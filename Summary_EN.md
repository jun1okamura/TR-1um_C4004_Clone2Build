# TR-1um C4004 4-bit CPU Design & Optimization Summary (`Summary_EN.md`)

This document summarizes the iterative design, physical implementation, and post-layout verification trials (**all 10 trials completed: `TR-1um_C4004_01` through `TR-1um_C4004_10`**) of the Intel 4004 compatible 4-bit CPU (`C4004`) on the OpenSUSI `TR-1um` PDK (`1 µm` CMOS, 2-metal `M1`/`M2`, `5.0 V` supply, `2500 µm × 2500 µm` 16-pad frame).

---

## 1. Trial Comparison Summary Table (Trials 01–10)

| Metric / Parameter | Trial 01 (`TR-1um_C4004_01`) | Trial 02 (`TR-1um_C4004_02`) | Trial 03 (`TR-1um_C4004_03`) | Trial 04 (`TR-1um_C4004_04`) | Trial 05 (`TR-1um_C4004_05`) | Trial 06 (`TR-1um_C4004_06`) | Trial 07 (`TR-1um_C4004_07`) | Trial 08 (`TR-1um_C4004_08`) | **Trial 09 (`TR-1um_C4004_09`) [Best WL & Power!]** | **Trial 10 (`TR-1um_C4004_10`) [All-Time Record 19.0 MHz!!]** |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Die Size / Core Area** | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | `2500×2500 µm` / `1840×1840 µm` | **`2500×2500 µm` / `1840×1840 µm`** |
| **RTL Microarchitecture Optimization** | Baseline 37-FF + Shared Ripple-Carry Adder | Shadow PC Bypass (`buf_l/m/h`) + Explicit 4-bit CLA | Early `X1` Reg Pre-Read Pipeline ALU (Shared `buf_l`) | Non-Stop Shadow PC + Dedicated `reg_buf` `X1` Pre-Read Full-Cycle CLA | Non-Stop Shadow PC + 4-bit Symmetric `NAND3+MUXDFFRB` `reg_buf[3:0]` | Non-Stop Shadow PC + Symmetric `reg_buf[3:0]` + Dedicated `BUF_X2` `d_hiz`/`d_oe` Drivers | Non-Stop Shadow PC + Symmetric `reg_buf[3:0]` + `BUF_X2` `d_hiz`/`d_oe` + `OR3+INV_X1` `sram_ce` Driver | Non-Stop Shadow PC + Symmetric `reg_buf[3:0]` + Direct `clk_in_th` Single-Stage `NOR3` `sram_ce` + 9-Branch Clock/Reset Tree | Non-Stop Shadow PC + Symmetric `reg_buf[3:0]` + Direct `clk_in_th` `NOR3` `sram_ce` + South `_1072_` Anchor + 8-Branch Clock/Reset Tree (`FO=9`) | **Non-Stop Shadow PC + 8-Branch Clock/Reset Tree (`FO=9`) + Cascaded `d_hiz`/`d_oe` (`FO(d_hiz_pre)=1`) + Row-8 Co-Located Half-Cycle `X1` `reg_buf[3:0]` & `NAND2/3`** |
| **`SRAM128` Macro Coordinates `(X, Y)`** | `(338.2 µm, 1603.8 µm)` | `(334.8 µm, 1587.6 µm)` | `(334.8 µm, 1609.2 µm)` | `(334.8 µm, 1614.6 µm)` | `(340.2 µm, 1614.6 µm)` | `(345.6 µm, 1614.6 µm)` | `(340.2 µm, 1609.2 µm)` | `(340.2 µm, 1614.6 µm)` | `(334.8 µm, 1614.6 µm)` | **`(340.2 µm, 1614.6 µm)` (Centered + North)** |
| **Standard-Cell Rows (Routing Channels)** | `9` Rows (Pitch `178.2 µm` / Channel `118.8 µm` = 22 tracks) | `10` Rows (Pitch `156.6 µm` / Channel `97.2 µm` = 18 tracks) | `10` Rows (GCell Pitch `162.0 µm` / Channel `102.6 µm` = 19 tracks) | `11` Rows (Pitch `145.8 µm` / Channel `86.4 µm` = 16 tracks) | `11` Rows (Pitch `145.8 µm` / Channel `86.4 µm` = 16 tracks) | `11` Rows (Pitch `145.8 µm` / Channel `86.4 µm` = 16 tracks) | `11` Rows (Pitch `145.8 µm` / Channel `86.4 µm` = 16 tracks) | `11` Rows (Pitch `145.8 µm` / Channel `86.4 µm` = 16 tracks) | `11` Rows (Pitch `145.8 µm` / Channel `86.4 µm` = 16 tracks) | **`11` Rows (Pitch `145.8 µm` / Channel `86.4 µm` = 16 tracks)** |
| **Total Sites / Logic Used Sites (Utilization)** | `2,925` / `2,726` (`93.20%`) | `3,250` / `2,649` (`81.51%`) | `3,250` / `2,764` (`85.05%`) | `3,575` / `2,839` (`79.41%`) | `3,575` / `2,837` (`79.36%`) | `3,575` / `2,843` (`79.52%`) | `3,575` / `2,846` (`79.61%`) | `3,575` / `2,837` (`79.36%`) | **`3,575` / `2,831` (`79.19%` All-Time Lowest!)** | **`3,575` / `2,831` (`79.19%` All-Time Lowest Tied!)** |
| **Total Logic Cells (StdCells + Macro)** | `599` (`598` stdcells + `1 SRAM128`) | `579` (`578` stdcells + `1 SRAM128`) | `607` (`606` stdcells + `1 SRAM128`) | `616` (`615` stdcells + `1 SRAM128`) | `614` (`613` stdcells + `1 SRAM128`) | `616` (`615` stdcells + `1 SRAM128`) | `617` (`616` stdcells + `1 SRAM128`) | `614` (`613` stdcells + `1 SRAM128`) | **`612` (`611` stdcells + `1 SRAM128` Lowest 41-FF!)** | **`612` (`611` stdcells + `1 SRAM128` Lowest 41-FF Tied!)** |
| **Sequential Flip-Flops (FFs)** | `37` (`22 MUXDFFRB` + `15 DFFRB`) | `37` (`22 MUXDFFRB` + `15 DFFRB`) | `37` (`22 MUXDFFRB` + `15 DFFRB`) | `41` (`25 MUXDFFRB` + `16 DFFRB`) | `41` (`26 MUXDFFRB` + `15 DFFRB`) | `41` (`26 MUXDFFRB` + `15 DFFRB`) | `41` (`26 MUXDFFRB` + `15 DFFRB`) | `41` (`26 MUXDFFRB` + `15 DFFRB`) | `41` (`26 MUXDFFRB` + `15 DFFRB`) | **`41` (`26 MUXDFFRB` + `15 DFFRB`)** |
| **Decap Filler Cells / Sites** | `72` (`55 FILL3` + `17 FILL2`) / `199` sites | `211` (`179 FILL3` + `32 FILL2`) / `601` sites | `175` (`136 FILL3` + `39 FILL2`) / `486` sites | `257` (`222 FILL3` + `35 FILL2`) / `736` sites | `254` (`230 FILL3` + `24 FILL2`) / `738` sites | `253` (`226 FILL3` + `27 FILL2`) / `732` sites | `255` (`219 FILL3` + `36 FILL2`) / `729` sites | `258` (`222 FILL3` + `36 FILL2`) / `738` sites | **`256` (`232 FILL3` + `24 FILL2`) / `744` sites (Max!)** | **`258` (`228 FILL3` + `30 FILL2`) / `744` sites (Max Tied!)** |
| **Total MOSFETs (Combined / Multi-Finger `M=`)** | `6,108` / `6,368` MOSFETs (+ `28` Diodes) | `6,252` / `6,512` MOSFETs (+ `28` Diodes) | `6,364` / `6,624` MOSFETs (+ `28` Diodes) | `6,692` / `6,952` MOSFETs (+ `28` Diodes) | `6,686` / `6,946` MOSFETs (+ `28` Diodes) | `6,692` / `6,952` MOSFETs (+ `28` Diodes) | `6,700` / `6,960` MOSFETs (+ `28` Diodes) | `6,694` / `6,954` MOSFETs (+ `28` Diodes) | **`6,682` / `6,942` MOSFETs (+ `28` Diodes, Lowest 41-FF!)** | `6,686` / `6,946` MOSFETs (+ `28` Diodes) |
| **OpenROAD Total Wirelength (`M1` + `M2`)** | `442,818 µm` (`218,035` + `224,783 µm`) | **`420,271 µm`** (`215,633` + `204,637 µm`) | `431,639 µm` (`214,383` + `217,256 µm`) | `448,871 µm` (`224,708` + `224,162 µm`) | `446,626 µm` (`222,628` + `223,997 µm`) | `448,037 µm` (`224,286` + `223,750 µm`) | `456,846 µm` (`225,921` + `230,924 µm`) | `438,162 µm` (`217,831` + `220,331 µm`) | **`430,680 µm` (`216,368` + `214,312 µm`) [Best 41-FF WL!]** | `450,643 µm` (`220,437` + `230,206 µm`) |
| **Total Signal Vias (`V1`)** | `2,756` | `2,643` | **`2,607` (Lowest Vias)** | `2,890` | `2,906` | `2,939` | `2,910` | `2,844` | **`2,717` [Lowest 41-FF Vias! < Trial 01!]** | `2,985` |
| **OpenROAD DRC / KLayout Signoff DRC** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** | **`0` / `0` Errors** |
| **KLayout Signoff LVS (`deep` & `flat`)** | **`Match`** | **`Match`** | **`Match`** | **`Match`** | **`Match`** | **`Match`** | **`Match`** | **`Match`** | **`Match`** | **`Match`** |
| **Max Clock Frequency `FMAX` (`ngspice`, `1.0 pF`)** | `8.0 MHz` (Internal ALU `9.0 MHz`) | `11.0 MHz` (`+37.5%`) | `8.5 MHz` (Internal ALU `15.0 MHz`) | `16.5 MHz` (Ext PC `20.0+ MHz`) | `17.0 MHz` (Ext PC `20.0+ MHz`) | `17.0 MHz` (Ext PC `22.0+ MHz`) | `16.0 MHz` | `18.5 MHz` (`+131.3%` / `2.313×`) | `18.5 MHz` (`+131.3%` + `19 MHz` Bus PASS!) | **`19.0 MHz` (`+137.5%` / `2.375×` All-Time Record!!)** |
| **Instruction Cycle Time (`8 × T_clk`) @ `FMAX`** | `1.000 µs` (`1.000 MIPS`) | `0.727 µs` (`1.375 MIPS`) | `0.941 µs` (`1.063 MIPS`) | `0.485 µs` (`2.063 MIPS`) | `0.471 µs` (`2.125 MIPS`) | `0.471 µs` (`2.125 MIPS`) | `0.500 µs` (`2.000 MIPS`) | `0.432 µs` (`2.313 MIPS`) | `0.432 µs` (`2.313 MIPS`) | **`0.421 µs` (`2.375 MIPS` All-Time Record!!)** |
| **Pad Output Delays `t_pd` (`sync` / `cm_rom` / `d_oe` / `D[3:0]`)** | `33.66` / `33.89` / `43.13` / `39.83 ns` | `34.23` / `39.32` / `44.72` / `40.72 ns` | `33.82` / `34.03` / `44.66` / `39.44 ns` | `35.30` / `35.59` / `47.42` / `41.41 ns` | `35.29` / `35.57` / `47.40` / `41.39 ns` | `35.29` / `35.57` / `44.86` / `40.85 ns` | `34.78` / `35.09` / `44.39` / `40.37 ns` | `34.71` / `35.00` / `44.29` / `40.28 ns` | **`34.37` / `34.69` / `43.95` / `39.96 ns` (@ `18.5 MHz`)** | **`34.37` / `34.67` / `45.47` / `39.81 ns` (@ `19.0 MHz` Best 41-FF `D[3:0]`!)** |
| **Average Power (`@ 1 MHz` / `@ 8 MHz` / `@ FMAX`)** | `1.688 mW` / `12.509 mW` / `12.509 mW` | `1.560 mW` / `11.508 mW` / `15.750 mW` (`@ 11 MHz`) | `1.686 mW` / `12.407 mW` / `13.177 mW` (`@ 8.5 MHz`) | `1.604 mW` / `11.911 mW` / `24.329 mW` (`@ 16.5 MHz`) | `1.602 mW` / `11.897 mW` / `25.045 mW` (`@ 17.0 MHz`) | `1.613 mW` / `11.973 mW` / `25.208 mW` (`@ 17.0 MHz`) | `1.609 mW` / `11.952 mW` / `23.658 mW` (`@ 16.0 MHz`) | `1.588 mW` / `11.783 mW` / `26.995 mW` (`@ 18.5 MHz`) | **`1.570 mW` / `11.630 mW` (Best 41-FF!) / `26.641 mW` (`@ 18.5 MHz`)** | `1.574 mW` / `11.673 mW` / **`27.469 mW` (`@ 19.0 MHz`)** |

