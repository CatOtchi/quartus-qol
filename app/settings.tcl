# User preferences are a data-only Tcl dictionary, never sourced as code.
source [file join [file dirname [info script]] palettes.tcl]
namespace eval ::quartus_qol {
 variable preference_keys {completion format_on_save diagnostics hover editor_colors pin_planner_colors}
 variable settings_timer {}
 variable preferences_path [file join $user_home preferences.dict]
}
proc ::quartus_qol::validate_preferences {data} {
 variable preference_keys
 set result [dict create]
 dict for {key value} $data {
  if {$key eq {theme}} {
   if {$value ni $::quartus_qol::theme_keys} {error "Invalid editor theme: $value"}
  } elseif {$key ni $preference_keys || $value ni {0 1}} {error "Invalid editor preference: $key"}
  dict set result $key $value
 }
 return $result
}
proc ::quartus_qol::load_preferences {} {
 variable preferences_path; variable config
 if {![file exists $preferences_path]} {return}
 set f [open $preferences_path r];set data [read $f];close $f
 set preferences [validate_preferences $data]
 # Older releases always used this palette. Preserve it on upgrades.
 if {![dict exists $preferences theme]} {dict set preferences theme quartus_dark}
 dict for {key value} $preferences {dict set config $key $value}
}
proc ::quartus_qol::save_preferences {data} {
 variable preferences_path
 set data [validate_preferences $data]
 set temporary ${preferences_path}.[pid].tmp
 set f [open $temporary w];fconfigure $f -encoding utf-8
 puts $f $data;close $f
 file rename -force $temporary $preferences_path
}
proc ::quartus_qol::apply_preferences {values} {
 variable config;variable preference_keys;variable seen;variable themed
 if {[llength $values]!=7} {error {Expected six feature settings and a theme index}}
 set index [lindex $values 6]
 if {![string is integer -strict $index] || $index<0 || $index>=[llength $::quartus_qol::theme_keys]} {error {Invalid theme index}}
 set changes [dict create]
 foreach key $preference_keys value [lrange $values 0 5] {dict set changes $key $value}
 dict set changes theme [lindex $::quartus_qol::theme_keys $index]
 set changes [validate_preferences $changes]
 save_preferences $changes
 set previous $config
 dict for {key value} $changes {dict set config $key $value}
 if {![dict get $config diagnostics]} {
  foreach ed [qol_native list] {qol_native clear [dict get $ed path]}
  qol_native hidehover
 } elseif {![dict get $previous diagnostics]} {set seen [dict create]}
 if {![dict get $config hover]} {qol_native hidehover}
 if {[dict get $previous completion]!=[dict get $config completion]} {
  completion_stop
  if {[dict get $config completion]} {completion_poll}
 }
 if {[dict get $previous editor_colors]!=[dict get $config editor_colors] || [dict get $previous theme] ne [dict get $config theme]} {
  color_stop;set themed [dict create]
  foreach ed [qol_native list] {qol_native restoretheme [dict get $ed path]}
  set ::quartus_qol::color_failed 0
 }
 if {![dict get $config pin_planner_colors]} {qol_native widgetstyle PPLQ_NODE_TABLE {}}
 theme_poll
 post_message -type info {Editor preferences applied.}
}
proc ::quartus_qol::settings_poll {} {
 variable settings_timer;variable config;variable preference_keys;variable enabled
 if {!$enabled} {return}
 set values {};foreach key $preference_keys {lappend values [dict get $config $key]}
 lappend values [lsearch -exact $::quartus_qol::theme_keys [dict get $config theme]]
 if {[catch {
  set result [qol_native options poll $values]
  if {[dict exists $result applied]} {apply_preferences [dict get $result applied]}
 } error]} {
  if {![info exists ::quartus_qol::settings_error] || $::quartus_qol::settings_error ne $error} {
   set ::quartus_qol::settings_error $error
   post_message -type warning "Quartus editor preferences: $error"
  }
 }
 set settings_timer [after 300 ::quartus_qol::settings_poll]
}
::quartus_qol::load_preferences
