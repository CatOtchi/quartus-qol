# Installer consent is data, applies to one exact pair of binaries, and never
# disables native signature/export checks. Reinstall after Quartus changes.
proc ::quartus_qol::compatibility_allowed {editor options consent} {
 if {$editor eq {fd3982bf07b1b7ef227406cb612facff2646fb639f0df4eaeefa58cc30b9056d} && $options eq {ed9e3a115915b04bb843c155faf2af01602c4333541f830a1c82f5bd380db64d}} {return 1}
 if {[catch {dict size $consent} count] || $count!=2} {return 0}
 return [expr {[dict exists $consent editor] && [dict exists $consent options] && [dict get $consent editor] eq $editor && [dict get $consent options] eq $options}]
}
proc ::quartus_qol::check_compatibility {} {
 variable home; variable config; variable user_home
 set hashes [exec [file join $home qolworker-v3.exe] [dict get $config python] -I -S -c {import hashlib,sys;print(' '.join(hashlib.sha256(open(p,'rb').read()).hexdigest() for p in sys.argv[1:]))} [file join $::quartus(binpath) edt_tedq.dll] [file join $::quartus(binpath) gcl_afcq.dll]]
 lassign $hashes editor options
 set consent {}
 set path [file join $user_home compatibility.dict]
 if {[file exists $path]} {set f [open $path r];set consent [read $f];close $f}
 if {![compatibility_allowed $editor $options $consent]} {error {Untested Quartus build. Run Install.cmd and accept its version warning to try this build.}}
 if {$editor ne {fd3982bf07b1b7ef227406cb612facff2646fb639f0df4eaeefa58cc30b9056d} || $options ne {ed9e3a115915b04bb843c155faf2af01602c4333541f830a1c82f5bd380db64d}} {
  post_message -type warning {Quartus QOL: running experimentally on an untested Quartus build with your installer acknowledgement.}
 }
}
