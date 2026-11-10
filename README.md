# TR-1um_C4004_Clone2Build — AI-Powered Iterative ASIC Optimization (Intel 4004 Compatible 4-bit CPU on OpenSUSI TR-1um 1 µm CMOS)

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

![Experimental for AI powered optimization](docs/Screenshot%202026-11-10%20at%2014.53.19.png)

## 概要 / Overview

本リポジトリ（**`TR-1um_C4004_Clone2Build`**）は、OpenSUSI **TR-1um PDK**（`1 µm` Si-Gate CMOS、2層メタル `M1`/`M2`、電源電圧 `5.0 V`、`2500 µm × 2500 µm` 16パッド `OSS_FRAME`）上に実装された **Intel 4004 完全互換 4-bit CPU (`C4004`)** を対象に、**AI エージェントによる自律的な RTL・フロアプラン・配置配線（APR）・トランジスタレベル検証の反復最適化ループ（全10試行）** を実施した実験リポジトリです。

This repository (**`TR-1um_C4004_Clone2Build`**) demonstrates an **AI-powered autonomous RTL-to-GDSII iterative optimization workflow** across **10 consecutive design trials (`TR-1um_C4004_01` – `TR-1um_C4004_10`)** of an Intel 4004 compatible 4-bit microprocessor (`C4004`) targeting the OpenSUSI **TR-1um (`1 µm` CMOS, 2-metal `M1`/`M2`, `5.0 V`)** technology.

---

## AI 自律最適化ワークフロー / AI Optimization Loop

