# User preferences are a data-only Tcl dictionary, never sourced as code.
namespace eval ::quartus_qol {
 variable preference_keys {completion format_on_save diagnostics hover editor_colors pin_planner_colors}
 variable settings_timer {}
 variable preferences_path [file join $user_home preferences.dict]
}
proc ::quartus_qol::validate_preferences {data} {
 variable preference_keys
 set result [dict create]
 dict for {key value} $data {
  if {$key ni $preference_keys || $value ni {0 1}} {error "Invalid editor preference: $key"}
  dict set result $key $value
 }
 return $result
}
proc ::quartus_qol::load_preferences {} {
 variable preferences_path; variable config
 if {![file exists $preferences_path]} {return}
 set f [open $preferences_path r];set data [read $f];close $f
 dict for {key value} [validate_preferences $data] {dict set config $key $value}
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
 if {[llength $values]!=[llength $preference_keys]} {error {Expected six feature settings}}
 set changes [dict create]
 foreach key $preference_keys value $values {dict set changes $key $value}
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
 if {[dict get $previous editor_colors]!=[dict get $config editor_colors]} {
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
