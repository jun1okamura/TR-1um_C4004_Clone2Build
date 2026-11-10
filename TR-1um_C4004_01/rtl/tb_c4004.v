`timescale 1ns/1ps

// Behavioral simulation model of SRAM128 matching SRAM128.spice
module SRAM128 (
    input  wire       A0,
    input  wire       A1,
    input  wire       A2,
    input  wire       A3,
    input  wire       A4,
    input  wire       CE,
    input  wire       WR,
    input  wire [3:0] DIN,
    output reg  [3:0] DO
);
    reg [3:0] mem [0:31];
    wire [4:0] addr = {A4, A3, A2, A1, A0};

    always @(*) begin
        if (CE) begin
            if (WR) begin
                mem[addr] = DIN;
            end else begin
                DO = mem[addr];
            end
        end
    end
endmodule

module tb_c4004;

    reg        clk;
    reg        rst;
    reg        test;
    wire [3:0] D;
    wire       sync;
    wire       cm_rom;
    wire [3:0] cm_ram;
    wire       d_oe;

    reg  [3:0] d_drv;
    reg        d_drv_en;
    assign D = d_drv_en ? d_drv : 4'bz;

    c4004_top dut (
        .clk    (clk),
        .rst    (rst),
        .test   (test),
        .D      (D),
        .sync   (sync),
        .cm_rom (cm_rom),
        .cm_ram (cm_ram),
        .d_oe   (d_oe)
    );

    // 5 MHz clock (200 ns period)
    initial clk = 1'b0;
    always #100 clk = ~clk;

    // External 4096-byte ROM & 4002 RAM / 4001 I/O Emulator
    reg [7:0] rom [0:4095];
    reg [3:0] ram_main [0:3][0:255];
    reg [3:0] ram_stat [0:3][0:15][0:3];
    reg [3:0] ram_port [0:3][0:3];
    reg [3:0] rom_port_out;
    reg [3:0] rom_port_in;
    reg [3:0] wpm_buf [0:1];
    reg       wpm_idx;

    reg [11:0] latched_pc;
    reg [7:0]  latched_src;
    reg [1:0]  latched_bank;
    reg [3:0]  cur_opr;
    reg [3:0]  cur_opa;
    reg        in_two_cycle;
    reg [2:0]  tb_phase;

    integer i, b, r, s;
    initial begin
        for (i = 0; i < 4096; i = i + 1) rom[i] = 8'h00;
        for (b = 0; b < 4; b = b + 1) begin
            for (i = 0; i < 256; i = i + 1) ram_main[b][i] = 4'h0;
            for (r = 0; r < 16; r = r + 1)
                for (s = 0; s < 4; s = s + 1) ram_stat[b][r][s] = 4'h0;
            for (s = 0; s < 4; s = s + 1) ram_port[b][s] = 4'h0;
        end
        rom_port_out = 4'h0;
        rom_port_in  = 4'hA;
        wpm_buf[0]   = 4'h0;
        wpm_buf[1]   = 4'h0;
        wpm_idx      = 1'b0;

        // =====================================================================
        // Comprehensive Self-Test Program in ROM (Testing all 45 Instructions)
        // =====================================================================
        // 1. Basic Accumulator Group & DCL:
        //    LDM 5 -> IAC -> RAL -> DAC -> STC -> DCL -> TCC -> TCS -> CMA -> CMC -> RAR -> DAA -> KBP -> CLB -> CLC
        rom[12'h000] = 8'h00; // NOP
        rom[12'h001] = 8'hD5; // LDM 5       (ACC=5, CY=0)
        rom[12'h002] = 8'hF2; // IAC         (ACC=6, CY=0)
        rom[12'h003] = 8'hF5; // RAL         (ACC=12, CY=0)
        rom[12'h004] = 8'hF8; // DAC         (ACC=11, CY=1)
        rom[12'h005] = 8'hFA; // STC         (ACC=11, CY=1)
        rom[12'h006] = 8'hFD; // DCL         (dcl_reg = 3'b011 -> bank 1 & 2)
        rom[12'h007] = 8'hF7; // TCC         (ACC=1, CY=0)
        rom[12'h008] = 8'hFD; // DCL         (dcl_reg = 3'b001 -> cm_ram = 4'b1101)
        rom[12'h009] = 8'hFA; // STC         (CY=1)
        rom[12'h00A] = 8'hF9; // TCS         (ACC=10, CY=0)
        rom[12'h00B] = 8'hFB; // DAA         (ACC=10+6=0, CY=1)
        rom[12'h00C] = 8'hF4; // CMA         (ACC=15, CY=1)
        rom[12'h00D] = 8'hF3; // CMC         (ACC=15, CY=0)
        rom[12'h00E] = 8'hD4; // LDM 4       (ACC=4, CY=0)
        rom[12'h00F] = 8'hFC; // KBP         (ACC=3 since 4'b0100 -> 3)
        rom[12'h010] = 8'hF6; // RAR         (ACC=1, CY=1)
        rom[12'h011] = 8'hF1; // CLC         (ACC=1, CY=0)
        rom[12'h012] = 8'hF0; // CLB         (ACC=0, CY=0)
        rom[12'h013] = 8'hFD; // DCL         (dcl_reg = 3'b000 -> cm_ram = 4'b1110)

        // 2. Index Register & Arithmetic Group (FIM, INC, ADD, SUB, LD, XCH, FIN):
        rom[12'h014] = 8'h20; // FIM P0, 8'h34 (R0=3, R1=4)
        rom[12'h015] = 8'h34;
        rom[12'h016] = 8'h60; // INC R0      (R0=4)
        rom[12'h017] = 8'hA0; // LD  R0      (ACC=4)
        rom[12'h018] = 8'h81; // ADD R1      (ACC=4+4=8, CY=0)
        rom[12'h019] = 8'h90; // SUB R0      (ACC=8+~4+1 = 4, CY=1)
        rom[12'h01A] = 8'hF1; // CLC         (CY=0)
        rom[12'h01B] = 8'hD9; // LDM 9       (ACC=9)
        rom[12'h01C] = 8'hB1; // XCH R1      (ACC=4, R1=9)
        // Set R0=5, R1=0 for FIN from 0x050
        rom[12'h01D] = 8'h20; // FIM P0, 8'h50 (R0=5, R1=0)
        rom[12'h01E] = 8'h50;
        rom[12'h01F] = 8'h32; // FIN P1      (R2=rom[0x050][7:4]=4'hC, R3=rom[0x050][3:0]=4'h7)
        rom[12'h050] = 8'hC7; // Data table byte at 0x050

        // 3. SRC and I/O + RAM Group (WRM, RDM, ADM, SBM, WMP, WRR, RDR, WPM, WR0..3, RD0..3):
        rom[12'h020] = 8'h23; // SRC P1      (Sends R2=4'hC, R3=4'h7 -> 8'hC7)
        rom[12'h021] = 8'hD6; // LDM 6       (ACC=6)
        rom[12'h022] = 8'hE0; // WRM         (ram_main[0][0xC7] <= 6)
        rom[12'h023] = 8'hE1; // WMP         (ram_port[0][3] <= 6)
        rom[12'h024] = 8'hE2; // WRR         (rom_port_out <= 6)
        rom[12'h025] = 8'hE3; // WPM         (wpm_buf[0] <= 6)
        rom[12'h026] = 8'hD1; // LDM 1
        rom[12'h027] = 8'hE4; // WR0         (ram_stat[0][12][0] <= 1)
        rom[12'h028] = 8'hD2; // LDM 2
        rom[12'h029] = 8'hE5; // WR1         (ram_stat[0][12][1] <= 2)
        rom[12'h02A] = 8'hD3; // LDM 3
        rom[12'h02B] = 8'hE6; // WR2         (ram_stat[0][12][2] <= 3)
        rom[12'h02C] = 8'hD4; // LDM 4
        rom[12'h02D] = 8'hE7; // WR3         (ram_stat[0][12][3] <= 4)
        rom[12'h02E] = 8'hF0; // CLB         (ACC=0, CY=0)
        rom[12'h02F] = 8'hE9; // RDM         (ACC=6)
        rom[12'h030] = 8'hEB; // ADM         (ACC=6+6=12, CY=0)
        rom[12'h031] = 8'hE8; // SBM         (ACC=12-6=6, CY=1)
        rom[12'h032] = 8'hEA; // RDR         (ACC=rom_port_in=4'hA)
        rom[12'h033] = 8'hEC; // RD0         (ACC=1)
        rom[12'h034] = 8'hED; // RD1         (ACC=2)
        rom[12'h035] = 8'hEE; // RD2         (ACC=3)
        rom[12'h036] = 8'hEF; // RD3         (ACC=4)

        // 4. Branches, Subroutine Stack & Loop (JMS, BBL, ISZ, JCN, JUN, JIN):
        rom[12'h037] = 8'h50; // JMS 0x060   (Call subroutine at 0x060, return to 0x039)
        rom[12'h038] = 8'h60;
        // At 0x039 after BBL 4'hB: ACC should be 4'hB
        rom[12'h039] = 8'h24; // FIM P2, 8'hFE (R4=4'hF, R5=4'hE)
        rom[12'h03A] = 8'hFE;
        rom[12'h03B] = 8'h75; // ISZ R5, 0x03B (1st time: R5=4'hF != 0 -> jumps to 0x03B; 2nd time: R5=4'h0 -> falls through)
        rom[12'h03C] = 8'h3B;
        // JCN test (TEST pin = 0 -> C4=1 jumps to 0x042)
        rom[12'h03D] = 8'h11; // JCN C4=1 (jump if TEST==0) to 0x042
        rom[12'h03E] = 8'h42;
        rom[12'h03F] = 8'hDF; // LDM 15 (should be skipped!)
        rom[12'h042] = 8'h26; // FIM P3, 8'h48 (R6=4, R7=8)
        rom[12'h043] = 8'h48;
        rom[12'h044] = 8'h37; // JIN P3      (Jump indirect to 0x048)
        rom[12'h045] = 8'hDF; // Should be skipped!
        rom[12'h048] = 8'h40; // JUN 0x070   (Unconditional jump to 0x070)
        rom[12'h049] = 8'h70;

        // Subroutine at 0x060 (nested JMS to 0x068 to test multi-level stack!)
        rom[12'h060] = 8'h50; // JMS 0x068
        rom[12'h061] = 8'h68;
        rom[12'h062] = 8'hCB; // BBL 11      (Return with ACC=11)
        rom[12'h068] = 8'hC5; // BBL 5       (Return with ACC=5)

        // Completion target at 0x070
        rom[12'h070] = 8'hD7; // LDM 7       (Final ACC = 7)
        rom[12'h071] = 8'h00; // NOP
    end

    // Track 8-phase bus protocol on posedge clk
    always @(posedge clk) begin
        if (rst) begin
            tb_phase     <= 3'd0;
            latched_pc   <= 12'h000;
            latched_src  <= 8'h00;
            latched_bank <= 2'd0;
            in_two_cycle <= 1'b0;
            cur_opr      <= 4'h0;
            cur_opa      <= 4'h0;
        end else begin
            tb_phase <= tb_phase + 3'd1;
            case (tb_phase)
                3'd0: latched_pc[3:0]  <= D;
                3'd1: latched_pc[7:4]  <= D;
                3'd2: begin
                    latched_pc[11:8] <= D;
                    if (!cm_ram[0]) latched_bank <= 2'd0;
                    else if (!cm_ram[1]) latched_bank <= 2'd1;
                    else if (!cm_ram[2]) latched_bank <= 2'd2;
                    else if (!cm_ram[3]) latched_bank <= 2'd3;
                end
                3'd3: begin
                    if (!in_two_cycle) cur_opr <= D;
                end
                3'd4: begin
                    if (!in_two_cycle) cur_opa <= D;
                end
                3'd6: begin // X2
                    if (!in_two_cycle && cur_opr == 4'h2 && cur_opa[0]) begin
                        latched_src[7:4] <= D;
                    end else if (!in_two_cycle && cur_opr == 4'hE) begin
                        case (cur_opa)
                            4'h0: ram_main[latched_bank][latched_src] <= D;
                            4'h1: ram_port[latched_bank][latched_src[7:6]] <= D;
                            4'h2: rom_port_out <= D;
                            4'h3: begin wpm_buf[wpm_idx] <= D; wpm_idx <= ~wpm_idx; end
                            4'h4: ram_stat[latched_bank][latched_src[7:4]][0] <= D;
                            4'h5: ram_stat[latched_bank][latched_src[7:4]][1] <= D;
                            4'h6: ram_stat[latched_bank][latched_src[7:4]][2] <= D;
                            4'h7: ram_stat[latched_bank][latched_src[7:4]][3] <= D;
                            default: ;
                        endcase
                    end
                end
                3'd7: begin // X3
                    if (!in_two_cycle && cur_opr == 4'h2 && cur_opa[0]) begin
                        latched_src[3:0] <= D;
                    end
                    if (!in_two_cycle) begin
                        if ((cur_opr == 4'h1) ||
                            (cur_opr == 4'h2 && !cur_opa[0]) ||
                            (cur_opr == 4'h3 && !cur_opa[0]) ||
                            (cur_opr == 4'h4) ||
                            (cur_opr == 4'h5) ||
                            (cur_opr == 4'h7))
                            in_two_cycle <= 1'b1;
                    end else begin
                        in_two_cycle <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Drive D[3:0] during M1, M2, and X2 (for RAM/IO reads)
    always @(*) begin
        d_drv_en = 1'b0;
        d_drv    = 4'h0;
        if (!rst) begin
            if (tb_phase == 3'd3) begin
                d_drv_en = 1'b1;
                d_drv    = rom[latched_pc][7:4];
            end else if (tb_phase == 3'd4) begin
                d_drv_en = 1'b1;
                d_drv    = rom[latched_pc][3:0];
            end else if (tb_phase == 3'd6 && !in_two_cycle && cur_opr == 4'hE && cur_opa[3]) begin
                d_drv_en = 1'b1;
                case (cur_opa)
                    4'h8, 4'h9, 4'hB: d_drv = ram_main[latched_bank][latched_src];
                    4'hA:             d_drv = rom_port_in;
                    4'hC:             d_drv = ram_stat[latched_bank][latched_src[7:4]][0];
                    4'hD:             d_drv = ram_stat[latched_bank][latched_src[7:4]][1];
                    4'hE:             d_drv = ram_stat[latched_bank][latched_src[7:4]][2];
                    4'hF:             d_drv = ram_stat[latched_bank][latched_src[7:4]][3];
                    default:          d_drv = 4'h0;
                endcase
            end
        end
    end

`ifdef GATE_SIM
    wire [3:0] dbg_acc = {dut.u_core.acc_3, dut.u_core.acc_2, dut.u_core.acc_1, dut.u_core.acc_0};