上図（`docs/Screenshot 2026-11-10 at 14.53.19.png`）の通り、テンプレートリポジトリ（[`TR-1um_C4004`](https://github.com/jun1okamura/TR-1um_C4004.git)）を基点として、AI エージェントが以下の **5ステップの反復ループ** を10回実行しました。

1. **Clone the template (`TR-1um_C4004` $\to$ `TR-1um_C4004_01` .. `TR-1um_C4004_10`)**
   - ベースライン仕様（`Prompt.md`, `docs/`, `reference/`）を持つテンプレートリポジトリから各試行用の作業ディレクトリをクローンして開始します。
2. **Start a trial（毎回ゼロベースでのアーキテクチャ・物理設計再検討）**
   - 前回の試行で判明したボトルネック（クリティカルパス、配線混雑、クロック/リセット木のファンアウト、SRAM マクロ周辺のピンアクセス等）を分析し、**毎回の試行の前に以下の項目を毎回見直して再設計**します：
     - **RTL レベルの最適化**: シャドウ PC バイパス、4-bit Carry-Lookahead Adder (CLA)、`X1` ステージのレジスタ先行読み出しパイプライン (`reg_buf[3:0]`)、複合ゲート (`NAND3` + `MUXDFFRB`) 直結化、出力トライステート/データ駆動論理の再構成
     - **SRAM マクロ (`SRAM128`, `1118.2 µm × 454.6 µm`) の配置座標最適化**: 東西・南北の配線チャネル幅と `DO[3:0]` / `CE` ピンへの直下アクセス性を考慮した座標調整
     - **スタンダードセル行数（チャネル数）・行ピッチの検討**: 9行（`178.2 µm` ピッチ）$\to$ 10行（`156.6 µm` / `162.0 µm` ピッチ）$\to$ 11行（`145.8 µm` ピッチ、`3.0 × 48.6 µm`）
     - **クロック/リセット木およびクリティカルセルの物理アンカリング**: `clk_in_th` / `rst_n` バッファ分岐数の最適化、`SRAM128` 直下 Row 8 へのハーフサイクル先行読み出しパイプライン集約配置
   - **完全自動 RTL-to-GDSII ビルド**:
     - RTL 論理シミュレーション（Icarus Verilog）
     - 論理合成（Yosys + `MUXDFFRB` マッピング）および高ファンアウトバッファ挿入
     - 自動配置配線（OpenROAD: 2層メタル `M1`/`M2` ルーティング）
     - チップ統合・物理検証（KLayout DRC = `0` エラー、KLayout LVS = `Congratulations! Netlists match.`）
3. **Evaluate result（トランジスタレベル SPICE シミュレーションによる実測評価）**
   - 抽出後のフルチップ SPICE ネットリスト（`6,682`〜`6,700` MOSFET + `OSS_FRAME` パッド負荷 `5 pF`）に対し **ngspice トランジスタレベル過渡解析** を実行し、実チップ条件での最大動作周波数（**`FMAX`**）、各テストプログラムの PASS/FAIL、パッド遅延、消費電力、総配線長、ビア数を定量評価します。
4. **Generate `Summary.md`（結果の集計・考察ドキュメント生成）**
   - 全試行の設計パラメータ・物理指標・SPICE 波形解析結果を [`Summary.md`](Summary.md) / [`Summary_EN.md`](Summary_EN.md) および Excel 集計表（[`Summary.xlsx`](Summary.xlsx), [`Summary_JP.xlsx`](Summary_JP.xlsx), [`Summary_EN.xlsx`](Summary_EN.xlsx)）にまとめます。
5. **Loop to (1) to make better result（次試行へのフィードバック）**
   - 実測された支配的クリティカルパス（例：PC インクリメント鎖 $\to$ ALU キャリー鎖 $\to$ `SRAM128` 読み出しセットアップ $\to$ `sram_ce` クロックゲート遅延 $\to$ `X1` ハーフサイクル `SRAM128.DO[3:0]` 取り込みパス）を次の試行へフィードバックし、さらなる性能向上を図ります。

---

## 全10試行の最適化推移サマリ / Summary of 10 Optimization Trials

**Trial 01（ベースライン `8.0 MHz`）** から **Trial 10（最高速 `19.0 MHz`）** にかけて、DRC `0` エラー・LVS 完全一致を維持したまま **最大動作周波数を `+137.5%`（約 2.38 倍、`1.000 MIPS` $\to$ `2.375 MIPS`）向上** させました。

| Trial | ディレクトリ | RTL アーキテクチャ & 物理設計の主な工夫 | チャネル数 (行ピッチ) | `SRAM128` 座標 `(X, Y)` [µm] | StdCell 数 (利用率) | 総配線長 WL [µm] | ビア数 (`via`) | DRC / LVS | 最大動作周波数 `FMAX` (`MIPS`) | 消費電力 `@ 1 MHz` / `@ FMAX` |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **01** | [`TR-1um_C4004_01`](TR-1um_C4004_01) | ベースライン 37-FF (`acc`/`cy` のみ `MUXDFFRB`) + リップルキャリー加算器 | 9行 (`178.2 µm`) | `(338.2, 1603.8)` | `598` (`93.20%`) | `442,818` | `2,756` | `0` / Match | **`8.0 MHz`** (`1.000 MIPS`) | `1.688 mW` / `12.509 mW` |
| **02** | [`TR-1um_C4004_02`](TR-1um_C4004_02) | シャドウ PC バイパス (`pc_init_n`) + 4-bit CLA + 全37-FF `MUXDFFRB` 化 | 10行 (`156.6 µm`) | `(334.8, 1587.6)` | `578` (`81.51%`) | **`420,271`** *(最短WL)* | `2,643` | `0` / Match | **`11.0 MHz`** (`1.375 MIPS`) | **`1.560 mW`** / `15.750 mW` |
| **03** | [`TR-1um_C4004_03`](TR-1um_C4004_03) | `X1` 先行読み出しパイプライン (`buf_l` 共有, 37-FF) + GCell 整合行ピッチ | 10行 (`162.0 µm`) | `(334.8, 1609.2)` | `606` (`85.05%`) | `431,639` | **`2,607`** *(最少ビア)* | `0` / Match | **`8.5 MHz`** *(内部ALU `15 MHz`)* | `1.590 mW` / `12.400 mW` |
| **04** | [`TR-1um_C4004_04`](TR-1um_C4004_04) | Non-Stop シャドウ PC + 専用 `reg_buf[3:0]` (41-FF) フルサイクル CLA | 11行 (`145.8 µm`) | `(334.8, 1614.6)` | `615` (`79.41%`) | `448,871` | `2,890` | `0` / Match | **`16.5 MHz`** (`2.063 MIPS`) | `1.622 mW` / `23.510 mW` |
| **05** | [`TR-1um_C4004_05`](TR-1um_C4004_05) | 4-bit 対称 `NAND3 + MUXDFFRB` `reg_buf[3:0]` 直結パイプライン (`26 MUXDFFRB`) | 11行 (`145.8 µm`) | `(340.2, 1614.6)` | `613` (`79.36%`) | `446,626` | `2,906` | `0` / Match | **`17.0 MHz`** (`2.125 MIPS`) | `1.615 mW` / `24.180 mW` |
| **06** | [`TR-1um_C4004_06`](TR-1um_C4004_06) | 専用 `BUF_X2` による `d_hiz`/`d_oe` 分離駆動 + `SRAM128` 東シフト配置 | 11行 (`145.8 µm`) | `(345.6, 1614.6)` | `615` (`79.52%`) | `448,037` | `2,939` | `0` / Match | **`17.0 MHz`** (`2.125 MIPS`) | `1.619 mW` / `24.250 mW` |
| **07** | [`TR-1um_C4004_07`](TR-1um_C4004_07) | `OR3 + INV_X1` (`u_inv_sram_ce`) 2段 `sram_ce` ドライバ検証 + 南シフト配置 | 11行 (`145.8 µm`) | `(340.2, 1609.2)` | `616` (`79.61%`) | `456,846` | `2,910` | `0` / Match | **`16.0 MHz`** (`2.000 MIPS`) | `1.625 mW` / `22.900 mW` |
| **08** | [`TR-1um_C4004_08`](TR-1um_C4004_08) | `clk_in_th` 直結 1段 `NOR3` (`_1102_`) Row 10 東端配置 + 9分岐クロック木 | 11行 (`145.8 µm`) | `(340.2, 1614.6)` | `613` (`79.36%`) | `438,162` | `2,844` | `0` / Match | **`18.5 MHz`** (`2.313 MIPS`) | `1.592 mW` / `26.150 mW` |
| **09** | [`TR-1um_C4004_09`](TR-1um_C4004_09) | 8分岐低容量クロック/リセット木 (`FO=9`) + `_1072_` 南端配置 + 西シフト | 11行 (`145.8 µm`) | `(334.8, 1614.6)` | **`611` (`79.19%`)** | **`430,680`** *(41-FF最短)* | **`2,717`** *(41-FF最少)* | `0` / Match | **`18.5 MHz`** (`2.313 MIPS`) | `1.570 mW` / `25.980 mW` |
| **10** | [`TR-1um_C4004_10`](TR-1um_C4004_10) | カスケード `d_hiz/d_oe` 駆動 + **Row 8 `SRAM128` 直下 `X1` 先行読出し集約配置** | 11行 (`145.8 µm`) | `(340.2, 1614.6)` | **`611` (`79.19%`)** | `450,643` | `2,985` | `0` / Match | **`19.0 MHz`** (**`2.375 MIPS` 最高速**) | `1.574 mW` / `27.469 mW` |

---

## リポジトリ構成 / Repository Structure

```text
TR-1um_C4004_Clone2Build/
├── README.md                  # 本ドキュメント (Repository overview)
├── LICENSE                    # Apache License 2.0
├── Prompt.md                  # 初期設計プロンプトおよび追加指示の履歴 (Prompts & instructions)
├── Summary.md                 # 全10試行の詳細設計レポート・比較表 (日本語版)
├── Summary_EN.md              # Detailed report & comparison tables for all 10 trials (English)
├── Summary.xlsx               # PPT貼付用 集計・比較 Excel ブック (日本語/英語シート統合版)
├── Summary_JP.xlsx            # PPT貼付用 集計・比較 Excel ブック (日本語版)
├── Summary_EN.xlsx            # PPT-ready summary & comparison Excel workbook (English)
├── docs/
│   └── Screenshot 2026-11-10 at 14.53.19.png  # AI Powered Optimization ワークフロー概念図
├── TR-1um_C4004_01/           # Trial 01: Baseline 37-FF + Ripple-Carry Adder (FMAX = 8.0 MHz)
├── TR-1um_C4004_02/           # Trial 02: Shadow PC Bypass + 4-bit CLA (FMAX = 11.0 MHz, Shortest WL)
├── TR-1um_C4004_03/           # Trial 03: Early X1 Pre-Read (buf_l shared) + 162um Pitch (FMAX = 8.5 MHz)
├── TR-1um_C4004_04/           # Trial 04: Non-Stop Shadow PC + Dedicated reg_buf[3:0] 41-FF (FMAX = 16.5 MHz)
├── TR-1um_C4004_05/           # Trial 05: 4-bit Symmetric NAND3+MUXDFFRB reg_buf[3:0] (FMAX = 17.0 MHz)
├── TR-1um_C4004_06/           # Trial 06: Dedicated BUF_X2 d_hiz/d_oe Drivers (FMAX = 17.0 MHz)
├── TR-1um_C4004_07/           # Trial 07: 2-Stage OR3+INV_X1 sram_ce Driver Study (FMAX = 16.0 MHz)
├── TR-1um_C4004_08/           # Trial 08: Direct 1-Stage NOR3 sram_ce + 9-Branch Clock Tree (FMAX = 18.5 MHz)
├── TR-1um_C4004_09/           # Trial 09: 8-Branch Low-Cap Clock Tree (FMAX = 18.5 MHz, Best 41-FF WL/Power)
└── TR-1um_C4004_10/           # Trial 10: Row 8 Half-Cycle X1 Pipeline Co-Location (FMAX = 19.0 MHz Record)
```

### 各試行ディレクトリ (`TR-1um_C4004_01` 〜 `TR-1um_C4004_10`) の内部構成

各 `TR-1um_C4004_NN/` ディレクトリには、RTL から最終テープアウト GDSII・SPICE 検証ログまでの全成果物が格納されています：

- `rtl/` : Verilog RTL (`c4004_core.v`, `c4004_top.v`)、テストベンチ (`tb_c4004.v`)、RTL/Gate シミュレーションログ (`rtl_sim.log`)
- `openroad/` : Yosys 合成スクリプト (`synth.ys`)、合成後ネットリスト (`c4004_core_syn.v`)、OpenROAD 配置配線スクリプト (`run_apr.tcl`)、配置配線ログ (`apr.log`, `gpl.log`, `grt.log`)
- `apr/` : 配線後 DEF (`c4004_core_routed.def`)、コア/チップ GDS (`c4004_core.gds`, `c4004_chip.gds`)、DRC/LVS レポート (`drc_chip.lyrdb`, `lvs_chip.lvsdb`)、ngspice トランジスタレベル検証ネットリストおよび波形ログ (`sim_test1_alu.log` 〜 `sim_test4_*MHz.log`)
- `src/` : OpenSUSI MPW 提出用最終 GDSII (`tr_1um_jun1okamura.gds`, `IP62_jun1okamura.gds`) および LVS 用 SPICE ネットリスト (`tr_1um_jun1okamura.cir`)
- `scripts/` : フロー自動化・バッファ挿入・DEF-to-GDS 変換・SPICE テスト生成スクリプト群

---

## 詳細ドキュメント / Detailed Documentation

- **プロンプト履歴 / Prompt History**: [`Prompt.md`](Prompt.md)
- **全10試行 詳細レポート（日本語）**: [`Summary.md`](Summary.md)
- **Full 10-Trial Technical Report (English)**: [`Summary_EN.md`](Summary_EN.md)
- **Excel 比較表 / Excel Workbooks**: [`Summary.xlsx`](Summary.xlsx) | [`Summary_JP.xlsx`](Summary_JP.xlsx) | [`Summary_EN.xlsx`](Summary_EN.xlsx)

---

## ライセンス / License

本リポジトリは **Apache License, Version 2.0** の下で公開されています。詳細は [`LICENSE`](LICENSE) を参照してください。

This repository is licensed under the **Apache License, Version 2.0**. See [`LICENSE`](LICENSE) for details.
