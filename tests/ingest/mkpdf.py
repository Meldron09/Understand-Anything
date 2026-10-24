"""mkpdf.py <out.pdf> <pages> [--outline] [--scanned] [--contents] [--equation]: write a small test PDF, stdlib only.

Each page has filler lines; a chapter heading "Chapter N" starts every 10th page. --outline adds a
bookmark per chapter; --scanned draws a box and no text (no text layer); --contents makes page 2 a
printed contents page, chapters then start at page 3 and print one less than the PDF page (page 1 is a cover);
--equation puts a garbled quadratic formula on page 3.
"""
import sys

out, n = sys.argv[1], int(sys.argv[2])
flags = set(sys.argv[3:])
starts = list(range(3 if "--contents" in flags else 1, n + 1, 10))  # chapter start pages (1-based)


def esc(s):
    return s.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def lines(p):
    if "--contents" in flags and p == 2:
        return ["Contents"] + [f"Chapter {i} {'.' * 20} {s - 1}" for i, s in enumerate(starts, 1)]
    head = [f"Chapter {starts.index(p) + 1}"] if p in starts else []
    body = [f"Page {p}: the quick brown fox jumps over the lazy dog, line {k}." for k in range(1, 25)]
    if "--equation" in flags and p == 3:
        body[3:3] = ["The roots follow x = - b +/- sqrt  b 2  - 4 a c", "  2 a   (equation 1, fraction lost)"]
    return head + body


objs = {1: "<< /Type /Catalog /Pages 2 0 R" + (" /Outlines {o} 0 R" if "--outline" in flags else "") + " >>"}
kids = [4 + 2 * i for i in range(n)]
objs[2] = "<< /Type /Pages /Count %d /Kids [%s] >>" % (n, " ".join(f"{k} 0 R" for k in kids))
objs[3] = "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
for i in range(n):
    p = i + 1
    if "--scanned" in flags:
        body = "0.8 g 72 72 468 648 re f"
    else:
        body = "BT /F1 11 Tf 72 740 Td 14 TL " + " ".join(f"({esc(l)}) Tj T*" for l in lines(p)) + " ET"
    objs[4 + 2 * i] = f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents {5 + 2 * i} 0 R /Resources << /Font << /F1 3 0 R >> >> >>"
    objs[5 + 2 * i] = f"<< /Length {len(body)} >>\nstream\n{body}\nendstream"
if "--outline" in flags:
    root = 4 + 2 * n
    first = root + 1
    objs[root] = f"<< /Type /Outlines /First {first} 0 R /Last {first + len(starts) - 1} 0 R /Count {len(starts)} >>"
    for j, s in enumerate(starts):
        o = first + j
        extra = (f" /Prev {o - 1} 0 R" if j else "") + (f" /Next {o + 1} 0 R" if j < len(starts) - 1 else "")
        objs[o] = f"<< /Title (Chapter {j + 1}) /Parent {root} 0 R /Dest [{kids[s - 1]} 0 R /Fit]{extra} >>"
    objs[1] = objs[1].replace("{o}", str(root))
buf, offs = b"%PDF-1.4\n", {}
for k in sorted(objs):
    offs[k] = len(buf)
    buf += f"{k} 0 obj\n{objs[k]}\nendobj\n".encode("latin-1")
x = len(buf)
buf += f"xref\n0 {len(objs) + 1}\n0000000000 65535 f \n".encode()
buf += b"".join(f"{offs[k]:010d} 00000 n \n".encode() for k in sorted(objs))
buf += f"trailer\n<< /Size {len(objs) + 1} /Root 1 0 R >>\nstartxref\n{x}\n%%EOF\n".encode()
open(out, "wb").write(buf)
