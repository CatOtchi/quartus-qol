# Presets color the editor and optionally Pin Planner, never the whole Qt UI.
namespace eval ::quartus_qol {variable themed [dict create]; variable theme_tick 0}
proc ::quartus_qol::bgr {hex} {
 scan [string trimleft $hex #] %x rgb
 return [expr {(($rgb & 255) << 16) | ($rgb & 65280) | (($rgb >> 16) & 255)}]
}
proc ::quartus_qol::theme_send {p message {w 0} {l 0}} {
 upvar 1 commands commands
 lappend commands [list $message $w $l]
 return
}
proc ::quartus_qol::theme_editor {p} {
 set commands {}
 set palette [current_palette]
 set base [bgr [dict get $palette base]]; set text [bgr [dict get $palette text]]; set gutter [bgr [dict get $palette gutter]]
 set italics [expr {[dict get $::quartus_qol::config theme] ne {quartus}}]
 set s -1
 foreach unused [lrepeat 256 {}] {
  incr s
  theme_send $p 2051 $s $text
  theme_send $p 2052 $s $base
 }
 foreach {styles role} {{1 2 3 20} comment {4} number {5 7 8} keyword {6 12} string {9} preprocessor {10} operator {11 21 22 23 24} text {19} keyword {33} comment} {
  foreach s $styles {theme_send $p 2051 $s [bgr [dict get $palette $role]]}
 }
 foreach s {1 2 3 20} {theme_send $p 2054 $s $italics}
 theme_send $p 2052 33 $gutter
 theme_send $p 2051 33 [bgr [dict get $palette gutter_text]]
 theme_send $p 2052 34 [bgr [dict get $palette selection]]
 theme_send $p 2051 34 $text
 theme_send $p 2051 35 [bgr [dict get $palette unmatched]]
 theme_send $p 2069 $text
 theme_send $p 2067 1 $text
 theme_send $p 2068 1 [bgr [dict get $palette selection]]
 theme_send $p 2478 256
 theme_send $p 2098 [bgr [dict get $palette line]]
 theme_send $p 2096 1
 theme_send $p 2084 1 [bgr [dict get $palette guide]]
 theme_send $p 2290 1 $gutter
 theme_send $p 2291 1 $gutter
 foreach m {25 26 27 28 29 30 31} {
  theme_send $p 2041 $m [bgr [dict get $palette comment]]
  theme_send $p 2042 $m $gutter
 }
 # Dedicated styles used by the VS Code grammar worker; retain Quartus fonts.
 foreach {style role italic} {
  64 text 0 65 comment 1 66 string 0 67 number 0
  68 keyword 0 69 type 0 70 module 1 71 function 0
  72 port 1 73 instance 0 74 constant 0 75 preprocessor 0
  76 operator 0 77 label 0 78 escape 0 86 unmatched 0
 } {
  theme_send $p 2051 $style [bgr [dict get $palette $role]]
  theme_send $p 2054 $style [expr {$italic && $italics}]
 }
 set style 80
 foreach color [dict get $palette depths] {theme_send $p 2051 $style [bgr $color];theme_send $p 2054 $style 0;incr style}
 theme_send $p 2132 3
 theme_send $p 2051 37 [bgr [dict get $palette guide]]
 theme_send $p 2051 38 [bgr [dict get $palette comment]]
 if {[info exists ::quartus_qol::color_seen] && [dict exists $::quartus_qol::color_seen $p]} {dict unset ::quartus_qol::color_seen $p}
 qol_native theme $p $commands
 # Extend the Verilog lexer's secondary keyword set with SystemVerilog words.
 # The original primary Verilog keywords stay intact.
 if {[qol_native send $p 4002] == 56} {
  qol_native keywords $p 1 {accept_on alias always_comb always_ff always_latch assert assume automatic before bind bins binsof bit break byte chandle checker class clocking const constraint context continue cover covergroup coverpoint cross dist do endchecker endclass endclocking endgroup endinterface endpackage endprogram endproperty endsequence enum expect export extends extern final first_match foreach forkjoin iff ignore_bins illegal_bins implements implies import inside int interconnect interface intersect join_any join_none let local logic longint matches modport nettype new null package packed priority program property protected pure rand randc randcase randsequence ref reject_on restrict return sequence shortint shortreal solve static string struct super sync_accept_on sync_reject_on tagged this throughout timeprecision timeunit type typedef union unique unique0 unsigned var virtual void wait_order wildcard with within}
 }
}
proc ::quartus_qol::theme_poll {} {
 variable themed; variable theme_tick;variable config
 set palette [current_palette]
 set theme [dict get $config theme]
 foreach ed [qol_native list] {
  set p [dict get $ed path]
  if {$p eq {}} {continue}
  # Also detects a close/reopen or Quartus resetting its editor preferences.
  if {[dict get $config editor_colors] && (![dict exists $themed $p] || [dict get $themed $p] ne $theme || [qol_native send $p 2482 32] != [bgr [dict get $palette base]])} {
   theme_editor $p; dict set themed $p $theme
  }
 }
 if {[llength [info commands ::quartus_qol::color_poll]]} {::quartus_qol::color_poll}
 incr theme_tick
 if {$theme_tick % 4 == 0 && [dict get $config pin_planner_colors]} {
  set fg [dict get $palette text];set bg [dict get $palette base];set selected [dict get $palette selection];set line [dict get $palette line]
  qol_native widgetstyle PPLQ_NODE_TABLE "PPLQ_NODE_TABLE {color: $fg; background: $bg; selection-color: $fg; selection-background-color: $selected;} PPLQ_NODE_TABLE::item {color: $fg; background: $bg;} PPLQ_NODE_TABLE::item:selected {color: $fg; background: $selected;} PPLQ_NODE_TABLE QHeaderView {color: $fg;} PPLQ_NODE_TABLE QHeaderView::section {color: $fg; background: $line;} PPLQ_NODE_TABLE QLineEdit {color: $fg; background: $bg;}"
 }
}
