`timescale 1ns/1ps

module AND2_X1 (input A, B, output Y); assign Y = A & B; endmodule
module AND3_X1 (input A, B, C, output Y); assign Y = A & B & C; endmodule
module AND4_X1 (input A, B, C, D, output Y); assign Y = A & B & C & D; endmodule
module AOI21 (input A1, A2, B, output Y); assign Y = ~((A1 & A2) | B); endmodule
module AOI22 (input A1, A2, B1, B2, output Y); assign Y = ~((A1 & A2) | (B1 & B2)); endmodule
module BUFTH (input A, output Y); assign Y = A; endmodule
module BUF_X1 (input A, output Y); assign Y = A; endmodule
module BUF_X2 (input A, output Y); assign Y = A; endmodule
module DEL1 (input A, output Y); assign Y = A; endmodule
module INV_X1 (input A, output Y); assign Y = ~A; endmodule
module INV_X2 (input A, output Y); assign Y = ~A; endmodule
module MUX2 (input A, B, S, output Y); assign Y = S ? B : A; endmodule
module NAND2 (input A, B, output Y); assign Y = ~(A & B); endmodule
module NAND3 (input A, B, C, output Y); assign Y = ~(A & B & C); endmodule
module NAND4 (input A, B, C, D, output Y); assign Y = ~(A & B & C & D); endmodule
module NOR2 (input A, B, output Y); assign Y = ~(A | B); endmodule
module NOR3 (input A, B, C, output Y); assign Y = ~(A | B | C); endmodule
module NOR4 (input A, B, C, D, output Y); assign Y = ~(A | B | C | D); endmodule
module OAI21 (input A1, A2, B, output Y); assign Y = ~((A1 | A2) & B); endmodule
module OAI22 (input A1, A2, B1, B2, output Y); assign Y = ~((A1 | A2) & (B1 | B2)); endmodule
module OR2 (input A, B, output Y); assign Y = A | B; endmodule
module OR3 (input A, B, C, output Y); assign Y = A | B | C; endmodule
module OR4 (input A, B, C, D, output Y); assign Y = A | B | C | D; endmodule
module XNOR2 (input A, B, output Y); assign Y = ~(A ^ B); endmodule
module XOR2 (input A, B, output Y); assign Y = A ^ B; endmodule

module DFFRB (input CK, D, RSTB, output reg Q, output QB);
    assign QB = ~Q;
    always @(posedge CK or negedge RSTB) begin
        if (!RSTB) Q <= 1'b0;
        else Q <= D;
    end
endmodule

module MUXDFFRB (input CK, A, B, S, RSTB, output reg Q, output QB);
    assign QB = ~Q;
    always @(posedge CK or negedge RSTB) begin
        if (!RSTB) Q <= 1'b0;
        else Q <= S ? B : A;
    end
endmodule

module EDFFRB (input CK, D, E, RSTB, output reg Q, output QB);
    assign QB = ~Q;
    always @(posedge CK or negedge RSTB) begin
        if (!RSTB) Q <= 1'b0;
        else if (E) Q <= D;
    end
endmodule

module DFFS (input CK, D, SET, output reg Q, output QB);
    assign QB = ~Q;
    always @(posedge CK or posedge SET) begin
        if (SET) Q <= 1'b1;
        else Q <= D;
    end
endmodule

module DFF (input CK, D, output reg Q, output QB);
    assign QB = ~Q;
    always @(posedge CK) Q <= D;
endmodule

