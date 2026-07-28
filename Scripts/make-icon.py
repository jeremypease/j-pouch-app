"""Generates the J-Pouch app icon.

A stylised "J" — the pouch is named for the shape it's built in, so the letterform is
meaningful to the people using this rather than decorative, and it stays legible at 40pt
where anything anatomical or detailed would turn to mush.

Anti-aliased with a signed distance field: one sample per pixel, coverage derived from the
distance to the stroke centreline. Supersampling would need ~9x the work for a worse edge.
Pure stdlib — no Pillow on this machine, and an icon generator isn't worth a dependency.
"""

import math
import struct
import zlib

SIZE = 1024
OUT = "/Users/jeremypease/Documents/J-Pouch App/JPouch/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"

# Stroke geometry. The stem sits directly above the arc's right end so the join is seamless.
STROKE_HALF_WIDTH = 85.0
ARC_CENTRE = (512.0, 610.0)
ARC_RADIUS = 165.0
STEM_X = ARC_CENTRE[0] + ARC_RADIUS      # 677
STEM_TOP = 250.0
STEM_BOTTOM = ARC_CENTRE[1]              # 610
ARC_LEFT_END = (ARC_CENTRE[0] - ARC_RADIUS, ARC_CENTRE[1])
ARC_RIGHT_END = (STEM_X, ARC_CENTRE[1])

# Blue into green, on a diagonal. Jeremy's reference icon used this pairing and it reads
# warmer and less clinical than the teal it replaced.
TOP_COLOUR = (58, 122, 176)     # soft blue
BOTTOM_COLOUR = (116, 179, 116) # soft green
MARK_COLOUR = (255, 255, 255)


def distance_to_stem(x, y):
    if y < STEM_TOP:
        return math.hypot(x - STEM_X, y - STEM_TOP)
    if y > STEM_BOTTOM:
        return math.hypot(x - STEM_X, y - STEM_BOTTOM)
    return abs(x - STEM_X)


def distance_to_arc(x, y):
    dx = x - ARC_CENTRE[0]
    dy = y - ARC_CENTRE[1]
    # Screen y grows downward, so the lower half of the circle is dy >= 0 — that's the hook.
    if dy >= 0:
        radial = math.hypot(dx, dy)
        return abs(radial - ARC_RADIUS)
    return min(
        math.hypot(x - ARC_LEFT_END[0], y - ARC_LEFT_END[1]),
        math.hypot(x - ARC_RIGHT_END[0], y - ARC_RIGHT_END[1]),
    )


def build():
    rows = []
    for y in range(SIZE):
        py = y + 0.5
        # Diagonal rather than straight down, so the two hues both get real estate.
        t_row = y / (SIZE - 1)
        row = bytearray()
        row.append(0)  # PNG filter type: none
        for x in range(SIZE):
            px = x + 0.5
            t = (x / (SIZE - 1)) * 0.45 + t_row * 0.55
            bg = tuple(
                int(round(TOP_COLOUR[i] + (BOTTOM_COLOUR[i] - TOP_COLOUR[i]) * t))
                for i in range(3)
            )
            distance = min(distance_to_stem(px, py), distance_to_arc(px, py))
            # One pixel of feathering either side of the edge gives a clean edge without
            # the shape looking soft.
            coverage = (STROKE_HALF_WIDTH + 0.5 - distance) / 1.0
            coverage = 0.0 if coverage < 0.0 else (1.0 if coverage > 1.0 else coverage)
            if coverage <= 0.0:
                row.extend(bg)
            else:
                row.extend(
                    int(round(bg[i] + (MARK_COLOUR[i] - bg[i]) * coverage)) for i in range(3)
                )
        rows.append(bytes(row))
    return b"".join(rows)


def chunk(tag, data):
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


raw = build()
# Colour type 2 (RGB, no alpha): App Store icons must be fully opaque.
ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
png = (
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", ihdr)
    + chunk(b"IDAT", zlib.compress(raw, 9))
    + chunk(b"IEND", b"")
)

with open(OUT, "wb") as handle:
    handle.write(png)

print(f"wrote {OUT} ({len(png):,} bytes)")
