# Asynchronous syntax coloring of the current editor buffer, including unsaved text.
namespace eval ::quartus_qol {
 variable color_channel {}
 variable color_seen [dict create]
 variable color_jobs [dict create]
 variable color_serial 0
 variable color_failed 0
}
proc ::quartus_qol::color_stop {} {
 variable color_channel; variable color_jobs; variable color_seen
 if {$color_channel ne {}} {
  catch {fileevent $color_channel readable {}}
  catch {close $color_channel}
  set color_channel {}
 }
 set color_jobs [dict create]; set color_seen [dict create]
}
proc ::quartus_qol::color_read {} {
 variable color_channel; variable color_jobs; variable color_seen; variable color_failed
 while {[gets $color_channel line] >= 0} {
  lassign $line id status data
  if {![dict exists $color_jobs $id]} {continue}
  lassign [dict get $color_jobs $id] p text
  dict unset color_jobs $id
  if {![dict get $::quartus_qol::config editor_colors]} {continue}
  if {$status ne {ok}} {
   post_message -type warning "Quartus QOL colors: [encoding convertfrom utf-8 [binary decode base64 $data]]"
   # Avoid retrying a failing snapshot every poll. A new edit retries normally.
   dict set color_seen $p $text
   continue
  }
  set styles [binary decode base64 $data]
  if {![catch {qol_native colorize $p $text $styles}]} {
   dict set color_seen $p $text
  }
 }
 if {[eof $color_channel]} {
  color_stop; set color_failed 1
  post_message -type warning {Quartus QOL syntax worker exited. Reload QOL to retry.}
 }
}
proc ::quartus_qol::color_poll {} {
 variable color_channel; variable color_jobs; variable color_seen
 variable color_serial; variable color_failed; variable config; variable home
 if {![dict get $config editor_colors]} {return}
 if {$color_failed} {return}
 if {$color_channel eq {}} {
  set cmd [list [dict get $config node] [file join $home highlighter.cjs]]
  if {[catch {set color_channel [open |$cmd r+]} error]} {
   set color_failed 1
   post_message -type warning "Quartus QOL syntax worker: $error"
   return
  }
  fconfigure $color_channel -blocking 0 -encoding ascii -translation lf -buffering line
  fileevent $color_channel readable ::quartus_qol::color_read
 }
 set opened {}
 foreach ed [qol_native list] {
  set p [dict get $ed path]; set ext [string tolower [file extension $p]]
  if {$ext ni {.v .vh .sv .svh} || [dict get $ed length] > 4194304} {continue}
  lappend opened $p
  set busy 0
  dict for {id job} $color_jobs {if {[lindex $job 0] eq $p} {set busy 1; break}}
  if {$busy} {continue}
  set text [qol_native get $p]
  if {[dict exists $color_seen $p] && [dict get $color_seen $p] eq $text} {continue}
  incr color_serial
  set lang [expr {$ext in {.v .vh} ? {verilog} : {systemverilog}}]
  dict set color_jobs $color_serial [list $p $text]
  puts $color_channel "$color_serial $lang [binary encode base64 -maxlen 0 [encoding convertto utf-8 $text]]"
 }
 foreach p [dict keys $color_seen] {if {$p ni $opened} {dict unset color_seen $p}}
}
