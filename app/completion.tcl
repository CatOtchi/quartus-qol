# Scintilla's own popup handles arrows, Tab/Enter, Escape and undo.
# Suggestions are lexical: HDL keywords and identifiers in the current buffer.
namespace eval ::quartus_qol {
 variable completion_timer {}
 variable completion_seen [dict create]
 variable completion_offered [dict create]
 variable completion_text {}
 variable completion_words {}
 variable completion_keywords {
  always always_comb always_ff always_latch assign automatic begin bit break byte
  case casex casez class const continue default disable do else end endcase
  endclass endfunction endgenerate endinterface endmodule endpackage endtask
  enum for foreach forever fork function generate genvar if import initial
  inout input int integer interface join localparam logic longint module
  negedge output package packed parameter posedge priority reg repeat return
  shortint signed static string struct task time typedef union unique unsigned
  var void wait while wire $bits $clog2 $display $error $fatal $finish $signed
  $size $unsigned $warning
 }
}
proc ::quartus_qol::completion_tokens {text} {
 # Whole comments, strings, escaped names and numeric literals consume tokens
 # before the identifier alternative, so their contents are never suggested.
 set words {}
 foreach token [regexp -all -inline {(?s)//[^\r\n]*|/\*(?:[^*]|\*+[^*/])*(?:\*+/|$)|"(?:\\.|[^"\\])*(?:"|$)|\\[^\s]+|[0-9][A-Za-z0-9_'?]*|[A-Za-z_$][A-Za-z0-9_$]*} $text] {
  if {[regexp {^[A-Za-z_$][A-Za-z0-9_$]*$} $token]} {lappend words $token}
 }
 return [lsort -ascii -unique $words]
}
proc ::quartus_qol::completion_score {word prefix} {
 # Lower scores win: prefix, word-boundary substring, substring, subsequence.
 set hay [string tolower $word]; set needle [string tolower $prefix]
 set at [string first $needle $hay]
 set extra [expr {[string length $word]-[string length $prefix]}]
 set casePenalty [expr {[string first $prefix $word]<0}]
 if {$at>=0} {
  set tier 2
  if {$at==0} {set tier 0} elseif {[string index $word [expr {$at-1}]] in {_ $}} {set tier 1}
  return [list $tier [expr {$at*2+$extra+$casePenalty}]]
 }
 set pos -1; set penalty $extra
 foreach ch [split $needle {}] {
  set next [string first $ch $hay [expr {$pos+1}]]
  if {$next<0} {return {}}
  incr penalty [expr {$next-$pos-1}]
  if {$next>0 && [string index $word [expr {$next-1}]] ne {_}} {incr penalty 2}
  set pos $next
 }
 return [list 3 $penalty]
}
proc ::quartus_qol::completion_matches {words prefix} {
 set ranked {}
 foreach word $words {
  if {$word ne $prefix} {
   set score [completion_score $word $prefix]
   if {[llength $score]} {lappend ranked [list {*}$score $word]}
  }
 }
 # Stable sorts preserve alphabetical order on equal scores.
 set ranked [lsort -ascii -index 2 $ranked]
 set ranked [lsort -integer -index 1 $ranked]
 set ranked [lsort -integer -index 0 $ranked]
 set result {}
 foreach row [lrange $ranked 0 99] {lappend result [lindex $row 2]}
 return $result
}
proc ::quartus_qol::completion_poll {} {
 variable completion_timer; variable completion_seen; variable completion_offered
 variable completion_text; variable completion_words; variable completion_keywords
 variable enabled; variable config
 if {!$enabled || ![dict get $config completion]} {return}
 if {[catch {
  set opened {}
  foreach ed [qol_native list] {
   set p [dict get $ed path]; lappend opened $p
   if {[string tolower [file extension $p]] ni {.sv .v .svh .vh} || [dict get $ed length]>1048576} {continue}
   if {![qol_native send $p 2381]} {continue}
   set pos [qol_native send $p 2008]
   set text [qol_native get $p]
   set key [list $pos $text]
   # A dismissed popup stays dismissed until the next edit/caret change.
   if {[dict exists $completion_seen $p] && [dict get $completion_seen $p] eq $key} {continue}
   set had [dict exists $completion_seen $p]
   set changed [expr {$had && [lindex [dict get $completion_seen $p] 1] ne $text}]
   dict set completion_seen $p $key
   if {!$changed || $pos!=[qol_native send $p 2009] || [qol_native send $p 2570]>1} {continue}
   # Recompute on each edit; the native popup cannot filter fuzzy candidates.
   if {[qol_native send $p 2102]} {qol_native send $p 2101}
   # Scintilla positions are UTF-8 byte offsets; Tcl indexes are characters.
   set before [encoding convertfrom utf-8 [string range [encoding convertto utf-8 $text] 0 [expr {$pos-1}]]]
   if {![regexp {([A-Za-z_$][A-Za-z0-9_$]*)$} $before -> prefix] || [string length $prefix]<2} {continue}
   if {[dict exists $completion_offered $p]} {
    lassign [dict get $completion_offered $p] start offered
    if {$pos-[string length $prefix]==$start && $prefix in $offered} {continue}
   }
   # Use a lexical scanner for exact end-of-prefix context (including comments).
   if {![completion_code_context $before]} {continue}
   if {$completion_text ne $text} {
    set completion_words [lsort -ascii -unique [concat $completion_keywords [completion_tokens $text]]]
    set completion_text $text
   }
   set matches [completion_matches $completion_words $prefix]
   if {[llength $matches]} {
    dict set completion_offered $p [list [expr {$pos-[string length $prefix]}] $matches]
    qol_native complete $p [string length $prefix] [join $matches { }]
   }
  }
  foreach p [dict keys $completion_seen] {if {$p ni $opened} {dict unset completion_seen $p}}
  foreach p [dict keys $completion_offered] {if {$p ni $opened} {dict unset completion_offered $p}}
 } error]} {
  if {![info exists ::quartus_qol::completion_error] || $::quartus_qol::completion_error ne $error} {
   set ::quartus_qol::completion_error $error
   post_message -type warning "Quartus QOL completion: $error"
  }
 }
 set completion_timer [after 100 ::quartus_qol::completion_poll]
}
proc ::quartus_qol::completion_code_context {text} {
 # Strip closed non-code regions. An unterminated region reaches the caret.
 set end [string length $text]
 foreach range [regexp -all -inline -indices {(?s)//[^\r\n]*|/\*(?:[^*]|\*+[^*/])*(?:\*+/|$)|"(?:\\.|[^"\\])*(?:"|$)|\\[^\s]+} $text] {
  lassign $range a b
  if {$b==$end-1} {return 0}
 }
 return 1
}
proc ::quartus_qol::completion_stop {} {
 variable completion_timer
 if {$completion_timer ne {}} {after cancel $completion_timer; set completion_timer {}}
 foreach ed [qol_native list] {catch {qol_native send [dict get $ed path] 2101}}
}
::quartus_qol::completion_poll
