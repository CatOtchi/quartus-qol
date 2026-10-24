# Loaded by the small, reversible hook in Quartus's GUI Tcl initialization file.
namespace eval ::quartus_qol_startup {
 variable home [file dirname [file normalize [info script]]]
}
if {![llength [info commands qol_pump_active]]} {
 load [file join $::quartus_qol_startup::home qolpump.dll] Qolpump
}
proc ::quartus_qol_startup::start {} {
 variable home
 if {[catch {
  # Loading the editor module is safe even before any source file is open.
  source [file join $::quartus(tclpath) internal init tedq.tcl]
  package require ::quartus::tedq
  source [file join $home quartus-qol.tcl]
 } error]} {
  post_message -type warning "Quartus QOL could not start: $error"
  catch {
   file mkdir [file join $home .runtime]
   set f [open [file join $home .runtime startup-error.txt] w]
   puts $f $error; close $f
   set f [open [file join $home .runtime startup-[pid].txt] w]
   puts $f [list status failed pid [pid] error $error]; close $f
  }
 } else {
  catch {
   file mkdir [file join $home .runtime]
   set f [open [file join $home .runtime startup-[pid].txt] w]
   puts $f [list status active pid [pid] native_version [qol_native version] home $home]
   close $f
  }
 }
}
after 1000 ::quartus_qol_startup::start
