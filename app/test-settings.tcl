namespace eval ::quartus_qol {
 variable home [file join [file dirname [info script]] .runtime]
 variable config [dict create completion 1 format_on_save 1 diagnostics 1 hover 1 editor_colors 1 pin_planner_colors 1 theme quartus]
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
check {[catch {::quartus_qol::validate_preferences {theme invented}}]} {reject unknown theme}
check {[catch {::quartus_qol::apply_preferences {1 1 1 1 1 1 99 4 120 1 400}}]} {reject invalid theme index}
check {[catch {::quartus_qol::validate_preferences {indentation_spaces 0}}]} {reject invalid indentation}
check {[catch {::quartus_qol::validate_preferences {hover_delay -1}}]} {reject invalid hover delay}
dict lappend ::quartus_qol::config format_args --named_port_alignment=align
dict lappend ::quartus_qol::config slang_args --ignore-unknown-modules
::quartus_qol::apply_preferences {0 0 0 0 0 0 0 2 100 0 250}
check {{--indentation_spaces=2} in [dict get $::quartus_qol::config format_args]} {formatter indentation changes}
check {{--column_limit=100} in [dict get $::quartus_qol::config format_args]} {formatter column limit changes}
check {{-Wextra} ni [dict get $::quartus_qol::config slang_args]} {disable extra warnings}
check {{hoverdelay 250} in $calls} {update native hover delay}
check {{--named_port_alignment=align} in [dict get $::quartus_qol::config format_args]} {preserve unrelated formatting arguments}
check {{--ignore-unknown-modules} in [dict get $::quartus_qol::config slang_args]} {preserve unrelated Slang arguments}
foreach k $::quartus_qol::preference_keys {check {![dict get $::quartus_qol::config $k]} "disabled $k"}
check {{restoretheme scratch.sv} in $calls} {restore editor colors}
check {{clear scratch.sv} in $calls} {remove diagnostics}
check {{completion_stop} in $calls} {cancel completion}
set ::quartus_qol::config [dict create]
::quartus_qol::load_preferences
check {[dict get $::quartus_qol::config diagnostics]==0} {persist disabled flags}
::quartus_qol::apply_preferences {1 1 1 1 1 1 3 4 120 1 400}
check {{completion_poll} in $calls} {restart completion}
set ::quartus_qol::config [dict create]
::quartus_qol::load_preferences
check {[dict get $::quartus_qol::config diagnostics]==1} {persist enabled flags}
check {[dict get $::quartus_qol::config theme] eq {nord}} {persist selected palette}
set calls {}
::quartus_qol::apply_preferences {1 1 1 1 1 1 5 4 120 1 400}
check {{restoretheme scratch.sv} in $calls && {color_stop} in $calls} {theme-only change clears old styling}
set f [open $::quartus_qol::preferences_path w];puts $f {completion 1 editor_colors 1};close $f
::quartus_qol::load_preferences
check {[dict get $::quartus_qol::config theme] eq {quartus_dark}} {legacy preferences retain original dark palette}
file delete $::quartus_qol::preferences_path
file delete $::quartus_qol::home
puts {PASS: preference validation, theme persistence/migration, feature cleanup and reactivation}
