# Run once per Quartus GUI session. Saving then formats and checks automatically.
if {[llength [info commands ::quartus_qol::stop]]} {::quartus_qol::stop}
namespace eval ::quartus_qol {
 variable home [file dirname [file normalize [info script]]]
 variable user_home [file join $home .. user]
 file mkdir $user_home
 variable timer {}
 variable hover_timer {}
 variable enabled 1
 variable seen [dict create]
 variable jobs
 if {![info exists jobs]} {set jobs [dict create]}
 variable serial
 if {![info exists serial]} {set serial 0}
 variable pending [dict create]
 variable config [dict create \
  python [file join $home .. tools python-3.13.7 python.exe] \
  slang [file join $home .. tools slang-11.0 slang.exe] \
  verible [file join $home .. tools verible-4294 verible-verilog-format.exe] \
  format_args {--indentation_spaces=4 --column_limit=120 --port_declarations_alignment=align --port_declarations_indentation=indent --module_net_variable_alignment=align --assignment_statement_alignment=align --named_port_alignment=align --named_port_indentation=indent --named_parameter_alignment=align --named_parameter_indentation=indent --formal_parameters_alignment=align --formal_parameters_indentation=indent --case_items_alignment=align} \
  slang_args {-Wextra} include_dirs {} defines {} top {} sources {} hover_delay 400 completion 1 format_on_save 1 diagnostics 1 hover 1 editor_colors 1 pin_planner_colors 0 theme quartus node [file join $home .. tools node-22.20.0 node.exe]]
}
proc ::quartus_qol::read_source {path} {
 set f [open $path r]; fconfigure $f -translation binary -encoding utf-8
 set text [read $f]; close $f
 return [string trimleft $text \ufeff]
}
proc ::quartus_qol::signature {path} {
 if {![file exists $path]} {return {}}
 return [list [file mtime $path] [file size $path] [zlib crc32 [encoding convertto utf-8 [read_source $path]]]]
}
proc ::quartus_qol::project_config {path} {
 variable config
 set c $config
 set sources [dict get $c sources]
 set root [file dirname $path]
 if {[is_project_open]} {
  set root [get_project_directory]
  if {![llength $sources]} {
   foreach kind {SYSTEMVERILOG_FILE VERILOG_FILE} {
    foreach_in_collection assignment [get_all_global_assignments -name $kind] {
     set f [get_assignment_info $assignment -value]
     if {[file pathtype $f] ne {absolute}} {set f [file join $root $f]}
     if {[file isfile $f]} {lappend sources [file normalize $f]}
    }
   }
  }
  foreach_in_collection assignment [get_all_global_assignments -name SEARCH_PATH] {
   set f [get_assignment_info $assignment -value]
   if {[file pathtype $f] ne {absolute}} {set f [file join $root $f]}
   dict lappend c include_dirs [file normalize $f]
  }
  foreach_in_collection assignment [get_all_global_assignments -name VERILOG_MACRO] {dict lappend c defines [get_assignment_info $assignment -value]}
  if {[dict get $c top] eq {}} {catch {dict set c top [get_global_assignment -name TOP_LEVEL_ENTITY]}}
 }
 if {![llength $sources]} {
  foreach ed [qol_native list] {
   set p [dict get $ed path]
   if {[string tolower [file extension $p]] in {.v .sv} && [file exists $p]} {lappend sources $p}
  }
 }
 # An independently opened file needs automatic root discovery. The project's
 # selected top otherwise suppresses elaboration of that file's module bodies.
 if {$path ni $sources && [string tolower [file extension $path]] in {.v .sv}} {
  lappend sources $path
  dict set c top {}
 }
 dict set c sources [lsort -unique $sources]
 dict lappend c include_dirs [file dirname $path]
 dict set c root $root
 dict set c path $path
 return $c
}
# JSON avoids loading a second Tcl runtime inside Python; Quartus's Tcl DLL
# search settings can deadlock tkinter initialization in a child process.
proc ::quartus_qol::json_quote {value} {
 set escaped [string map [list \\ \\\\ \" \\\" \n \\n \r \\r \t \\t \b \\b \f \\f] $value]
 return \"$escaped\"
}
proc ::quartus_qol::worker_json {config} {
 set fields {}
 dict for {key value} $config {
  if {$key in {format_args slang_args include_dirs defines sources}} {
   set parts {}; foreach item $value {lappend parts [json_quote $item]}
   set encoded \[[join $parts ,]\]
  } else {set encoded [json_quote $value]}
  lappend fields "[json_quote $key]:$encoded"
 }
 return \{[join $fields ,]\}
}
proc ::quartus_qol::launch {mode path} {
 variable home; variable serial; variable jobs; variable config
 if {$mode eq {lint} && ![dict get $config diagnostics]} {return}
 if {$mode eq {format} && ![dict get $config format_on_save]} {return [launch lint $path]}
 if {[dict exists $jobs $path]} {return}
 incr serial
 set req [file join $home .runtime [format {%d-%d.req} [pid] $serial]]
 file mkdir [file dirname $req]
 set c [project_config $path]
 set f [open $req w]; fconfigure $f -translation binary -encoding utf-8; puts -nonewline $f [worker_json $c]; close $f
 set cmd [list [file join $home qolworker-v3.exe] [dict get $c python] -I -S -u [file join $home worker.py] $mode $req]
 set launch_started [clock microseconds]
 set ch [open |$cmd r]
 set ::quartus_qol::last_launch_ms [expr {([clock microseconds]-$launch_started)/1000.0}]
 fconfigure $ch -blocking 0 -encoding utf-8 -translation lf
 dict set jobs $path [dict create channel $ch request $req mode $mode data {}]
 fileevent $ch readable [list ::quartus_qol::read_result $path]
}
proc ::quartus_qol::read_result {path} {
 variable jobs; variable seen; variable enabled; variable pending; variable home
 if {![dict exists $jobs $path]} {return}
 set job [dict get $jobs $path]; set ch [dict get $job channel]
 dict append job data [read $ch]
 dict set jobs $path $job
 if {![eof $ch]} {return}
 fileevent $ch readable {}; catch {close $ch}; catch {file delete [dict get $job request]}
 dict unset jobs $path
 set out [open [file join $home .runtime last-[dict get $job mode].txt] w]
 fconfigure $out -translation binary -encoding utf-8
 puts -nonewline $out [dict get $job data]; close $out
 if {!$enabled} {return}
 if {[catch {apply_result $path [dict get $job mode] [dict get $job data]} error]} {
  set out [open [file join $home .runtime last-error.txt] w]; puts $out $error; close $out
  post_message -type warning "Quartus QOL: $error"
 }
 if {[dict exists $pending $path]} {
  dict unset pending $path
  if {![dict exists $jobs $path]} {launch format $path}
 }
}
proc ::quartus_qol::apply_result {path mode payload} {
 variable seen; variable config
 if {$mode eq {lint} && ![dict get $config diagnostics]} {return}
 if {$mode eq {format} && ![dict get $config format_on_save]} {launch lint $path;return}
 variable last_result
 set last_result [list $mode $payload]
 if {[catch {dict get $payload status} status]} {error {Worker returned invalid output}}
 if {$status eq {failure}} {error [dict get $payload detail]}
 set saved 0
 foreach ed [qol_native list] {if {[dict get $ed path] eq $path} {set saved [expr {![dict get $ed modified]}]}}
 if {!$saved} {return}
 if {$mode eq {format}} {
  if {$status eq {formatted}} {
   set old [dict get $payload original]; set new [dict get $payload formatted]
   if {[qol_native get $path] ne $old || [read_source $path] ne $old} {return}
   if {$old ne $new} {qol_native replace $path $old $new; qol_native save $path}
   dict set seen $path [list 0 [signature $path]]
  }
  if {[info exists ::quartus_qol::color_seen] && [dict exists $::quartus_qol::color_seen $path]} {dict unset ::quartus_qol::color_seen $path}
  launch lint $path
  return
 }
 if {$status eq {stale}} {dict unset seen $path; return}
 if {$status ne {diagnostics}} {return}
 set covered [dict create]
 foreach snap [dict get $payload snapshots] {
  dict set covered [string tolower [file normalize [lindex $snap 0]]] 1
  lassign $snap p crc
  if {![file exists $p]} {return}
  set f [open $p rb]; set bytes [read $f]; close $f
  if {[zlib crc32 $bytes] != $crc} {return}
 }
 set by_file [dict create]
 foreach row [dict get $payload diagnostics] {
  lassign $row p line col len severity message
  dict lappend by_file $p [list $line $col $len $severity $message]
 }
 foreach ed [qol_native list] {
  set p [dict get $ed path]
  if {[dict get $ed modified] || ![file exists $p] || [string tolower [file extension $p]] ni {.sv .v .svh .vh}} {continue}
  if {[qol_native get $p] ne [read_source $p]} {continue}
  if {![dict exists $covered [string tolower [file normalize $p]]] && ![dict exists $by_file $p]} {continue}
  if {[dict exists $by_file $p]} {
   set rows [dict get $by_file $p]
   qol_native mark $p $rows
  } else {qol_native clear $p}
 }
 set count [llength [dict get $payload diagnostics]]
 # Keep the detailed, current result in the editor; don't accumulate stale Errors.
 post_message -type info "Quartus QOL: slang found $count diagnostic(s); squiggles and hover messages updated."
}
proc ::quartus_qol::hover_poll {} {
 variable hover_timer; variable enabled; variable config
 if {!$enabled} {return}
 if {[catch {
  if {[dict get $config hover] && [dict get $config diagnostics]} {qol_native hover} else {qol_native hidehover}
 } error]} {
  post_message -type warning "Quartus QOL hover: $error"
  return
 }
 set hover_timer [after 75 ::quartus_qol::hover_poll]
}
proc ::quartus_qol::poll {} {
 variable timer; variable enabled; variable seen; variable jobs; variable pending
 if {!$enabled} {return}
 if {[catch {
  if {[catch {::quartus_qol::theme_poll} theme_error]} {
   if {![info exists ::quartus_qol::last_theme_error] || $::quartus_qol::last_theme_error ne $theme_error} {
    set ::quartus_qol::last_theme_error $theme_error
    post_message -type warning "Quartus QOL colors: $theme_error"
   }
  }
  set opened {}
  foreach ed [qol_native list] {
   set p [dict get $ed path]
   if {$p eq {} || ![file exists $p] || [string tolower [file extension $p]] ni {.v .sv .svh .vh}} {continue}
   lappend opened $p
   set dirty [dict get $ed modified]
   set sig [signature $p]
   set current [list $dirty $sig]
   if {![dict exists $seen $p]} {
    dict set seen $p $current
    # Initial opening checks errors without silently reformatting existing files.
    if {!$dirty} {launch lint $p}
   } else {
    lassign [dict get $seen $p] was_dirty was_sig
    if {$dirty && !$was_dirty} {qol_native clear $p}
    if {!$dirty && ($was_dirty || $sig ne $was_sig)} {
     if {[dict exists $jobs $p]} {dict set pending $p 1} else {launch format $p}
    }
    dict set seen $p $current
   }
  }
  foreach p [dict keys $seen] {if {$p ni $opened} {dict unset seen $p}}
 } error]} {post_message -type warning "Quartus QOL: $error"}
 set timer [after 250 ::quartus_qol::poll]
}
proc ::quartus_qol::stop {} {
 variable enabled; variable timer; variable jobs; variable hover_timer
 if {[llength [info commands ::quartus_qol::color_stop]]} {::quartus_qol::color_stop}
 if {[llength [info commands ::quartus_qol::completion_stop]]} {::quartus_qol::completion_stop}
 catch {qol_native options stop}
 catch {qol_native uistyle {}}
 if {[info exists ::quartus_qol::settings_timer] && $::quartus_qol::settings_timer ne {}} {after cancel $::quartus_qol::settings_timer;set ::quartus_qol::settings_timer {}}
 set enabled 0
 if {$timer ne {}} {after cancel $timer; set timer {}}
 if {[info exists hover_timer] && $hover_timer ne {}} {after cancel $hover_timer; set hover_timer {}}
 foreach ed [qol_native list] {catch {qol_native clear [dict get $ed path]}}
 post_message {Quartus QOL disabled for this session.}
}
if {[llength [info commands qol_native]] == 0 || [catch {qol_native version} native_version] || $native_version != 15} {
 source [file join $::quartus_qol::home compatibility.tcl]
 ::quartus_qol::check_compatibility
 load [file join $::quartus_qol::home qolnative-v15.dll] Qolnative
}
if {[file exists [file join $::quartus_qol::user_home config.tcl]]} {source [file join $::quartus_qol::user_home config.tcl]}
source [file join $::quartus_qol::home settings.tcl]
if {$::quartus_qol::timer ne {}} {after cancel $::quartus_qol::timer}
source [file join $::quartus_qol::home theme.tcl]
source [file join $::quartus_qol::home highlighter.tcl]
source [file join $::quartus_qol::home completion.tcl]
::quartus_qol::poll
qol_native hoverdelay [dict get $::quartus_qol::config hover_delay]
::quartus_qol::hover_poll
::quartus_qol::settings_poll
post_message {Quartus QOL active: Verible formatting and slang diagnostics after save.}