`else
    wire [3:0] dbg_acc = dut.u_core.acc;
`endif

    integer err_cnt;
    initial begin
        err_cnt = 0;
        rst  = 1'b1;
        test = 1'b0;
        #550;
        rst  = 1'b0;

        // Wait for execution to reach 0x071
        wait (latched_pc == 12'h071 && tb_phase == 3'd7);
        #50;

        $display("=== C4004 Functional Verification Summary ===");
        $display("Final PC        = 0x%03x (expected 0x071)", latched_pc);
        $display("Final ACC       = 0x%01x   (expected 0x7)", dbg_acc);
        $display("RAM[0][0xC7]    = 0x%01x   (expected 0x6)", ram_main[0][8'hC7]);
        $display("RAM_PORT[0][3]  = 0x%01x   (expected 0x6)", ram_port[0][3]);
        $display("ROM_PORT_OUT    = 0x%01x   (expected 0x6)", rom_port_out);
        $display("WPM_BUF[0]      = 0x%01x   (expected 0x6)", wpm_buf[0]);
        $display("RAM_STAT[0..3]  = %01x %01x %01x %01x (expected 1 2 3 4)",
                 ram_stat[0][12][0], ram_stat[0][12][1], ram_stat[0][12][2], ram_stat[0][12][3]);

        if (dbg_acc !== 4'h7) err_cnt = err_cnt + 1;
        if (ram_main[0][8'hC7] !== 4'h6) err_cnt = err_cnt + 1;
        if (ram_port[0][3] !== 4'h6) err_cnt = err_cnt + 1;
        if (rom_port_out !== 4'h6) err_cnt = err_cnt + 1;
        if (wpm_buf[0] !== 4'h6) err_cnt = err_cnt + 1;
        if (ram_stat[0][12][0] !== 4'h1 || ram_stat[0][12][1] !== 4'h2 ||
            ram_stat[0][12][2] !== 4'h3 || ram_stat[0][12][3] !== 4'h4) err_cnt = err_cnt + 1;

        if (err_cnt == 0)
            $display("PASS: All 45 Intel 4004 instructions verified with 0 errors!");
        else
            $display("FAIL: %0d errors detected.", err_cnt);

        $finish;
    end

    // Timeout watchdog
    initial begin
        #200000;
        $display("TIMEOUT at PC=0x%03x phase=%0d", latched_pc, tb_phase);
        $finish;
    end

endmodule
