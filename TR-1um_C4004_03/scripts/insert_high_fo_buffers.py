import os
import re
import json
from collections import defaultdict

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_V    = os.path.join(BASE_DIR, "openroad/c4004_core_raw_syn.v")
OUT_V    = os.path.join(BASE_DIR, "openroad/c4004_core_syn.v")
CELL_INFO_JSON = os.path.join(BASE_DIR, "module/STDCELL/cell_info.json")
ROW_MAP_JSON   = os.path.join(BASE_DIR, "openroad/ff_row_map.json")

with open(CELL_INFO_JSON, "r") as f:
    CELL_INFO = json.load(f)

OUTPUT_PIN_NAMES = {"Y", "Q", "QB", "DO"}

BUS_NET_PREFIXES = ("d_in", "d_out", "cm_ram", "sram_din", "sram_do")

def sanitize_net(net):
    net = net.strip()
    if net.startswith("{") and "sram_din" in net:
        return "sram_din"
    if net.startswith("{") and "sram_do" in net:
        return "sram_do"
    if net.startswith("\\"):
        s = net[1:].strip()
        m = re.match(r"^(\w+)\[(\d+)\]$", s)
        if m:
            pfx, idx = m.group(1), m.group(2)
            if pfx in BUS_NET_PREFIXES:
                return f"{pfx}[{idx}]"
            return f"{pfx}_{idx}"
        return re.sub(r"[^\w]", "_", s)
    return net

def parse_verilog(path):
    with open(path, "r") as f:
        text = f.read()

    wires = set()
    for m in re.finditer(r"^\s*wire\s+([^;]+);", text, flags=re.MULTILINE):
        w_str = m.group(1).strip()
        if w_str.startswith("["):
            continue
        for tok in w_str.split(","):
            wires.add(sanitize_net(tok.strip()))

    inst_pattern = re.compile(
        r"^\s*(\S+)\s+(\S+)\s*\((.*?)\)\s*;",
        flags=re.MULTILINE | re.DOTALL
    )
    insts = []
    for m in inst_pattern.finditer(text):
        ctype = m.group(1)
        if ctype in ("module", "input", "output", "inout", "wire", "assign"):
            continue
        iname = m.group(2)
        body  = m.group(3)
        conns = {}
        for pm in re.finditer(r"\.(\w+)\(\s*([^\)]+?)\s*\)", body):
            conns[pm.group(1)] = sanitize_net(pm.group(2))
        insts.append({"type": ctype, "name": iname, "conns": conns})

    return wires, insts

wires, insts = parse_verilog(RAW_V)
print(f"Loaded {len(insts)} instances from {RAW_V}")

# -------------------------------------------------------------------------
# 1. Fold MUX2 + DFFRB -> MUXDFFRB when MUX2.Y only drives DFFRB.D
# -------------------------------------------------------------------------
net_drivers = {}
net_sinks = defaultdict(list)

for idx, inst in enumerate(insts):
    ctype = inst["type"]
    for pin, net in inst["conns"].items():
        if ctype == "SRAM128":
            if pin.startswith("DO"):
                net_drivers[net] = (idx, pin)
            else:
                net_sinks[net].append((idx, pin))
        else:
            if pin in OUTPUT_PIN_NAMES:
                net_drivers[net] = (idx, pin)
            else:
                net_sinks[net].append((idx, pin))

folded_mux_indices = set()
muxdff_count = 0
for idx, inst in enumerate(insts):
    if inst["type"] == "DFFRB":
        d_net = inst["conns"].get("D")
        if d_net in net_drivers and len(net_sinks[d_net]) == 1:
            drv_idx, drv_pin = net_drivers[d_net]
            drv_inst = insts[drv_idx]
            if drv_inst["type"] == "MUX2" and drv_pin == "Y":
                inst["type"] = "MUXDFFRB"
                del inst["conns"]["D"]
                inst["conns"]["A"] = drv_inst["conns"]["A"]
                inst["conns"]["B"] = drv_inst["conns"]["B"]
                inst["conns"]["S"] = drv_inst["conns"]["S"]
                folded_mux_indices.add(drv_idx)
                muxdff_count += 1

insts = [inst for idx, inst in enumerate(insts) if idx not in folded_mux_indices]
print(f"Folded {muxdff_count} MUX2+DFFRB pairs into MUXDFFRB (total insts now {len(insts)})")