---

## Trial 01: `TR-1um_C4004_01`

### 1. Architecture & Floorplan Highlights
- **Baseline 37-FF Architecture**: Full implementation of all 45 Intel 4004 instructions using a single `SRAM128` macro (`32 × 4-bit`: 16 index registers `R0..R15` and `4 × 12-bit` PC/stack) and a shared 4-bit ripple-carry adder.
- **9-Row Floorplan**: 9 standard-cell rows (`row_pitch = 178.2 µm`, channel height = `118.8 µm` = 22 tracks, `2,925` sites) with `SRAM128` at `(338.2 µm, 1603.8 µm)`.
- **Post-Layout Performance**: Achieved **`FMAX = 8.0 MHz` (`1.000 MIPS`)**, limited by the half-cycle `negedge clk -> SRAM128 PC read -> D[3:0]` pad output path in `A1`.

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_01`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | `598` cells | Used sites: `2,726` / `2,925` (`93.20%`) |
| | Sequential Cells (FFs) | `37` FFs | `MUXDFFRB`: 22, `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | `56` cells | `BUF_X2`: 9 clk + 9 rst + 38 high-FO |
| | Combinational Logic Cells | `498` cells | Baseline 37-FF + shared ripple-carry adder |
| | Memory Macro | `1` macro | `SRAM128` at `(338.2 µm, 1603.8 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `36` cells | 4 columns × 9 rows |
| | Decap Filler Cells | `72` cells | `FILL3`: 55 (`165` sites), `FILL2`: 17 (`34` sites), `FILL1`: 0 (Total `199` sites) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,368` MOSFETs | `PMOS`: 2,990, `NMOS`: 3,218, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,108` MOSFETs | `PMOS`: 2,860, `NMOS`: 3,218, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `5,824` MOSFETs | `PMOS`: 2,718, `NMOS`: 3,106 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `647` / `10` | All nets meet `FO <= 10` |
| | OpenROAD Total Wirelength | `442,818 µm` | `METAL1`: `218,035 µm` (`49.24%`), `METAL2`: `224,783 µm` (`50.76%`) |
| | Signal Vias (`V1`) | `2,756` vias | OpenROAD Detailed Routing: `0` DRC violations |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_01`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `33.65 ns` | `33.87 ns` | `43.14 ns` | `39.84 ns` | `0.338 mA` | `1.688 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `33.66 ns` | `33.87 ns` | `43.14 ns` | `39.84 ns` | `0.649 mA` | `3.246 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `33.66 ns` | `33.88 ns` | `43.14 ns` | `39.84 ns` | `1.270 mA` | `6.349 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `33.66 ns` | `33.88 ns` | `43.13 ns` | `39.83 ns` | `1.886 mA` | `9.431 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS (`FMAX`)** | `0x006` | **`0xA`** | `33.66 ns` | `33.89 ns` | `43.13 ns` | `39.83 ns` | `2.502 mA` | `12.509 mW` |
| `9.0 MHz` | `111.1 ns` | FAIL (`PC` Read) | `0x000` | **`0xA` (ALU PASS)** | `33.65 ns` | `33.89 ns` | `43.12 ns` | `39.83 ns` | `2.753 mA` | `13.765 mW` |
| `10.0 MHz` | `100.0 ns` | FAIL | `0x009` | `0xB` | `33.65 ns` | `33.89 ns` | `43.12 ns` | `39.83 ns` | `3.004 mA` | `15.019 mW` |
| `12.0 MHz` | `83.3 ns` | FAIL | `0x019` | `0x3` | `33.54 ns` | `33.76 ns` | `42.99 ns` | `39.71 ns` | `3.707 mA` | `18.537 mW` |
| `14.0 MHz` | `71.4 ns` | FAIL | `0x819` | `0x9` | `33.46 ns` | `33.69 ns` | `42.92 ns` | `39.64 ns` | `4.656 mA` | `23.282 mW` |
| `16.0 MHz` | `62.5 ns` | FAIL | `0x819` | `0x5` | `33.42 ns` | `33.63 ns` | `42.86 ns` | `39.58 ns` | `5.210 mA` | `26.052 mW` |

---

## Trial 02: `TR-1um_C4004_02`

