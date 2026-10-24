namespace eval ::quartus_qol {variable enabled 0; variable config [dict create completion 1]}
source [file join [file dirname [info script]] completion.tcl]
proc check {condition name} {if {![uplevel 1 [list expr $condition]]} {error "FAIL: $name"}}
set words [::quartus_qol::completion_tokens {module sample;
 logic present_state, next_state;
 // comment_only
 /* block_only */
 initial $display("string_only");
 logic [7:0] byte_data = 8'hff;
 \escaped_name ;
endmodule}]
foreach name {present_state next_state sample logic {$display}} {check {$name in $words} "identifier $name"}
foreach name {comment_only block_only string_only hff escaped_name} {check {$name ni $words} "skip $name"}
check {[::quartus_qol::completion_matches $words pre] eq {present_state}} {prefix matching}
check {[::quartus_qol::completion_matches $words present_state] eq {}} {no redundant completion}
check {"serial_data" in [::quartus_qol::completion_matches {serial_data} data]} {substring matching}
check {"key_code_synced" in [::quartus_qol::completion_matches {key_code_synced} ksc]} {ordered abbreviation}
check {[::quartus_qol::completion_matches {serial_data DATA_READY data_buffer metadata} data] eq {DATA_READY data_buffer serial_data metadata}} {rank prefix before boundary before substring}
check {[::quartus_qol::completion_matches {LEDR} ledr] eq {LEDR}} {case insensitive exact name preserves spelling}
check {[::quartus_qol::completion_matches {key_code_synced} zks] eq {}} {reject out of order or missing letters}
check {[::quartus_qol::completion_matches {KEY_CODE_SYNCED} ksc] eq {KEY_CODE_SYNCED}} {case insensitive abbreviation}
set many {}; for {set n 0} {$n<150} {incr n} {lappend many signal_$n}
check {[llength [::quartus_qol::completion_matches $many sig]]==100} {candidate limit}
foreach text [list {// logic pre} {/* logic pre} {"hello pre} {\escaped_pre}] {
 check {![::quartus_qol::completion_code_context $text]} "non-code context $text"
}
foreach text [list "// comment\npre" {/* comment */ pre} {"hello"; pre} {logic pre}] {
 check {[::quartus_qol::completion_code_context $text]} "code context $text"
}
puts {PASS: keywords/identifiers, ranked fuzzy matching, comments, strings, literals, escaped names and context}