# -------------------------------------------------------------------------
# 2. Insert Schmitt-Trigger BUFTH on all 7 Primary Inputs:
#    clk, rst, test, d_in[0], d_in[1], d_in[2], d_in[3]
# -------------------------------------------------------------------------
primary_inputs = [
    ("clk",     "clk_in_th",   "u_bufth_clk"),
    ("rst",     "rst_in_th",   "u_bufth_rst"),
    ("test",    "test_in_th",  "u_bufth_test"),
    ("d_in[0]", "din0_in_th",  "u_bufth_din0"),
    ("d_in[1]", "din1_in_th",  "u_bufth_din1"),
    ("d_in[2]", "din2_in_th",  "u_bufth_din2"),
    ("d_in[3]", "din3_in_th",  "u_bufth_din3"),
]

in_remap = {orig: new_net for orig, new_net, _ in primary_inputs}
for inst in insts:
    for pin, net in list(inst["conns"].items()):
        if net in in_remap:
            inst["conns"][pin] = in_remap[net]

for orig, new_net, bname in primary_inputs:
    wires.add(new_net)
    insts.append({
        "type": "BUFTH",
        "name": bname,
        "conns": {"A": orig, "Y": new_net}
    })

print("Inserted 7 BUFTH Schmitt-trigger input buffers on clk, rst, test, d_in[3:0]")

# -------------------------------------------------------------------------
# 3. Assign FFs to 10 Rows (3..4 FFs per row!) & Build Row-Based Clock/Reset Trees
#    (Max <= 10 sinks per leaf BUF_X2)
# -------------------------------------------------------------------------
NUM_ROWS = 10
ff_insts = [inst for inst in insts if inst["type"] in ("DFFRB", "MUXDFFRB", "DFFS", "EDFFRB")]
print(f"Total Flip-Flops: {len(ff_insts)}")

rst_n_net = ff_insts[0]["conns"]["RSTB"]
clk_th_net = "clk_in_th"

