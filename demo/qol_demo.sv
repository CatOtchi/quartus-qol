// Quartus QOL demo: save this file, then hover over missing_signal.
// The undeclared name is intentional; fix it to SW[0] to clear the error.
module qol_demo (
    input  logic [9:0] SW,
    output logic [9:0] LEDR
);
    logic [7:0] serial_data;
    logic       key_code_synced;

    assign serial_data     = SW[7:0];
    assign key_code_synced = SW[8];
    assign LEDR = {key_code_synced, missing_signal, serial_data};
endmodule
