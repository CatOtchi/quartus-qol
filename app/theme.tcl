# Neutral dark palette matched to Quartus chrome. Syntax keeps subdued colors.
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
 set base [bgr #2d2d2d]; set text [bgr #dddddd]; set gutter [bgr #272727]
 set s -1
 foreach unused [lrepeat 256 {}] {
  incr s
  theme_send $p 2051 $s $text
  theme_send $p 2052 $s $base
 }
 foreach {styles color} {{1 2 3 20} #919991 {4} #c8a780 {5 7 8} #93b7d0 {6 12} #a7b58c {9} #c9bd96 {10} #b9c6c9 {11 21 22 23 24} #dddddd {19} #93b7d0 {33} #929292} {
  foreach s $styles {theme_send $p 2051 $s [bgr $color]}
 }
 foreach s {1 2 3 20} {theme_send $p 2054 $s 1}
 theme_send $p 2052 33 $gutter
 theme_send $p 2052 34 [bgr #4b5660]
 theme_send $p 2051 34 [bgr #eeeeee]
 theme_send $p 2051 35 [bgr #db8989]
 theme_send $p 2069 [bgr #eeeeee]
 theme_send $p 2067 1 $text
 theme_send $p 2068 1 [bgr #4b5660]
 theme_send $p 2478 256
 theme_send $p 2098 [bgr #3c3c3c]
 theme_send $p 2096 1
 theme_send $p 2084 1 [bgr #626262]
 theme_send $p 2290 1 $gutter
 theme_send $p 2291 1 $gutter
 foreach m {25 26 27 28 29 30 31} {
  theme_send $p 2041 $m [bgr #919991]
  theme_send $p 2042 $m $gutter
 }
 # Dedicated styles used by the VS Code grammar worker; retain Quartus fonts.
 foreach {style color italic} {
  64 #dddddd 0 65 #8f9b8d 1 66 #aabf93 0 67 #d4ae7b 0
  68 #92b7d0 0 69 #9bbec4 0 70 #cebd8c 1 71 #c9bd91 0
  72 #8db6d1 1 73 #dddddd 0 74 #c6ab89 0 75 #b49cc6 0
  76 #a9b8be 0 77 #bac5cc 0 78 #d0b58c 0
  80 #d99886 0 81 #c7ad75 0 82 #a9bc83 0
  83 #7eb6b1 0 84 #8eafd0 0 85 #b69aca 0 86 #e28b8b 0
 } {
  theme_send $p 2051 $style [bgr $color]
  theme_send $p 2054 $style $italic
 }
 theme_send $p 2132 3
 theme_send $p 2051 37 [bgr #444444]
 theme_send $p 2051 38 [bgr #646464]
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
 foreach ed [qol_native list] {
  set p [dict get $ed path]
  if {$p eq {}} {continue}
  # Also detects a close/reopen or Quartus resetting its editor preferences.
  if {[dict get $config editor_colors] && (![dict exists $themed $p] || [qol_native send $p 2482 32] != [bgr #2d2d2d])} {
   theme_editor $p; dict set themed $p 1
  }
 }
 if {[llength [info commands ::quartus_qol::color_poll]]} {::quartus_qol::color_poll}
 incr theme_tick
 if {$theme_tick % 4 == 0 && [dict get $config pin_planner_colors]} {
  qol_native widgetstyle PPLQ_NODE_TABLE {PPLQ_NODE_TABLE {color: #dddddd; background: #2d2d2d; selection-color: #ffffff; selection-background-color: #4b5660;} PPLQ_NODE_TABLE::item {color: #dddddd; background: #2d2d2d;} PPLQ_NODE_TABLE::item:selected {color: #ffffff; background: #4b5660;} PPLQ_NODE_TABLE QHeaderView {color: #dddddd;} PPLQ_NODE_TABLE QHeaderView::section {color: #dddddd; background: #3c3c3c;} PPLQ_NODE_TABLE QLineEdit {color: #dddddd; background: #2d2d2d;}}
 }
}
