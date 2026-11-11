import os
import pya

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ly = pya.Layout()
ly.read(os.path.join(BASE_DIR, "module/SRAM128/SRAM128.gds"))
top = ly.top_cell()
dbu = ly.dbu
ox, oy = 82.1, 90.1

for lnum, dt, name in [(19,0,"V1"), (20,0,"M2")]:
    li = ly.find_layer(lnum, dt)
    reg = pya.Region(top.begin_shapes_rec(li))
    for p in reg.each():
        pb = p.bbox()
        x1, y1, x2, y2 = pb.left*dbu+ox, pb.bottom*dbu+oy, pb.right*dbu+ox, pb.top*dbu+oy
        if x1 < 10.0 or x2 > 1156.0:
            print(f"{name}: ({x1:.2f}, {y1:.2f})..({x2:.2f}, {y2:.2f})")
