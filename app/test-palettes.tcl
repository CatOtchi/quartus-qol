namespace eval ::quartus_qol {variable config [dict create theme quartus editor_colors 1 pin_planner_colors 1]}
source [file join [file dirname [info script]] palettes.tcl]
source [file join [file dirname [info script]] theme.tcl]
proc check {condition name} {if {![uplevel 1 [list expr $condition]]} {error "FAIL: $name"}}
proc qol_native {op args} {
 lappend ::calls [list $op {*}$args]
 if {$op eq {list}} {return {{path demo.sv}}}
 if {$op eq {send}} {return 0}
}
set calls {}
check {[llength $::quartus_qol::theme_keys]==7} {preset count agrees with native dropdown}
foreach name $::quartus_qol::theme_keys {
 dict set ::quartus_qol::config theme $name
 set p [::quartus_qol::current_palette]
 check {[llength [dict get $p depths]]==6} "$name depth cycle"
 foreach key [dict keys $p] {
  if {$key eq {depths}} {set colors [dict get $p $key]} else {set colors [list [dict get $p $key]]}
  foreach color $colors {check {[regexp {^#[0-9a-f]{6}$} $color]} "$name valid $key"}
 }
 set calls {};::quartus_qol::theme_editor demo.sv
 set messages [lindex [lsearch -inline -index 0 $calls theme] 2]
 check {[list 2052 32 [::quartus_qol::bgr [dict get $p base]]] in $messages} "$name correct paper"
 check {[list 2051 65 [::quartus_qol::bgr [dict get $p comment]]] in $messages} "$name comment role"
 foreach command $messages {check {[lindex $command 0] ni {2055 2056 2057 2171}} "$name preserves font and source"}
 set ::quartus_qol::theme_tick 3
 ::quartus_qol::theme_poll
 set ui [lsearch -inline -index 0 $calls uistyle]
 if {$name in {quartus_dark catppuccin_frappe nord tokyo_night}} {
  check {[string first [dict get $p base] [lindex $ui 1]]>=0} "$name dark UI follows palette"
 } elseif {$name eq {catppuccin_latte}} {
  check {$ui eq {uistyle {}}} {light theme restores application stylesheet}
 }
 check {[dict get $::quartus_qol::themed demo.sv] eq $name} "$name tracked per buffer"
 set css [lindex [lsearch -inline -index 0 $calls widgetstyle] 2]
 check {[string first [dict get $p base] $css]>=0 && [string first [dict get $p text] $css]>=0} "$name Pin Planner follows palette"
}
dict set ::quartus_qol::config theme quartus
check {[dict get [::quartus_qol::current_palette] base] eq {#ffffff}} {fresh default resembles stock Quartus}
dict set ::quartus_qol::config editor_colors 0
set calls {};::quartus_qol::theme_poll
check {[lsearch -index 0 $calls theme]<0} {disabled colors do not overwrite native palette}
dict set ::quartus_qol::config theme nord
dict set ::quartus_qol::config editor_colors 1
set calls {};::quartus_qol::theme_poll
set calls {};::quartus_qol::theme_poll
check {[lsearch -index 0 $calls uistyle]<0} {unchanged theme doesn't repolish the application}
dict set ::quartus_qol::config editor_colors 0
set calls {};::quartus_qol::theme_poll
check {{uistyle {}} in $calls} {disabled colors restore the application stylesheet}
puts {PASS: seven complete palettes, role/depth colors, font/source preservation, stock default and Pin Planner colors}
