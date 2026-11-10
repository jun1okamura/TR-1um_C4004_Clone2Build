import pya

ly = pya.Layout()
ly.read("/Users/okamura/Dropbox/98_LSI_Design/TR-1um_C4004_Clone2Build/TR-1um_C4004_01/module/STDCELL/TR-1um_STDCELL.gds")
print("=== STDCELL GDS CELLS ===")
for c in ly.each_cell():
    bbox = c.bbox()
    if c.name in ["TAP2", "FILL", "FILL2", "FILL3", "INV_X1", "BUF_X2", "BUFTH", "DFFRB", "MUXDFFRB"]:
        print(f"Cell {c.name}: bbox=({bbox.left*ly.dbu:.3f}, {bbox.bottom*ly.dbu:.3f})..({bbox.right*ly.dbu:.3f}, {bbox.top*ly.dbu:.3f})")
        for li in ly.layer_indices():
            lp = ly.get_info(li)
            if lp.layer in [3, 8, 11, 13, 19, 20, 48, 49, 140]:
                shapes = []
                for s in c.shapes(li).each():
                    b = s.bbox()
                    shapes.append(f"({b.left*ly.dbu:.2f},{b.bottom*ly.dbu:.2f})-({b.right*ly.dbu:.2f},{b.top*ly.dbu:.2f})")
                if shapes:
                    print(f"  L({lp.layer}/{lp.datatype}): {len(shapes)} shapes: {shapes[:8]}")

ly2 = pya.Layout()
ly2.read("/Users/okamura/Dropbox/98_LSI_Design/TR-1um_C4004_Clone2Build/TR-1um_C4004_01/module/SRAM128/SRAM128.gds")
top2 = ly2.top_cell()
b2 = top2.bbox()
print(f"\n=== SRAM128 GDS top={top2.name}: bbox=({b2.left*ly2.dbu:.3f}, {b2.bottom*ly2.dbu:.3f})..({b2.right*ly2.dbu:.3f}, {b2.top*ly2.dbu:.3f}) ===")
for li in ly2.layer_indices():
    lp = ly2.get_info(li)
    if lp.layer in [13, 19, 20, 48, 49, 140]:
        texts = []
        for s in top2.shapes(li).each():
            if s.is_text():
                t = s.text
                texts.append(f"'{t.string}'@({t.x*ly2.dbu:.2f},{t.y*ly2.dbu:.2f})")
        if texts:
            print(f"  Text L({lp.layer}/{lp.datatype}): {texts}")