### 1. Architecture & Floorplan Highlights
- **Shadow PC Bypass (`pc_init_n`) + Explicit 4-bit CLA**: Drives `PC` directly from `buf_l/buf_m/buf_h` FFs at `posedge clk` when `pc_init_n == 0` and replaces the ripple-carry adder with a 2-level Carry-Lookahead Adder (CLA), reducing logic cells by 20 (`578` stdcells).
- **10-Row Floorplan**: Expanded to 10 rows (`row_pitch = 156.6 µm`, channel = `97.2 µm` = 18 tracks, `3,250` sites) with `SRAM128` at `(334.8 µm, 1587.6 µm)` and `601` sites of decap fillers, achieving the shortest wirelength (`420,271 µm`, `-5.09%`) and **`FMAX = 11.0 MHz` (`+37.5%`)**.

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_02`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | `578` cells | Used sites: `2,649` / `3,250` (`81.51%`) |
| | Sequential Cells (FFs) | `37` FFs | `MUXDFFRB`: 22, `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | `56` cells | `BUF_X2`: 10 clk + 10 rst + 36 high-FO |
| | Combinational Logic Cells | `478` cells | Shadow PC Bypass + Explicit 4-bit CLA (`-20` cells) |
| | Memory Macro | `1` macro | `SRAM128` at `(334.8 µm, 1587.6 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `40` cells | 4 columns × 10 rows |
| | Decap Filler Cells | `211` cells | `FILL3`: 179 (`537` sites), `FILL2`: 32 (`64` sites), `FILL1`: 0 (Total `601` sites) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,512` MOSFETs | `PMOS`: 3,062, `NMOS`: 3,290, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,252` MOSFETs | `PMOS`: 2,932, `NMOS`: 3,290, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `5,968` MOSFETs | `PMOS`: 2,790, `NMOS`: 3,178 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `627` / `10` | All nets meet `FO <= 10` |
| | OpenROAD Total Wirelength | **`420,271 µm`** | `METAL1`: `215,633 µm` (`51.31%`), `METAL2`: `204,637 µm` (`48.69%`) [Shortest WL] |
| | Signal Vias (`V1`) | `2,643` vias | OpenROAD Detailed Routing: `0` DRC violations |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_02`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.30 ns` | `39.38 ns` | `44.80 ns` | `40.80 ns` | `0.312 mA` | `1.560 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.30 ns` | `39.38 ns` | `44.80 ns` | `40.80 ns` | `0.599 mA` | `2.996 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.30 ns` | `39.39 ns` | `44.77 ns` | `40.79 ns` | `1.169 mA` | `5.846 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `34.30 ns` | `39.38 ns` | `44.80 ns` | `40.79 ns` | `1.733 mA` | `8.665 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.31 ns` | `39.39 ns` | `44.79 ns` | `40.79 ns` | `2.302 mA` | `11.508 mW` |
| **`8.5 MHz`** | `117.6 ns` | **PASS** | `0x006` | **`0xA`** | `34.31 ns` | `39.38 ns` | `44.79 ns` | `40.80 ns` | `2.444 mA` | `12.220 mW` |
| **`9.0 MHz`** | `111.1 ns` | **PASS** | `0x006` | **`0xA`** | `34.30 ns` | `39.38 ns` | `44.77 ns` | `40.79 ns` | `2.587 mA` | `12.933 mW` |
| **`9.5 MHz`** | `105.3 ns` | **PASS** | `0x006` | **`0xA`** | `34.28 ns` | `39.37 ns` | `44.77 ns` | `40.79 ns` | `2.729 mA` | `13.645 mW` |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.29 ns` | `39.37 ns` | `44.76 ns` | `40.78 ns` | `2.872 mA` | `14.359 mW` |
| **`10.5 MHz`** | `95.2 ns` | **PASS** | `0x006` | **`0xA`** | `34.26 ns` | `39.36 ns` | `44.72 ns` | `40.76 ns` | `3.010 mA` | `15.051 mW` |
| **`11.0 MHz`** | `90.9 ns` | **PASS (`FMAX`)** | `0x006` | **`0xA`** | `34.23 ns` | `39.32 ns` | `44.69 ns` | `40.72 ns` | `3.150 mA` | `15.750 mW` |
| `11.5 MHz` | `87.0 ns` | FAIL (`X2` SRAM+CLA) | `0x026` | `0x3` | `34.20 ns` | `39.29 ns` | `44.66 ns` | `40.70 ns` | `3.350 mA` | `16.749 mW` |
| `12.0 MHz` | `83.3 ns` | FAIL | `0x024` | `0x3` | `34.18 ns` | `39.26 ns` | `44.62 ns` | `40.67 ns` | `3.456 mA` | `17.282 mW` |
| `14.0 MHz` | `71.4 ns` | FAIL | `0x02B` | `0x7` | `34.10 ns` | `39.17 ns` | `44.55 ns` | `40.59 ns` | `4.102 mA` | `20.510 mW` |
| `16.0 MHz` | `62.5 ns` | FAIL | `0x02B` | `0xA` | `34.04 ns` | `39.12 ns` | `44.49 ns` | `40.53 ns` | `4.639 mA` | `23.195 mW` |

---

## Trial 03: `TR-1um_C4004_03`

### 1. Architecture & Floorplan Highlights
- **Early `X1` Register Pre-Read Pipeline**: Pre-reads `SRAM128` index register `R[opa]` in `X1` (`phase == 5`) into `buf_l` and runs the 4-bit CLA FF-to-FF across the full clock cycle (`1.0 × T_clk`) in `X2`, boosting internal ALU operation up to **`15.0 MHz`**, while sharing `buf_l` caused external `PC` reads to limit external `FMAX` to `8.5 MHz`.
- **GCell-Aligned 10-Row Floorplan**: `row_pitch = 162.0 µm` (`30` tracks = `2.0 × 81.0 µm` GCell, channel = `102.6 µm` = 19 tracks), `SRAM128` at `(334.8 µm, 1609.2 µm)`, achieving the **lowest via count (`2,607` vias)** across all trials.

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_03`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | `606` cells | Used sites: `2,764` / `3,250` (`85.05%`) |
| | Sequential Cells (FFs) | `37` FFs | `MUXDFFRB`: 22, `DFFRB`: 15 (`0` extra FFs) |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | `49` cells | `BUF_X2`: 10 clk + 10 rst + 29 high-FO (`-7` buffers) |
| | Combinational Logic Cells | `513` cells | Includes `X1` early reg read & `X2` stack write control |
| | Memory Macro | `1` macro | `SRAM128` at `(334.8 µm, 1609.2 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `40` cells | 4 columns × 10 rows |
| | Decap Filler Cells | `175` cells | `FILL3`: 136 (`408` sites), `FILL2`: 39 (`78` sites), `FILL1`: 0 (Total `486` sites) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,624` MOSFETs | `PMOS`: 3,118, `NMOS`: 3,346, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,364` MOSFETs | `PMOS`: 2,988, `NMOS`: 3,346, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `6,080` MOSFETs | `PMOS`: 2,846, `NMOS`: 3,234 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `654` / `10` | All nets meet `FO <= 10` |
| | OpenROAD Total Wirelength | `431,639 µm` | `METAL1`: `214,383 µm` (Lowest M1 WL), `METAL2`: `217,256 µm` |
| | Signal Vias (`V1`) | **`2,607` vias** | **Lowest via count across all trials (`-5.41%` vs Trial 01)** |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_03`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA` (PASS)** | `33.80 ns` | `34.03 ns` | `42.25 ns` | `39.43 ns` | `0.337 mA` | `1.686 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA` (PASS)** | `33.82 ns` | `34.03 ns` | `42.24 ns` | `39.44 ns` | `0.645 mA` | `3.224 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA` (PASS)** | `33.81 ns` | `34.01 ns` | `42.22 ns` | `39.44 ns` | `1.258 mA` | `6.292 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA` (PASS)** | `33.82 ns` | `34.03 ns` | `42.20 ns` | `39.44 ns` | `1.880 mA` | `9.399 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA` (PASS)** | `33.82 ns` | `34.03 ns` | `42.22 ns` | `39.44 ns` | `2.481 mA` | `12.407 mW` |
| **`8.5 MHz`** | `117.6 ns` | **PASS (`FMAX`)** | `0x006` | **`0xA` (PASS)** | `33.84 ns` | `34.03 ns` | `42.21 ns` | `39.45 ns` | `2.635 mA` | `13.177 mW` |
| `9.0 MHz` | `111.1 ns` | FAIL (Ext `PC`) | `0x000` | **`0xA` (ALU PASS)** | `33.83 ns` | `34.02 ns` | `42.22 ns` | `39.44 ns` | `2.789 mA` | `13.945 mW` |
| `10.0 MHz` | `100.0 ns` | FAIL (Ext `PC`) | `0x069` | **`0xA` (ALU PASS)** | `33.83 ns` | `34.04 ns` | `42.21 ns` | `39.44 ns` | `3.116 mA` | `15.582 mW` |
| `12.0 MHz` | `83.3 ns` | FAIL (Ext `PC`) | `0x029` | **`0xA` (ALU PASS)** | `33.71 ns` | `33.90 ns` | `42.07 ns` | `39.32 ns` | `3.672 mA` | `18.359 mW` |
| `14.0 MHz` | `71.4 ns` | FAIL (Ext `PC`) | `0xA19` | **`0xA` (ALU PASS)** | `33.64 ns` | `33.82 ns` | `41.98 ns` | `39.25 ns` | `4.396 mA` | `21.980 mW` |
| `15.0 MHz` | `66.7 ns` | FAIL (Ext `PC`) | `0xA99` | **`0xA` (ALU PASS!)** | `33.62 ns` | `33.80 ns` | `41.95 ns` | `39.22 ns` | `4.700 mA` | `23.501 mW` |
| `16.0 MHz` | `62.5 ns` | FAIL | `0xA99` | `0x2` | `33.58 ns` | `33.78 ns` | `41.94 ns` | `39.19 ns` | `5.069 mA` | `25.346 mW` |

---

## Trial 04: `TR-1um_C4004_04`

### 1. Architecture & Floorplan Highlights
- **Non-Stop Shadow PC + Dedicated `reg_buf[3:0]` `X1` Pre-Read Full-Cycle CLA (41 FFs)**: Introduces a dedicated 4-bit pipeline register `reg_buf[3:0]` so `buf_l/buf_m/buf_h` are never overwritten by `FIM`, `LD`, `ADD`, `SUB`, `INC`, `ISZ`, `XCH`, or `SRC`, keeping `pc_init_n == 0` continuously and achieving **`FMAX = 16.5 MHz` (`2.063 MIPS`)**.
- **11-Row Floorplan**: Expanded to 11 rows (`row_pitch = 145.8 µm` = 27 tracks, channel = `86.4 µm` = 16 tracks, `3,575` sites) with `SRAM128` at `(334.8 µm, 1614.6 µm)` and `736` sites of decap fillers.

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_04`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | `615` cells | Used sites: `2,839` / `3,575` (`79.41%`) |
| | Sequential Cells (FFs) | `41` FFs | `MUXDFFRB`: 25, `DFFRB`: 16 (Dedicated 4-FF `reg_buf[3:0]`) |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | `45` cells | `BUF_X2`: 10 clk + 10 rst + 25 high-FO (`-4` buffers) |
| | Combinational Logic Cells | `522` cells | Non-Stop Shadow PC + Full-Cycle CLA control |
| | Memory Macro | `1` macro | `SRAM128` at `(334.8 µm, 1614.6 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `44` cells | 4 columns × 11 rows |
| | Decap Filler Cells | `257` cells | `FILL3`: 222 (`666` sites), `FILL2`: 35 (`70` sites), `FILL1`: 0 (Total `736` sites) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,952` MOSFETs | `PMOS`: 3,282, `NMOS`: 3,510, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,692` MOSFETs | `PMOS`: 3,152, `NMOS`: 3,510, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `6,408` MOSFETs | `PMOS`: 3,010, `NMOS`: 3,398 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `667` / `10` | All nets meet `FO <= 10` |
| | OpenROAD Total Wirelength | `448,871 µm` | `METAL1`: `224,708 µm` (`50.06%`), `METAL2`: `224,162 µm` (`49.94%`) |
| | Signal Vias (`V1`) | `2,890` vias | Converged in 13 iterations (`68.69 s`) with `0` DRC violations |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_04`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.55 ns` | `35.83 ns` | `47.77 ns` | `41.68 ns` | `0.321 mA` | `1.604 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.84 ns` | `47.78 ns` | `41.69 ns` | `0.617 mA` | `3.087 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.85 ns` | `47.77 ns` | `41.69 ns` | `1.207 mA` | `6.034 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.84 ns` | `47.76 ns` | `41.67 ns` | `1.794 mA` | `8.969 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.85 ns` | `47.74 ns` | `41.66 ns` | `2.382 mA` | `11.911 mW` |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.84 ns` | `47.72 ns` | `41.67 ns` | `2.972 mA` | `14.860 mW` |
| **`11.0 MHz`** | `90.9 ns` | **PASS** | `0x006` | **`0xA`** | `35.49 ns` | `35.77 ns` | `47.64 ns` | `41.59 ns` | `3.262 mA` | `16.310 mW` |
| **`12.0 MHz`** | `83.3 ns` | **PASS** | `0x006` | **`0xA`** | `35.45 ns` | `35.73 ns` | `47.58 ns` | `41.56 ns` | `3.552 mA` | `17.761 mW` |
| **`13.0 MHz`** | `76.9 ns` | **PASS** | `0x006` | **`0xA`** | `35.40 ns` | `35.68 ns` | `47.56 ns` | `41.51 ns` | `3.842 mA` | `19.211 mW` |
| **`14.0 MHz`** | `71.4 ns` | **PASS** | `0x006` | **`0xA`** | `35.36 ns` | `35.65 ns` | `47.54 ns` | `41.47 ns` | `4.132 mA` | `20.661 mW` |
| **`15.0 MHz`** | `66.7 ns` | **PASS** | `0x006` | **`0xA`** | `35.33 ns` | `35.63 ns` | `47.49 ns` | `41.44 ns` | `4.425 mA` | `22.126 mW` |
| **`16.0 MHz`** | `62.5 ns` | **PASS** | `0x006` | **`0xA`** | `35.31 ns` | `35.60 ns` | `47.44 ns` | `41.42 ns` | `4.717 mA` | `23.587 mW` |
| **`16.5 MHz`** | `60.6 ns` | **PASS (`FMAX`)** | `0x006` | **`0xA`** | `35.30 ns` | `35.59 ns` | `47.42 ns` | `41.41 ns` | `4.866 mA` | `24.329 mW` |
| `17.0 MHz` | `58.8 ns` | FAIL (`reg_buf[3]`) | `0x006` (PASS) | `0x2` | `35.29 ns` | `35.57 ns` | `47.40 ns` | `41.39 ns` | `4.982 mA` | `24.909 mW` |
| `18.0 MHz` | `55.6 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `35.26 ns` | `35.55 ns` | `47.39 ns` | `41.37 ns` | `5.191 mA` | `25.954 mW` |
| `20.0 MHz` | `50.0 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `35.23 ns` | `35.52 ns` | `47.36 ns` | `41.33 ns` | `5.766 mA` | `28.829 mW` |