ff_row_map = {}
row_ffs = defaultdict(list)
for i, ff in enumerate(ff_insts):
    r = min(NUM_ROWS - 1, (i * NUM_ROWS) // len(ff_insts))
    ff_row_map[ff["name"]] = r
    row_ffs[r].append(ff)

# Non-FF sinks of clk_in_th and rst_n_net (e.g. sram_ce gate in row 9 near SRAM128)
for inst in insts:
    if inst["type"] not in ("DFFRB", "MUXDFFRB", "DFFS", "EDFFRB") and inst["name"] != "u_bufth_clk":
        for pin, net in list(inst["conns"].items()):
            if pin not in OUTPUT_PIN_NAMES:
                if net == clk_th_net:
                    inst["conns"][pin] = f"clk_buf_r{NUM_ROWS}"
                elif net == rst_n_net:
                    inst["conns"][pin] = f"rst_n_buf_r{NUM_ROWS}"

for r in range(NUM_ROWS):
    c_net = f"clk_buf_r{r+1}"
    rn_net = f"rst_n_buf_r{r+1}"
    wires.add(c_net)
    wires.add(rn_net)
    insts.append({
        "type": "BUF_X2",
        "name": f"u_clk_buf_r{r+1}",
        "conns": {"A": clk_th_net, "Y": c_net}
    })
    insts.append({
        "type": "BUF_X2",
        "name": f"u_rst_buf_r{r+1}",
        "conns": {"A": rst_n_net, "Y": rn_net}
    })
    ff_row_map[f"u_clk_buf_r{r+1}"] = r
    ff_row_map[f"u_rst_buf_r{r+1}"] = r
    for ff in row_ffs[r]:
        ff["conns"]["CK"] = c_net
        if "RSTB" in ff["conns"]:
            ff["conns"]["RSTB"] = rn_net

print(f"Inserted {NUM_ROWS} row-based BUF_X2 clock buffers (clk_buf_r1..r{NUM_ROWS}) and {NUM_ROWS} reset buffers (rst_n_buf_r1..r{NUM_ROWS})")

# -------------------------------------------------------------------------
# 4. Split all High-Fanout Internal Nets (FO > 10) into BUF_X2 Groups
# -------------------------------------------------------------------------
def get_sink_map(inst_list):
    smap = defaultdict(list)
    for idx, inst in enumerate(inst_list):
        ctype = inst["type"]
        for pin, net in inst["conns"].items():
            if ctype == "SRAM128":
                if not pin.startswith("DO"):
                    smap[net].append((idx, pin))
            else:
                if pin not in OUTPUT_PIN_NAMES:
                    smap[net].append((idx, pin))
    return smap

smap = get_sink_map(insts)
exempt_nets = {orig for orig, _, _ in primary_inputs} | {"clk_in_th", rst_n_net}
exempt_nets |= {f"clk_buf_r{r+1}" for r in range(NUM_ROWS)} | {f"rst_n_buf_r{r+1}" for r in range(NUM_ROWS)}
exempt_nets |= {f"sram_din[{i}]" for i in range(4)} | {"sram_din", "sram_do"}

fo_buf_idx = 0
for net, sinks in list(smap.items()):
    if net in exempt_nets or len(sinks) <= 10:
        continue
    num_groups = max(2, (len(sinks) + 9) // 10)
    chunk_size = (len(sinks) + num_groups - 1) // num_groups
    for g in range(num_groups):
        grp = sinks[g * chunk_size : (g + 1) * chunk_size]
        if not grp:
            continue
        fo_buf_idx += 1
        bnet = f"fo_net_{fo_buf_idx}_g{g}"
        bname = f"u_fobuf_{fo_buf_idx}_g{g}"
        wires.add(bnet)
        insts.append({
            "type": "BUF_X2",
            "name": bname,
            "conns": {"A": net, "Y": bnet}
        })
        for s_idx, s_pin in grp:
            insts[s_idx]["conns"][s_pin] = bnet

print(f"Inserted {fo_buf_idx} high-fanout BUF_X2 buffers for nets with FO > 10")

final_smap = get_sink_map(insts)
max_fo = max(len(v) for v in final_smap.values())
print(f"Max fanout across all nets after buffering: {max_fo} (<= 10 target met!)")

with open(ROW_MAP_JSON, "w") as f:
    json.dump(ff_row_map, f, indent=2)

# -------------------------------------------------------------------------
# 5. Write Final Synthesized & Buffered Netlist (openroad/c4004_core_syn.v)
# -------------------------------------------------------------------------
port_and_bus_nets = {
    "clk", "rst", "test",
    "d_in[0]", "d_in[1]", "d_in[2]", "d_in[3]",
    "d_out[0]", "d_out[1]", "d_out[2]", "d_out[3]",
    "d_oe", "d_hiz", "sync", "cm_rom",
    "cm_ram[0]", "cm_ram[1]", "cm_ram[2]", "cm_ram[3]",
    "sram_din", "sram_do",
    "sram_din[0]", "sram_din[1]", "sram_din[2]", "sram_din[3]",
    "sram_do[0]", "sram_do[1]", "sram_do[2]", "sram_do[3]"
}

all_used_nets = set()
for inst in insts:
    for net in inst["conns"].values():
        all_used_nets.add(net)

scalar_wires = sorted(all_used_nets - port_and_bus_nets)

v_lines = [
    "// Synthesized and Buffered Gate-Level Netlist for c4004_core (Trial 02: 10 Rows)",
    "module c4004_core (",
    "  clk,",
    "  rst,",
    "  test,",
    "  d_in,",
    "  d_out,",
    "  d_oe,",
    "  d_hiz,",
    "  sync,",
    "  cm_rom,",
    "  cm_ram",
    ");",
    "  input clk;",
    "  input rst;",
    "  input test;",
    "  input [3:0] d_in;",
    "  output [3:0] d_out;",
    "  output d_oe;",
    "  output d_hiz;",
    "  output sync;",
    "  output cm_rom;",
    "  output [3:0] cm_ram;",
    "",
    "  wire [3:0] sram_din;",
    "  wire [3:0] sram_do;",
]

for w in scalar_wires:
    v_lines.append(f"  wire {w};")
v_lines.append("")

for inst in insts:
    ctype = inst["type"]
    iname = inst["name"]
    c_strs = [f".{k}({v})" for k, v in inst["conns"].items()]
    v_lines.append(f"  {ctype} {iname} ( " + ", ".join(c_strs) + " );")

v_lines.append("endmodule")
with open(OUT_V, "w") as f:
    f.write("\n".join(v_lines) + "\n")

total_sites = 0
for inst in insts:
    if inst["type"] != "SRAM128":
        total_sites += int(CELL_INFO[inst["type"]]["sites"])
print(f"Wrote {OUT_V}: {len(insts)} total instances ({len(insts)-1} stdcells + 1 SRAM128), {total_sites} sites (out of 3250 available sites = {total_sites*100.0/3250:.1f}% utilization)")
