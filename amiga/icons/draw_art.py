#!/usr/bin/env python3
"""ascii-invaders' picture for its GlowIcons (art/asciiinvaders.png), drawn
here: upstream's pictures are screen shots. A dark screen, two rows of
blocky invaders, a shelter and the gunner firing up at them.
64 x 64, RGBA, solid or see-through.
    python3 amiga/icons/draw_art.py amiga/icons/art
Pure Python. GPL-2.0-or-later, Copyright (c) 2026 AmiCradle Team."""
import struct, sys, zlib
from pathlib import Path

W = H = 64
INK = (16, 18, 22, 255)


def png(px, path):
    raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in px)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def draw():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    def rect(x0, y0, x1, y1, c):
        for y in range(max(0, y0), min(H, y1)):
            for x in range(max(0, x0), min(W, x1)):
                px[y][x] = c
    INVADER = ["..#...#..", "...###...", "..#####..", ".##.#.##.", "#########", "#.#...#.#"]
    def sprite(x0, y0, rows, c, s=1):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch == "#":
                    rect(x0 + i * s, y0 + j * s, x0 + (i + 1) * s, y0 + (j + 1) * s, c)
    rect(2, 4, 62, 60, INK)
    for k in range(4):
        sprite(6 + k * 14, 9, INVADER, (230, 60, 200, 255))
        sprite(6 + k * 14, 19, INVADER, (60, 200, 230, 255))
    rect(10, 42, 22, 46, (60, 200, 80, 255))        # shelters
    rect(42, 42, 54, 46, (60, 200, 80, 255))
    sprite(26, 51, ["...#...", ".#####.", "#######"], (60, 220, 90, 255), 2)
    rect(32, 31, 34, 38, (240, 240, 240, 255))      # the shot
    return px


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "amiga/icons/art")
    out.mkdir(parents=True, exist_ok=True)
    png(draw(), out / "asciiinvaders.png")