---

## Trial 05: `TR-1um_C4004_05` (Final Trial — Highest Performance)

### 1. Architecture & Floorplan Highlights
- **4-bit Symmetric `NAND3 + MUXDFFRB` `reg_buf[3:0]` Pipeline**: Restructured the `reg_buf[3]` (`_1146_`) input cone (`NOR2 _1005_ + AND3_X1 _1011_ + AOI21 _1012_ + DFFRB _1146_`) into `NAND3 _1011_ + MUXDFFRB _1146_` (matching `reg_buf[0..2]` so all 26 eligible FFs are folded into `MUXDFFRB`), removing 2 gate stages (~3.5 ns) from the critical `sram_do[3] -> reg_buf[3]` path and reducing the logic cell count to `613` stdcells (`2,837` sites = **`79.36%` utilization**, lowest of all 5 trials).
- **Horizontally Centered `SRAM128` on 11-Row Floorplan**: Placed `SRAM128` at `(340.2 µm, 1614.6 µm)` above 11 rows (`row_pitch = 145.8 µm`), achieving the maximum decap area (`738` sites = `3.71×` vs Trial 01), shorter wirelength (`446,626 µm`), and **`FMAX = 17.0 MHz` (`2.125 MIPS`, `+112.5%` / `2.125×` speedup over Trial 01)**.

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_05`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | **`613` cells** | **Used sites: `2,837` / `3,575` (`79.36%`: Lowest utilization!)** |
| | Sequential Cells (FFs) | `41` FFs | **`MUXDFFRB`: 26 (All 4 bits of `reg_buf[3:0]` folded!)**, `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | `45` cells | `BUF_X2`: 10 clk + 10 rst + 25 high-FO |
| | Combinational Logic Cells | `520` cells | `-2` cells vs Trial 04 (removed `NOR2 _1005_` + folded `MUX2 _1012_`) |
| | Memory Macro | `1` macro | `SRAM128` at `(340.2 µm, 1614.6 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `44` cells | 4 columns × 11 rows |
| | Decap Filler Cells | **`254` cells** | `FILL3`: 230 (`690` sites), `FILL2`: 24 (`48` sites), `FILL1`: 0 (**Total `738` sites: Max!**) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,946` MOSFETs | `PMOS`: 3,279, `NMOS`: 3,507, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,686` MOSFETs | `PMOS`: 3,149, `NMOS`: 3,507, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `6,402` MOSFETs | `PMOS`: 3,007, `NMOS`: 3,395 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `665` / `10` | All nets meet `FO <= 10` |
| | OpenROAD Total Wirelength | **`446,626 µm`** | `METAL1`: `222,628 µm` (`49.85%`), `METAL2`: `223,997 µm` (`50.15%`) (`-2,245 µm` vs Trial 04) |
| | Signal Vias (`V1`) | `2,906` vias | OpenROAD Detailed Routing: `0` DRC violations |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_05`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.55 ns` | `35.83 ns` | `47.77 ns` | `41.69 ns` | `0.320 mA` | `1.602 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.84 ns` | `47.78 ns` | `41.69 ns` | `0.617 mA` | `3.083 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.55 ns` | `35.84 ns` | `47.77 ns` | `41.68 ns` | `1.205 mA` | `6.027 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.85 ns` | `47.76 ns` | `41.67 ns` | `1.792 mA` | `8.959 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.57 ns` | `35.85 ns` | `47.74 ns` | `41.67 ns` | `2.379 mA` | `11.897 mW` |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.83 ns` | `47.72 ns` | `41.66 ns` | `2.969 mA` | `14.846 mW` |
| **`12.0 MHz`** | `83.3 ns` | **PASS** | `0x006` | **`0xA`** | `35.44 ns` | `35.72 ns` | `47.58 ns` | `41.55 ns` | `3.548 mA` | `17.738 mW` |
| **`14.0 MHz`** | `71.4 ns` | **PASS** | `0x006` | **`0xA`** | `35.36 ns` | `35.65 ns` | `47.54 ns` | `41.46 ns` | `4.127 mA` | `20.637 mW` |
| **`15.0 MHz`** | `66.7 ns` | **PASS** | `0x006` | **`0xA`** | `35.33 ns` | `35.63 ns` | `47.49 ns` | `41.44 ns` | `4.420 mA` | `22.100 mW` |
| **`16.0 MHz`** | `62.5 ns` | **PASS** | `0x006` | **`0xA`** | `35.31 ns` | `35.59 ns` | `47.44 ns` | `41.42 ns` | `4.712 mA` | `23.561 mW` |
| **`16.5 MHz`** | `60.6 ns` | **PASS** | `0x006` | **`0xA`** | `35.29 ns` | `35.58 ns` | `47.42 ns` | `41.40 ns` | `4.860 mA` | `24.301 mW` |
| **`17.0 MHz`** | `58.8 ns` | **PASS (`FMAX`!)** | `0x006` | **`0xA`** | `35.29 ns` | `35.57 ns` | `47.40 ns` | `41.39 ns` | `5.009 mA` | `25.045 mW` |
| `17.5 MHz` | `57.1 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `35.27 ns` | `35.56 ns` | `47.39 ns` | `41.38 ns` | `5.039 mA` | `25.197 mW` |
| `18.0 MHz` | `55.6 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `35.26 ns` | `35.55 ns` | `47.39 ns` | `41.37 ns` | `5.183 mA` | `25.913 mW` |
| `18.5 MHz` | `54.1 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `35.26 ns` | `35.54 ns` | `47.38 ns` | `41.36 ns` | `5.326 mA` | `26.628 mW` |
| `19.0 MHz` | `52.6 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `35.25 ns` | `35.52 ns` | `47.37 ns` | `41.36 ns` | `5.468 mA` | `27.342 mW` |
| `20.0 MHz` | `50.0 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `35.23 ns` | `35.51 ns` | `47.36 ns` | `41.34 ns` | `5.756 mA` | `28.781 mW` |

---

## Trial 06: `TR-1um_C4004_06`

### 1. Architecture & Floorplan Highlights
- **Dedicated High-Drive `BUF_X2` Output Drivers (`u_buf_dhiz`, `u_buf_doe`) & Pad-Adjacent Anchoring**: Inserted dedicated `BUF_X2` buffers on `d_hiz` and `d_oe`, anchoring `u_buf_dhiz` at Row 2 West `(64.8 µm, 318.6 µm)` adjacent to `D[3:0]` pads `P6..P3` and `u_buf_doe` at Row 0 South `(1026.0 µm, 27.0 µm)` adjacent to `P9 (d_oe)`. This reduced **`t_pd(d_oe)` by `-2.54 ns` (`47.40 ns -> 44.86 ns`)** and **`t_pd(D[3:0])` by `-0.54 ns` (`41.39 ns -> 40.85 ns`)**, enabling external PC/bus operation (`M1`/`M2` fetches) up to **`22.0 MHz`** and isolating the `17.5 MHz` bottleneck to the `X1` half-cycle `SRAM128` read path (`sram_ce -> sram_do[3:0] -> reg_buf[3:0]`).
- **East-Shifted `SRAM128` on 11-Row Floorplan**: Shifted `SRAM128` 1 site (`+5.4 µm`) East to `(345.6 µm, 1614.6 µm)` above 11 rows (`row_pitch = 145.8 µm`), achieving `0` DRC violations, LVS `Match`, and **`FMAX = 17.0 MHz` (`2.125 MIPS`)**.

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_06`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | **`615` cells** | Used sites: `2,843` / `3,575` (`79.52%`) |
| | Sequential Cells (FFs) | `41` FFs | `MUXDFFRB`: 26, `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO / Output Buffers | `47` cells | `BUF_X2`: 10 clk + 10 rst + 25 high-FO + 2 output (`u_buf_dhiz`, `u_buf_doe`) |
| | Combinational Logic Cells | `520` cells | 4-bit symmetric `NAND3 + MUXDFFRB` `reg_buf[3:0]` |
| | Memory Macro | `1` macro | `SRAM128` at `(345.6 µm, 1614.6 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `44` cells | 4 columns × 11 rows |
| | Decap Filler Cells | `253` cells | `FILL3`: 226 (`678` sites), `FILL2`: 27 (`54` sites), `FILL1`: 0 (Total `732` sites) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,952` MOSFETs | `PMOS`: 3,282, `NMOS`: 3,510, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,692` MOSFETs | `PMOS`: 3,152, `NMOS`: 3,510, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `6,408` MOSFETs | `PMOS`: 3,010, `NMOS`: 3,398 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `667` / `10` | All nets meet `FO <= 10` |
| | OpenROAD Total Wirelength | `448,037 µm` | `METAL1`: `224,286 µm` (`50.06%`), `METAL2`: `223,750 µm` (`49.94%`) |
| | Signal Vias (`V1`) | `2,939` vias | OpenROAD Detailed Routing: `0` DRC violations |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_06`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.55 ns` | `35.83 ns` | **`45.22 ns`** | **`41.14 ns`** | `0.323 mA` | `1.613 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.84 ns` | **`45.22 ns`** | **`41.14 ns`** | `0.620 mA` | `3.102 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.85 ns` | **`45.20 ns`** | **`41.13 ns`** | `1.213 mA` | `6.065 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.85 ns` | **`45.19 ns`** | **`41.12 ns`** | `1.803 mA` | `9.015 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.84 ns` | **`45.19 ns`** | **`41.12 ns`** | `2.395 mA` | `11.973 mW` |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.56 ns` | `35.84 ns` | **`45.17 ns`** | **`41.13 ns`** | `2.988 mA` | `14.942 mW` |
| **`12.0 MHz`** | `83.3 ns` | **PASS** | `0x006` | **`0xA`** | `35.44 ns` | `35.73 ns` | **`45.03 ns`** | **`41.01 ns`** | `3.571 mA` | `17.857 mW` |
| **`14.0 MHz`** | `71.4 ns` | **PASS** | `0x006` | **`0xA`** | `35.36 ns` | `35.64 ns` | **`44.96 ns`** | **`40.93 ns`** | `4.155 mA` | `20.775 mW` |
| **`15.0 MHz`** | `66.7 ns` | **PASS** | `0x006` | **`0xA`** | `35.33 ns` | `35.63 ns` | **`44.94 ns`** | **`40.90 ns`** | `4.449 mA` | `22.247 mW` |
| **`16.0 MHz`** | `62.5 ns` | **PASS** | `0x006` | **`0xA`** | `35.32 ns` | `35.60 ns` | **`44.91 ns`** | **`40.88 ns`** | `4.744 mA` | `23.718 mW` |
| **`16.5 MHz`** | `60.6 ns` | **PASS** | `0x006` | **`0xA`** | `35.30 ns` | `35.58 ns` | **`44.87 ns`** | **`40.87 ns`** | `4.893 mA` | `24.463 mW` |
| **`17.0 MHz`** | `58.8 ns` | **PASS (`FMAX`!)** | `0x006` | **`0xA`** | `35.29 ns` | `35.57 ns` | **`44.86 ns`** | **`40.85 ns`** | `5.042 mA` | `25.208 mW` |
| `17.5 MHz` | `57.1 ns` | FAIL (`X1` `sram_do`) | `0x006` (PASS) | `0x0` | `35.27 ns` | `35.56 ns` | `44.85 ns` | `40.84 ns` | `5.076 mA` | `25.381 mW` |
| `18.0 MHz` | `55.6 ns` | FAIL (`X1` `sram_do`) | `0x006` (PASS) | `0x0` | `35.26 ns` | `35.55 ns` | `44.84 ns` | `40.84 ns` | `5.220 mA` | `26.100 mW` |
| `19.0 MHz` | `52.6 ns` | FAIL (`X1` `sram_do`) | `0x006` (PASS) | `0x0` | `35.25 ns` | `35.54 ns` | `44.82 ns` | `40.81 ns` | `5.507 mA` | `27.537 mW` |
| `20.0 MHz` | `50.0 ns` | FAIL (`X1` `sram_do`) | `0x006` (PASS) | `0x0` | `35.23 ns` | `35.51 ns` | `44.80 ns` | `40.78 ns` | `5.798 mA` | `28.988 mW` |
| `22.0 MHz` | `45.5 ns` | FAIL (`X1` `sram_do`) | `0x006` (PASS!) | `0x0` | `35.18 ns` | `35.47 ns` | `44.77 ns` | `40.76 ns` | `6.521 mA` | `32.604 mW` |

---

## Trial 07: `TR-1um_C4004_07`

### 1. Architecture & Floorplan Highlights
- **`OR3 + INV_X1` Two-Stage `sram_ce` Driver Investigation**: Replaced the single `NOR3` (`_1102_`) driving `sram_ce` with an `OR3` (`_1102_`) followed by an `INV_X1` (`u_inv_sram_ce`) anchored at Row 10 East `(1495.0 µm, 1485.0 µm)` directly beneath `SRAM128.CE`. Post-layout `ngspice` verification achieved `FMAX = 16.0 MHz`, demonstrating that the extra 2 internal inverter stages inside `OR3 + INV_X1` (`NOR3 + INV + INV` = 3 stages vs 1 stage for `NOR3`) added ~3.5 ns of gate delay that outweighed the improved rising slew rate (informing Trial 08's direct single-stage `NOR3` anchoring).
- **South-Shifted `SRAM128` at `(340.2 µm, 1609.2 µm)` Achieving Best 41-FF Pad Delays**: Shifting `SRAM128` 1 track (`-5.4 µm`) South to `Y = 1609.2 µm` opened additional routing space near the North pads (`sync`, `cm_rom`) and achieved the **shortest pad propagation delays across all 41-FF trials (`t_pd(sync) = 34.78 ns`, `t_pd(cm_rom) = 35.09 ns`, `t_pd(d_oe) = 44.39 ns`, `t_pd(D[3:0]) = 40.37 ns`)**.

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_07`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | **`616` cells** | Used sites: `2,846` / `3,575` (`79.61%`) |
| | Sequential Cells (FFs) | `41` FFs | `MUXDFFRB`: 26, `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO / Output Buffers | `47` cells | `BUF_X2`: 10 clk + 10 rst + 25 high-FO + 2 output (`u_buf_dhiz`, `u_buf_doe`) |
| | Combinational Logic Cells | `521` cells | 4-bit symmetric `reg_buf[3:0]` + `OR3 + INV_X1 (u_inv_sram_ce)` |
| | Memory Macro | `1` macro | `SRAM128` at `(340.2 µm, 1609.2 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `44` cells | 4 columns × 11 rows |
| | Decap Filler Cells | `255` cells | `FILL3`: 219 (`657` sites), `FILL2`: 36 (`72` sites), `FILL1`: 0 (Total `729` sites) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,960` MOSFETs | `PMOS`: 3,286, `NMOS`: 3,514, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,700` MOSFETs | `PMOS`: 3,156, `NMOS`: 3,514, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `6,416` MOSFETs | `PMOS`: 3,014, `NMOS`: 3,402 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `668` / `10` | All nets meet `FO <= 10` |
| | OpenROAD Total Wirelength | `456,846 µm` | `METAL1`: `225,921 µm` (`49.45%`), `METAL2`: `230,924 µm` (`50.55%`) |
| | Signal Vias (`V1`) | `2,910` vias | OpenROAD Detailed Routing: `0` DRC violations |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_07`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | **`35.00 ns`** | **`35.33 ns`** | **`44.73 ns`** | **`40.64 ns`** | `0.322 mA` | `1.609 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | **`35.03 ns`** | **`35.33 ns`** | **`44.70 ns`** | **`40.64 ns`** | `0.620 mA` | `3.100 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | **`35.02 ns`** | **`35.34 ns`** | **`44.68 ns`** | **`40.63 ns`** | `1.211 mA` | `6.057 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | **`35.02 ns`** | **`35.33 ns`** | **`44.67 ns`** | **`40.62 ns`** | `1.800 mA` | `9.000 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | **`35.03 ns`** | **`35.33 ns`** | **`44.68 ns`** | **`40.63 ns`** | `2.390 mA` | `11.952 mW` |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | **`35.03 ns`** | **`35.33 ns`** | **`44.66 ns`** | **`40.62 ns`** | `2.982 mA` | `14.912 mW` |
| **`12.0 MHz`** | `83.3 ns` | **PASS** | `0x006` | **`0xA`** | **`34.92 ns`** | **`35.22 ns`** | **`44.54 ns`** | **`40.51 ns`** | `3.564 mA` | `17.821 mW` |
| **`14.0 MHz`** | `71.4 ns` | **PASS** | `0x006` | **`0xA`** | **`34.83 ns`** | **`35.14 ns`** | **`44.45 ns`** | **`40.42 ns`** | `4.147 mA` | `20.733 mW` |
| **`15.0 MHz`** | `66.7 ns` | **PASS** | `0x006` | **`0xA`** | **`34.82 ns`** | **`35.12 ns`** | **`44.43 ns`** | **`40.39 ns`** | `4.440 mA` | `22.201 mW` |
| **`16.0 MHz`** | `62.5 ns` | **PASS (`FMAX`)** | `0x006` | **`0xA`** | **`34.78 ns`** | **`35.09 ns`** | **`44.39 ns`** | **`40.37 ns`** | `4.732 mA` | `23.658 mW` |
| `16.5 MHz` | `60.6 ns` | FAIL (`OR3+INV` 2-stage) | `0x006` (PASS) | `0x0` | `34.76 ns` | `35.07 ns` | `44.37 ns` | `40.36 ns` | `4.774 mA` | `23.871 mW` |
| `17.0 MHz` | `58.8 ns` | FAIL (`OR3+INV` 2-stage) | `0x006` (PASS) | `0x0` | `34.76 ns` | `35.06 ns` | `44.34 ns` | `40.35 ns` | `4.919 mA` | `24.593 mW` |
| `18.0 MHz` | `55.6 ns` | FAIL (`OR3+INV` 2-stage) | `0x006` (PASS) | `0x0` | `34.73 ns` | `35.04 ns` | `44.34 ns` | `40.32 ns` | `5.208 mA` | `26.039 mW` |
| `20.0 MHz` | `50.0 ns` | FAIL (`OR3+INV` 2-stage) | `0x006` (PASS) | `0x9` | `34.70 ns` | `35.00 ns` | `44.29 ns` | `40.28 ns` | `5.958 mA` | `29.792 mW` |
| `22.0 MHz` | `45.5 ns` | FAIL (`OR3+INV` 2-stage) | `0x006` (PASS!) | `0x9` | `34.66 ns` | `34.97 ns` | `44.26 ns` | `40.25 ns` | `6.542 mA` | `32.712 mW` |

---

## Trial 08: `TR-1um_C4004_08` (Direct `clk_in_th -> NOR3 _1102_` `sram_ce` Driver + 9-Branch Clock/Reset Tree — New Record `18.5 MHz`!)

### 1. Architecture, Gate-Level & Floorplan Highlights
- **Direct `clk_in_th` Single-Stage `NOR3` `sram_ce` Driver + 9-Branch Clock/Reset Tree**:
  - Kept `_1102_` (`sram_ce` driver) as a single-stage `NOR3` gate, connected its `.B` input (`clk`) **directly to `clk_in_th`** (bypassing the 2-stage leaf clock buffer to save `~3.0 ns` on the mid-cycle falling clock edge!), and anchored `_1102_` at Row 10 East `(X = 1495.0 µm, Y = 1485.0 µm)` directly beneath `SRAM128.CE`.
  - Consolidated the row-based clock/reset tree from 10 to **9 leaf `BUF_X2` branches** (`u_clk_buf_r1..r9` and `u_rst_buf_r1..r9`, with Rows 7+8 sharing `r8` (`8 <= 10` FFs) and Rows 9+10 sharing `r9` (`6 <= 10` FFs)), keeping `FO(clk_in_th) = 9 + 1 = 10 <= 10` and `FO(rst_n) = 9 <= 10` while removing 2 `BUF_X2` buffers (`-10` sites), reducing logic standard cells to **`613` (`2,837` sites = `79.36%` utilization, `738` decap filler sites)**.
- **11-Row Floorplan & `SRAM128` Placement**:
  - `SRAM128` placed at **`(340.2 µm, 1614.6 µm)`** above 11 standard-cell rows (`row_pitch = 145.8 µm` = 27 tracks, channel height = `86.4 µm` = 16 tracks).
  - Converged in 14 TritonRoute iterations (`107.58 s`) with **0 DRC violations**, achieving the **shortest wirelength (`438,162 µm`: `-9,875 µm` vs Trial 06) and lowest via count (`2,844` vias: `-95` vias vs Trial 06) of any 41-FF trial**, and set a **new all-time record `FMAX = 18.5 MHz` (`2.313 MIPS`, `+131.3%` vs Trial 01)**!

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_08`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | `613` cells | Used sites: `2,837` / `3,575` (**`79.36%`: Lowest utilization tied!**) |
| | Sequential Cells (FFs) | `41` FFs | `MUXDFFRB`: 26 (All 4 bits of `reg_buf[3:0]` folded), `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | `45` cells | `BUF_X2`: 9 clk + 9 rst + 25 high-FO + 2 `u_buf_dhiz`/`u_buf_doe` |
| | Combinational Logic Cells | `520` cells | Direct `clk_in_th -> NOR3 _1102_` (`sram_ce`) anchored at Row 10 East |
| | Memory Macro | `1` macro | `SRAM128` at `(340.2 µm, 1614.6 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `44` cells | 4 columns × 11 rows |
| | Decap Filler Cells | `258` cells | `FILL3`: 222 (`666` sites), `FILL2`: 36 (`72` sites), `FILL1`: 0 (**Total `738` sites: Max tied!**) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,954` MOSFETs | `PMOS`: 3,283, `NMOS`: 3,511, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,694` MOSFETs | `PMOS`: 3,153, `NMOS`: 3,511, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `6,410` MOSFETs | `PMOS`: 3,011, `NMOS`: 3,399 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `665` / `10` | All nets meet `FO <= 10` (`FO(clk_in_th) = 10`) |
| | OpenROAD Total Wirelength | **`438,162 µm`** | `METAL1`: `217,831 µm` (`49.71%`), `METAL2`: `220,331 µm` (`50.29%`) (**Best 41-FF WL!**) |
| | Signal Vias (`V1`) | **`2,844` vias** | Converged in 14 iterations (`107.58 s`) with `0` DRC violations (**Lowest 41-FF vias!**) |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_08`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.01 ns` | `35.30 ns` | `44.68 ns` | `40.60 ns` | `0.318 mA` | **`1.588 mW` (Best 41-FF!)** |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.01 ns` | `35.30 ns` | `44.66 ns` | `40.60 ns` | `0.611 mA` | `3.056 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.00 ns` | `35.30 ns` | `44.65 ns` | `40.59 ns` | `1.195 mA` | `5.974 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `35.02 ns` | `35.29 ns` | `44.63 ns` | `40.59 ns` | `1.775 mA` | `8.877 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.02 ns` | `35.31 ns` | `44.64 ns` | `40.58 ns` | `2.357 mA` | **`11.783 mW` (`-5.80%` vs Trial 01)** |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | `35.00 ns` | `35.31 ns` | `44.62 ns` | `40.58 ns` | `2.941 mA` | `14.704 mW` |
| **`12.0 MHz`** | `83.3 ns` | **PASS** | `0x006` | **`0xA`** | `34.89 ns` | `35.18 ns` | `44.50 ns` | `40.47 ns` | `3.514 mA` | `17.572 mW` |
| **`14.0 MHz`** | `71.4 ns` | **PASS** | `0x006` | **`0xA`** | `34.82 ns` | `35.10 ns` | `44.42 ns` | `40.39 ns` | `4.088 mA` | `20.441 mW` |
| **`15.0 MHz`** | `66.7 ns` | **PASS** | `0x006` | **`0xA`** | `34.80 ns` | `35.07 ns` | `44.40 ns` | `40.36 ns` | `4.378 mA` | `21.889 mW` |
| **`16.0 MHz`** | `62.5 ns` | **PASS** | `0x006` | **`0xA`** | `34.76 ns` | `35.05 ns` | `44.36 ns` | `40.34 ns` | `4.666 mA` | `23.328 mW` |
| **`16.5 MHz`** | `60.6 ns` | **PASS** | `0x006` | **`0xA`** | `34.76 ns` | `35.04 ns` | `44.34 ns` | `40.32 ns` | `4.811 mA` | `24.056 mW` |
| **`17.0 MHz`** | `58.8 ns` | **PASS** | `0x006` | **`0xA`** | `34.74 ns` | `35.03 ns` | `44.32 ns` | `40.31 ns` | `4.958 mA` | `24.789 mW` |
| **`17.5 MHz`** | `57.1 ns` | **PASS** | `0x006` | **`0xA`** | `34.73 ns` | `35.02 ns` | `44.31 ns` | `40.30 ns` | `5.105 mA` | `25.524 mW` |
| **`18.0 MHz`** | `55.6 ns` | **PASS** | `0x006` | **`0xA`** | `34.71 ns` | `35.01 ns` | `44.30 ns` | `40.29 ns` | `5.251 mA` | `26.255 mW` |
| **`18.5 MHz`** | `54.1 ns` | **PASS (`FMAX` New Record!!)** | **`0x006`** | **`0xA`** | **`34.71 ns`** | **`35.00 ns`** | **`44.29 ns`** | **`40.28 ns`** | `5.399 mA` | **`26.995 mW`** |
| `19.0 MHz` | `52.6 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.70 ns` | `34.99 ns` | `44.27 ns` | `40.27 ns` | `5.422 mA` | `27.109 mW` |
| `19.5 MHz` | `51.3 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.69 ns` | `34.98 ns` | `44.26 ns` | `40.25 ns` | `5.562 mA` | `27.810 mW` |
| `20.0 MHz` | `50.0 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.69 ns` | `34.96 ns` | `44.25 ns` | `40.25 ns` | `5.704 mA` | `28.518 mW` |
| `21.0 MHz` | `47.6 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.67 ns` | `34.96 ns` | `44.24 ns` | `40.23 ns` | `5.986 mA` | `29.928 mW` |
| `22.0 MHz` | `45.5 ns` | FAIL (`M1` Bus) | **`0x006` (PASS!)** | `0x0` | `34.64 ns` | `34.93 ns` | `44.23 ns` | `40.22 ns` | `6.266 mA` | `31.331 mW` |

---

## Trial 09: `TR-1um_C4004_09` (8-Branch Low-Capacitance Clock/Reset Tree + South `_1072_` Anchor + West-Shifted `SRAM128` — Record `18.5 MHz` + Best 41-FF Wirelength & Power!)

### 1. Architecture, Gate-Level & Floorplan Highlights
- **8-Branch Low-Capacitance Clock/Reset Tree (`FO(clk_in_th) = 9`, `FO(rst_n) = 8`) + South `_1072_` Anchor**:
  - Consolidated the row-based clock/reset tree further from 9 to **8 leaf `BUF_X2` branches** (`u_clk_buf_r1..r8` and `u_rst_buf_r1..r8`, with Rows 0+1 sharing `r1` (`7 <= 10` FFs), Rows 7+8 sharing `r7` (`8 <= 10` FFs), and Rows 9+10 sharing `r8` (`6 <= 10` FFs)), reducing `FO(clk_in_th)` to `8 + 1 = 9 <= 10` and `FO(rst_n)` to `8 <= 10`.
  - Removed 2 more `BUF_X2` cells (`-10` sites), achieving the **all-time lowest cell utilization (`79.19%`: `2,831` sites across `611` stdcells)** and **all-time highest decap filler capacity (`744` sites: `232 FILL3 + 24 FILL2 = 256` fillers, `0` `FILL1`)**.
  - Anchored `_1072_` (`INV_X1` driving `d_oe_pre`) at Row 0 South `(1093.5 µm, 27.0 µm)` immediately adjacent to `u_buf_doe` `(1098.9 µm, 27.0 µm)`, while keeping `_1102_` (`NOR3` driving `sram_ce` directly from `clk_in_th`) anchored at Row 10 East `(1495.0 µm, 1485.0 µm)`.
- **11-Row Floorplan & West-Shifted `SRAM128` Placement `(334.8 µm, 1614.6 µm)`**:
  - Shifted `SRAM128` 1 site (`-5.4 µm`) West to **`(X = 334.8 µm, Y = 1614.6 µm)`** above 11 standard-cell rows (`row_pitch = 145.8 µm` = 27 tracks, channel height = `86.4 µm` = 16 tracks).
  - Converged in `117.16 s` with **0 DRC violations**, achieving the **shortest wirelength (`430,680 µm`: `-7,482 µm` vs Trial 08, `-17,357 µm` vs Trial 06, even shorter than 37-FF Trials 01 & 03!)**, **lowest via count (`2,717` vias: `-127` vs Trial 08, `-222` vs Trial 06, even fewer than 37-FF Trial 01!)**, **lowest power (`1.570 mW @ 1 MHz`)**, and **shortest pad delays (`t_pd(D[3:0]) = 39.96 ns < 40 ns`)** of any 41-FF trial while matching the **`FMAX = 18.5 MHz` (`2.313 MIPS`)** record and passing external `M1` bus turnaround even at `19.0 MHz`!

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_09`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | **`611` cells** | Used sites: `2,831` / `3,575` (**`79.19%`: All-time lowest utilization!**) |
| | Sequential Cells (FFs) | `41` FFs | `MUXDFFRB`: 26 (All 4 bits of `reg_buf[3:0]` folded), `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | **`43` cells** | `BUF_X2`: 8 clk + 8 rst + 25 high-FO + 2 `u_buf_dhiz`/`u_buf_doe` (`-2` cells!) |
| | Combinational Logic Cells | `520` cells | Direct `clk_in_th -> NOR3 _1102_` + South `_1072_` anchored beside `u_buf_doe` |
| | Memory Macro | `1` macro | `SRAM128` at `(334.8 µm, 1614.6 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `44` cells | 4 columns × 11 rows |
| | Decap Filler Cells | **`256` cells** | `FILL3`: 232 (`696` sites), `FILL2`: 24 (`48` sites), `FILL1`: 0 (**Total `744` sites: All-time max!**) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | **`6,942` MOSFETs** | `PMOS`: 3,277, `NMOS`: 3,505, `NMOSE`: 160 (+`28` Diodes, **Lowest 41-FF!**) |
| | Full-Chip MOSFETs (Combined) | **`6,682` MOSFETs** | `PMOS`: 3,147, `NMOS`: 3,505, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | **`6,398` MOSFETs** | `PMOS`: 3,005, `NMOS`: 3,393 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `663` / `10` | All nets meet `FO <= 10` (`FO(clk_in_th) = 9`, `FO(rst_n) = 8`) |
| | OpenROAD Total Wirelength | **`430,680 µm`** | `METAL1`: `216,368 µm` (`50.24%`), `METAL2`: `214,312 µm` (`49.76%`) (**Shortest 41-FF WL! `-7,482 µm` vs Trial 08!**) |
| | Signal Vias (`V1`) | **`2,717` vias** | Converged in `117.16 s` with `0` DRC violations (**Lowest 41-FF vias! `-127` vs Trial 08!**) |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_09`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.66 ns` | `34.99 ns` | `44.35 ns` | `40.28 ns` | `0.314 mA` | **`1.570 mW` (Best 41-FF!)** |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.66 ns` | `34.99 ns` | `44.34 ns` | `40.28 ns` | `0.603 mA` | `3.017 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.67 ns` | `34.98 ns` | `44.32 ns` | `40.26 ns` | `1.180 mA` | `5.900 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `34.67 ns` | `34.99 ns` | `44.32 ns` | `40.27 ns` | `1.753 mA` | `8.764 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.68 ns` | `34.99 ns` | `44.32 ns` | `40.28 ns` | `2.326 mA` | **`11.630 mW` (`-7.03%` vs Trial 01)** |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.68 ns` | `34.99 ns` | `44.33 ns` | `40.27 ns` | `2.902 mA` | `14.512 mW` |
| **`12.0 MHz`** | `83.3 ns` | **PASS** | `0x006` | **`0xA`** | `34.56 ns` | `34.88 ns` | `44.18 ns` | `40.15 ns` | `3.469 mA` | `17.343 mW` |
| **`14.0 MHz`** | `71.4 ns` | **PASS** | `0x006` | **`0xA`** | `34.48 ns` | `34.80 ns` | `44.11 ns` | `40.07 ns` | `4.035 mA` | `20.176 mW` |
| **`15.0 MHz`** | `66.7 ns` | **PASS** | `0x006` | **`0xA`** | `34.46 ns` | `34.77 ns` | `44.06 ns` | `40.04 ns` | `4.319 mA` | `21.596 mW` |
| **`16.0 MHz`** | `62.5 ns` | **PASS** | `0x006` | **`0xA`** | `34.43 ns` | `34.74 ns` | `44.04 ns` | `40.02 ns` | `4.605 mA` | `23.024 mW` |
| **`16.5 MHz`** | `60.6 ns` | **PASS** | `0x006` | **`0xA`** | `34.41 ns` | `34.72 ns` | `44.02 ns` | `40.00 ns` | `4.748 mA` | `23.739 mW` |
| **`17.0 MHz`** | `58.8 ns` | **PASS** | `0x006` | **`0xA`** | `34.40 ns` | `34.72 ns` | `43.99 ns` | **`39.98 ns`** | `4.894 mA` | `24.468 mW` |
| **`17.5 MHz`** | `57.1 ns` | **PASS** | `0x006` | **`0xA`** | `34.39 ns` | `34.70 ns` | `43.98 ns` | `39.98 ns` | `5.039 mA` | `25.193 mW` |
| **`18.0 MHz`** | `55.6 ns` | **PASS** | `0x006` | **`0xA`** | `34.38 ns` | `34.70 ns` | `43.98 ns` | `39.97 ns` | `5.183 mA` | `25.913 mW` |
| **`18.5 MHz`** | `54.1 ns` | **PASS (`FMAX` Record Tied!!)** | **`0x006`** | **`0xA`** | **`34.37 ns`** | **`34.69 ns`** | **`43.95 ns`** | **`39.96 ns`** | `5.328 mA` | **`26.641 mW`** |
| `19.0 MHz` | `52.6 ns` | FAIL (`X1` `reg_buf` / Bus PASS!) | `0x006` (PASS) | `0xC` (M1 PASS!) | `34.37 ns` | `34.68 ns` | `43.95 ns` | `39.95 ns` | `5.458 mA` | `27.292 mW` |
| `19.5 MHz` | `51.3 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.35 ns` | `34.66 ns` | `43.93 ns` | `39.93 ns` | `5.488 mA` | `27.439 mW` |
| `20.0 MHz` | `50.0 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.35 ns` | `34.65 ns` | `43.92 ns` | `39.93 ns` | `5.627 mA` | `28.135 mW` |
| `21.0 MHz` | `47.6 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.33 ns` | `34.64 ns` | `43.92 ns` | `39.91 ns` | `5.906 mA` | `29.531 mW` |
| `22.0 MHz` | `45.5 ns` | FAIL (`M1` Bus) | **`0x006` (PASS!)** | `0x0` | `34.31 ns` | `34.63 ns` | `43.90 ns` | `39.90 ns` | `6.183 mA` | `30.915 mW` |

---

## Trial 10: `TR-1um_C4004_10` (Final Trial — All-Time Record `19.0 MHz` / `2.375 MIPS`!!)

### 1. Architecture, Gate-Level & Floorplan Highlights
- **Root-Cause Analysis of Trial 09 at `19.0 MHz` & Half-Cycle `X1` Pre-Read Pipeline Co-Location in Row 8**:
  - In Trial 09 at `19.0 MHz` (`T_clk = 52.63 ns`, half-cycle `26.32 ns`), external `M1` bus turnaround succeeded, but `final_acc` was `0xC` (`12`) instead of `0xA` (`10`) because RePlAce placed `reg_buf[3:0]` (`_1143_.._1146_`) in Rows 1–2 (`Y = 172.8..318.6 µm`, `1,440 µm` away from `SRAM128` at `Y = 1614.6 µm`), weighting the half-cycle `X1` pre-read path (`SRAM128.DO[3:0] -> NAND2 -> NAND3 -> reg_buf[3:0]`) equally with the full-cycle `X2` ALU path (`reg_buf[3:0] -> CLA -> ACC`).
  - In Trial 10, all 12 cells of the half-cycle `X1` pre-read pipeline (`reg_buf[3:0]` `MUXDFFRB` cells `_1143_.._1146_` and their driving `NAND2` `_0821_/_0828_/_0834_/_1009_` and `NAND3` `_0824_/_0830_/_0836_/_1011_` gates) are **co-located in Row 8 (`Y = 1193.4 µm, X = 480.0..656.0 µm`) directly beneath `SRAM128.DO[3:0]`**, cutting the half-cycle interconnect distance by more than 3× (`1,440 µm -> < 450 µm`)!
- **Cascaded `NOR4 _1071_ -> BUF_X2 u_buf_dhiz -> INV_X1 _1072_ -> BUF_X2 u_buf_doe` (`FO(d_hiz_pre) = 1`)**:
  - Reconnected `_1072_.A` (`INV_X1` driving `d_oe_pre`) to the buffered `d_hiz` output of `u_buf_dhiz` (`BUF_X2`) instead of `d_hiz_pre`, and co-located `_1071_` (`NOR4`) at Row 2 West `(55.8 µm, 318.6 µm)` immediately adjacent to `u_buf_dhiz` `(45.0 µm, 318.6 µm)`, turning `d_hiz_pre` into a `< 20 µm` single-sink (`FO = 1`) local net.
- **Horizontally Centered `SRAM128` `(340.2 µm, 1614.6 µm)` on 11-Row Floorplan**:
  - Placed `SRAM128` at `(340.2 µm, 1614.6 µm)` above 11 standard-cell rows (`row_pitch = 145.8 µm` = 27 tracks, channel = `86.4 µm` = 16 tracks), maintaining the **all-time lowest cell utilization (`79.19%`: `2,831 / 3,575` sites, `611` stdcells)** and **all-time highest decap filler capacity (`744` sites: `228 FILL3 + 30 FILL2 = 258` fillers, `0` `FILL1`)**, converging with **0 DRC violations**, exact LVS `Match` (`deep` & `flat`), and achieving the **all-time fastest clock frequency `FMAX = 19.0 MHz` (`2.375 MIPS`, `+137.5%` vs Trial 01, `25.7×` original Intel 4004 `740 kHz`)** and **shortest 41-FF `D[3:0]` pad delay (`39.81 ns`)**!

### 2. Cell, Device & Routing Statistics (`TR-1um_C4004_10`)

| Category | Metric / Item | Value | Notes / Details |
| :--- | :--- | :---: | :--- |
| **Cell & Site Stats** | Logic Standard Cells | **`611` cells** | Used sites: `2,831` / `3,575` (**`79.19%`: All-time lowest utilization tied!**) |
| | Sequential Cells (FFs) | `41` FFs | `MUXDFFRB`: 26 (All 4 bits of `reg_buf[3:0]` folded), `DFFRB`: 15 |
| | Input Schmitt Buffers | `7` cells | `BUFTH`: 7 (`clk, rst, test, d_in[3:0]`) |
| | Clock / Reset / High-FO Buffers | **`43` cells** | `BUF_X2`: 8 clk + 8 rst + 25 high-FO + 2 `u_buf_dhiz`/`u_buf_doe` |
| | Combinational Logic Cells | `520` cells | Cascaded `d_hiz`/`d_oe` (`FO(d_hiz_pre)=1`) + Row-8 co-located `X1` `reg_buf` |
| | Memory Macro | `1` macro | `SRAM128` at `(340.2 µm, 1614.6 µm)`, `1,212` MOSFETs |
| | Substrate Tap Cells (`TAP2`) | `44` cells | 4 columns × 11 rows |
| | Decap Filler Cells | **`258` cells** | `FILL3`: 228 (`684` sites), `FILL2`: 30 (`60` sites), `FILL1`: 0 (**Total `744` sites: All-time max tied!**) |
| **Extracted Devices** | Full-Chip MOSFETs (Multi-Finger `M=`) | `6,946` MOSFETs | `PMOS`: 3,279, `NMOS`: 3,507, `NMOSE`: 160 (+`28` Diodes) |
| | Full-Chip MOSFETs (Combined) | `6,686` MOSFETs | `PMOS`: 3,149, `NMOS`: 3,507, `NMOSE`: 30 (+`28` Diodes) |
| | Core (`c4004_core`) MOSFETs | `6,402` MOSFETs | `PMOS`: 3,007, `NMOS`: 3,395 (incl. `SRAM128`: `1,212`) |
| **Routing & Signoff** | Signal Nets / Max Fanout | `663` / `10` | All nets meet `FO <= 10` (`FO(clk_in_th) = 9`, `FO(rst_n) = 8`, `FO(d_hiz_pre) = 1`) |
| | OpenROAD Total Wirelength | `450,643 µm` | `METAL1`: `220,437 µm` (`48.92%`), `METAL2`: `230,206 µm` (`51.08%`) |
| | Signal Vias (`V1`) | `2,985` vias | Converged in `148.89 s` with `0` DRC violations |
| | KLayout DRC / LVS | **`0` Errors / `Match`** | Exact match in both `deep` and `flat` modes |

### 3. Post-Layout `ngspice` Frequency Sweep Results (`TR-1um_C4004_10`)

| Clock Freq | Period `T_clk` | Status | `PC` Out (`A1..A3`) | Internal ALU `ACC` (`X2`) | `t_pd(sync)` | `t_pd(cm_rom)` | `t_pd(d_oe)` | `t_pd(D[3:0])` | Avg Current `I_VDD` | Avg Power `P_avg` |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **`1.0 MHz`** | `1000.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.69 ns` | `34.96 ns` | `45.89 ns` | `40.15 ns` | `0.315 mA` | `1.574 mW` |
| **`2.0 MHz`** | `500.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.68 ns` | `34.99 ns` | `45.89 ns` | `40.15 ns` | `0.606 mA` | `3.029 mW` |
| **`4.0 MHz`** | `250.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.69 ns` | `34.98 ns` | `45.87 ns` | `40.15 ns` | `1.185 mA` | `5.925 mW` |
| **`6.0 MHz`** | `166.7 ns` | **PASS** | `0x006` | **`0xA`** | `34.70 ns` | `34.98 ns` | `45.84 ns` | `40.15 ns` | `1.759 mA` | `8.796 mW` |
| **`8.0 MHz`** | `125.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.71 ns` | `34.99 ns` | `45.86 ns` | `40.14 ns` | `2.335 mA` | `11.673 mW` |
| **`10.0 MHz`** | `100.0 ns` | **PASS** | `0x006` | **`0xA`** | `34.70 ns` | `34.99 ns` | `45.86 ns` | `40.12 ns` | `2.913 mA` | `14.567 mW` |
| **`12.0 MHz`** | `83.3 ns` | **PASS** | `0x006` | **`0xA`** | `34.57 ns` | `34.86 ns` | `45.69 ns` | `40.02 ns` | `3.482 mA` | `17.408 mW` |
| **`14.0 MHz`** | `71.4 ns` | **PASS** | `0x006` | **`0xA`** | `34.51 ns` | `34.80 ns` | `45.64 ns` | **`39.93 ns`** | `4.050 mA` | `20.252 mW` |
| **`15.0 MHz`** | `66.7 ns` | **PASS** | `0x006` | **`0xA`** | `34.48 ns` | `34.76 ns` | `45.60 ns` | **`39.90 ns`** | `4.336 mA` | `21.682 mW` |
| **`16.0 MHz`** | `62.5 ns` | **PASS** | `0x006` | **`0xA`** | `34.45 ns` | `34.73 ns` | `45.56 ns` | **`39.87 ns`** | `4.623 mA` | `23.113 mW` |
| **`16.5 MHz`** | `60.6 ns` | **PASS** | `0x006` | **`0xA`** | `34.44 ns` | `34.73 ns` | `45.55 ns` | **`39.86 ns`** | `4.768 mA` | `23.838 mW` |
| **`17.0 MHz`** | `58.8 ns` | **PASS** | `0x006` | **`0xA`** | `34.43 ns` | `34.71 ns` | `45.53 ns` | **`39.85 ns`** | `4.913 mA` | `24.567 mW` |
| **`17.5 MHz`** | `57.1 ns` | **PASS** | `0x006` | **`0xA`** | `34.42 ns` | `34.70 ns` | `45.51 ns` | **`39.85 ns`** | `5.059 mA` | `25.294 mW` |
| **`18.0 MHz`** | `55.6 ns` | **PASS** | `0x006` | **`0xA`** | `34.41 ns` | `34.69 ns` | `45.51 ns` | **`39.84 ns`** | `5.204 mA` | `26.020 mW` |
| **`18.5 MHz`** | `54.1 ns` | **PASS** | `0x006` | **`0xA`** | `34.38 ns` | `34.68 ns` | `45.48 ns` | **`39.82 ns`** | `5.350 mA` | `26.752 mW` |
| **`19.0 MHz`** | `52.6 ns` | **PASS (`FMAX` All-Time Record!!)** | **`0x006`** | **`0xA`** | **`34.37 ns`** | **`34.67 ns`** | `45.47 ns` | **`39.81 ns`** | `5.494 mA` | **`27.469 mW`** |
| `19.5 MHz` | `51.3 ns` | FAIL (`X1` `reg_buf` / Bus PASS!) | `0x006` (PASS) | `0x5` (M1 PASS!) | `34.37 ns` | `34.65 ns` | `45.46 ns` | `39.80 ns` | `5.611 mA` | `28.055 mW` |
| `20.0 MHz` | `50.0 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.37 ns` | `34.64 ns` | `45.45 ns` | `39.79 ns` | `5.653 mA` | `28.265 mW` |
| `21.0 MHz` | `47.6 ns` | FAIL (`M1` Bus) | `0x006` (PASS) | `0x0` | `34.35 ns` | `34.63 ns` | `45.46 ns` | `39.77 ns` | `5.932 mA` | `29.660 mW` |
| `22.0 MHz` | `45.5 ns` | FAIL (`M1` Bus) | **`0x006` (PASS!)** | `0x0` | `34.33 ns` | `34.62 ns` | `45.44 ns` | `39.76 ns` | `6.208 mA` | `31.041 mW` |

---

## Summary of Findings Across All 10 Trials (`TR-1um_C4004_01` – `TR-1um_C4004_10`)

1. **Co-Optimization of RTL Microarchitecture, Gate-Level Drivers & Half-Cycle Physical Placement (`8.0 MHz -> 19.0 MHz`, `+137.5%` / `2.375×` Speedup, `25.7×` Original Intel 4004 `740 kHz`)**:
   - **Trial 01 (`8.0 MHz` / `1.000 MIPS`)**: Baseline 37-FF design with shared ripple-carry adder, limited by half-cycle `negedge clk -> SRAM128` PC read in `A1`.
   - **Trial 02 (`11.0 MHz` / `1.375 MIPS`, `+37.5%`)**: Shadow PC bypass (`pc_init_n`) + explicit 4-bit CLA + 10-row floorplan (`420,271 µm` shortest overall wirelength).
   - **Trial 03 (`8.5 MHz` / Internal ALU `15.0 MHz`)**: Early `X1` index-register pre-read pipeline validated `15.0 MHz` internal ALU operation while achieving the lowest via count (`2,607` vias).
   - **Trial 04 (`16.5 MHz` / `2.063 MIPS`, `+106.3%`)**: Dedicated 4-bit pipeline register `reg_buf[3:0]` (41 FFs) unified Non-Stop Shadow PC with Full-Cycle CLA on an 11-row floorplan.
   - **Trial 05 (`17.0 MHz` / `2.125 MIPS`, `+112.5%`)**: Restructured `reg_buf[3]` into a symmetric `NAND3 + MUXDFFRB` cone (folding all 26 eligible FFs into `MUXDFFRB`).
   - **Trial 06 (`17.0 MHz`, `-2.54 ns` faster `d_oe`, `22.0 MHz` external bus)**: Dedicated `BUF_X2` drivers (`u_buf_dhiz`, `u_buf_doe`) anchored adjacent to West/South pads.
   - **Trial 07 (`16.0 MHz`, improved pad delays)**: Demonstrated that single-stage `NOR3` outperforms 2-stage `OR3 + INV_X1` for `sram_ce` due to 2 fewer internal inverter stages.
   - **Trial 08 (`18.5 MHz` / `2.313 MIPS`, `+131.3%`)**: Connected single-stage `NOR3 _1102_.B` (`sram_ce`) directly to `clk_in_th` and anchored it below `SRAM128.CE` with a 9-branch clock/reset tree.
   - **Trial 09 (`18.5 MHz` / `2.313 MIPS`, Shortest 41-FF Wirelength `430,680 µm`, Lowest 41-FF Vias `2,717` & Lowest Power `1.570 mW`)**: Condensed the clock/reset tree to 8 branches (`FO(clk_in_th) = 9`, `FO(rst_n) = 8`) and shifted `SRAM128` West to `(334.8 µm, 1614.6 µm)`, achieving `79.19%` utilization and `744` decap filler sites.
   - **Trial 10 (`19.0 MHz` / `2.375 MIPS`, `+137.5%` All-Time Record Fastest!!)**: Co-located all 12 cells of the half-cycle `X1` pre-read pipeline (`reg_buf[3:0]` and driving `NAND2`/`NAND3` gates) in Row 8 directly beneath `SRAM128.DO[3:0]` and cascaded `d_hiz -> _1072_ -> d_oe` (`FO(d_hiz_pre) = 1`), achieving **`FMAX = 19.0 MHz` (`2.375 MIPS`)** and the shortest 41-FF data output delay (`t_pd(D[3:0]) = 39.81 ns`).
2. **100% DRC/LVS Signoff Clean Across All 10 Trials**:
   - Every single trial (`TR-1um_C4004_01` through `TR-1um_C4004_10`) achieved **0 OpenROAD detailed routing DRC violations, 0 KLayout signoff DRC violations, and exact KLayout LVS `Match` in both hierarchical (`deep`) and flattened (`flat`) modes**.


