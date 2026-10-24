lassign $argv app python lintreq formatreq
set diagnostics [exec $python -I -S -u [file join $app worker.py] lint $lintreq]
if {[dict get $diagnostics status] ne {diagnostics}} {error $diagnostics}
set found 0
foreach row [dict get $diagnostics diagnostics] {
 if {[lindex $row 4] eq {error} && [string match {*missing_signal*} [lindex $row 5]]} {set found 1}
}
if {!$found} {error {Missing undeclared signal diagnostic}}
set formatted [exec $python -I -S -u [file join $app worker.py] format $formatreq]
if {[dict get $formatted status] ne {formatted}} {error $formatted}
if {[dict get $formatted original] eq [dict get $formatted formatted]} {error {Formatter did not change the deliberately unformatted fixture}}
puts {PASS: private Python/Slang/Verible report real diagnostics and format source}
