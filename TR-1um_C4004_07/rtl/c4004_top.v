// Intel 4004 Compatible 4-bit CPU Top Wrapper (c4004_top)
`timescale 1ns/1ps

module c4004_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       test,
    inout  wire [3:0] D,
    output wire       sync,
    output wire       cm_rom,
    output wire [3:0] cm_ram,
    output wire       d_oe
);

    wire [3:0] d_in  = D;
    wire [3:0] d_out;
    wire       d_hiz;

    assign D = d_oe ? d_out : 4'bz;

    c4004_core u_core (
        .clk    (clk),
        .rst    (rst),
        .test   (test),
        .d_in   (d_in),
        .d_out  (d_out),
        .d_oe   (d_oe),
        .d_hiz  (d_hiz),
        .sync   (sync),
        .cm_rom (cm_rom),
        .cm_ram (cm_ram)
    );

endmodule
