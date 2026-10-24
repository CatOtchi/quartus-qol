namespace eval ::quartus_qol {
 variable home [file join [file dirname [info script]] .runtime]
 variable config [dict create completion 1 format_on_save 1 diagnostics 1 hover 1 editor_colors 1 pin_planner_colors 1]
 variable seen [dict create];variable themed [dict create];variable color_failed 0
}
set script [file join [file dirname [info script]] settings.tcl]
# Keep tests independent of the user's persisted preferences.
set oldhome $::quartus_qol::home
set ::quartus_qol::home [file join $oldhome settings-test-[pid]]
set ::quartus_qol::user_home $::quartus_qol::home
file mkdir $::quartus_qol::home
source $script
proc check {condition name} {if {![uplevel 1 [list expr $condition]]} {error "FAIL: $name"}}
proc qol_native {op args} {lappend ::calls [list $op {*}$args];if {$op eq {list}} {return {{path scratch.sv}}};return {}}
proc ::quartus_qol::completion_stop {} {lappend ::calls completion_stop}
proc ::quartus_qol::completion_poll {} {lappend ::calls completion_poll}
proc ::quartus_qol::color_stop {} {lappend ::calls color_stop}
proc ::quartus_qol::theme_poll {} {lappend ::calls theme_poll}
proc post_message {args} {}
set calls {}
check {[catch {::quartus_qol::validate_preferences {diagnostics 2}}]} {reject invalid boolean}
check {[catch {::quartus_qol::validate_preferences {unknown 1}}]} {reject unknown key}
::quartus_qol::apply_preferences {0 0 0 0 0 0}
foreach k $::quartus_qol::preference_keys {check {![dict get $::quartus_qol::config $k]} "disabled $k"}
check {{restoretheme scratch.sv} in $calls} {restore editor colors}
check {{clear scratch.sv} in $calls} {remove diagnostics}
check {{completion_stop} in $calls} {cancel completion}
set ::quartus_qol::config [dict create]
::quartus_qol::load_preferences
check {[dict get $::quartus_qol::config diagnostics]==0} {persist disabled flags}
::quartus_qol::apply_preferences {1 1 1 1 1 1}
check {{completion_poll} in $calls} {restart completion}
set ::quartus_qol::config [dict create]
::quartus_qol::load_preferences
check {[dict get $::quartus_qol::config diagnostics]==1} {persist enabled flags}
file delete $::quartus_qol::preferences_path
file delete $::quartus_qol::home
puts {PASS: preference validation, persistence, feature cleanup and reactivation}
