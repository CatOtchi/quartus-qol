namespace eval ::quartus_qol {}
source [file join [file dirname [info script]] .. app compatibility.tcl]
proc check {condition message} {if {![uplevel 1 [list expr $condition]]} {error $message}}
set editor fd3982bf07b1b7ef227406cb612facff2646fb639f0df4eaeefa58cc30b9056d
set options ed9e3a115915b04bb843c155faf2af01602c4333541f830a1c82f5bd380db64d
check {[::quartus_qol::compatibility_allowed $editor $options {}]} {tested pair}
check {![::quartus_qol::compatibility_allowed different other {}]} {missing consent}
check {[::quartus_qol::compatibility_allowed different other {editor different options other}]} {accepted pair}
check {![::quartus_qol::compatibility_allowed different changed {editor different options other}]} {changed binaries}
check {![::quartus_qol::compatibility_allowed different other {editor}]} {malformed data}
puts {PASS: runtime consent is data-only and restricted to the acknowledged binaries}
