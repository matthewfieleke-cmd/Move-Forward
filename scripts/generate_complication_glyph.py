#!/usr/bin/env python3
"""Generate the Move Forward watch complication glyph as a template PNG.

Accessory complications render as a single tinted colour, so this draws the app
icon's mark (progress ring with an exit notch plus the forward chevron) as an
alpha-only shape rather than reusing the full-colour icon.
"""

from __future__ import annotations

import json
import math
import os
import struct
import zlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GLYPH_DIR = os.path.join(ROOT, "MoveForwardWatchWidgets/Assets.xcassets/ComplicationGlyph.imageset")
SUPERSAMPLE = 6


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: str, size: int, rows: list[bytes]) -> None:
    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw.extend(row)
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(png)


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def distance_to_segment(px: float, py: float, x0: float, y0: float, x1: float, y1: float) -> float:
    vx, vy = x1 - x0, y1 - y0
    wx, wy = px - x0, py - y0
    length2 = vx * vx + vy * vy
    t = 0.0 if length2 == 0 else clamp((wx * vx + wy * vy) / length2)
    dx, dy = px - (x0 + t * vx), py - (y0 + t * vy)
    return math.hypot(dx, dy)


def covers(nx: float, ny: float) -> bool:
    """Whether a point in normalised -0.5...0.5 space is inside the mark.

    Shapes are tested as solids; supersampling supplies the anti-aliasing, which
    keeps the strokes crisp at complication sizes instead of soft and smudged.
    """
    distance = math.hypot(nx, ny)

    radius = 0.385
    ring_half_width = 0.050
    if abs(distance - radius) < ring_half_width:
        # Angle measured clockwise from twelve o'clock, matching the app icon.
        angle = (math.pi / 2 - math.atan2(-ny, nx)) % math.tau
        # The icon marks the room-exit checkpoint here, so the ring breaks for it.
        if not 0.525 * math.tau <= angle <= 0.605 * math.tau:
            return True

    chevron = min(
        distance_to_segment(nx, ny, -0.090, -0.150, 0.090, 0.0),
        distance_to_segment(nx, ny, -0.090, 0.150, 0.090, 0.0),
    )
    return chevron < 0.050


def render(size: int) -> list[bytes]:
    rows: list[bytes] = []
    step = 1.0 / SUPERSAMPLE
    for y in range(size):
        row = bytearray(size * 4)
        for x in range(size):
            hits = 0
            for sy in range(SUPERSAMPLE):
                for sx in range(SUPERSAMPLE):
                    nx = (x + (sx + 0.5) * step) / size - 0.5
                    ny = (y + (sy + 0.5) * step) / size - 0.5
                    if covers(nx, ny):
                        hits += 1
            alpha = int(round(255 * hits / (SUPERSAMPLE * SUPERSAMPLE)))
            index = x * 4
            row[index : index + 4] = bytes((255, 255, 255, alpha))
        rows.append(bytes(row))
    return rows


def main() -> None:
    scales = {"ComplicationGlyph.png": 64, "ComplicationGlyph@2x.png": 128, "ComplicationGlyph@3x.png": 192}
    images = []
    for name, size in scales.items():
        write_png(os.path.join(GLYPH_DIR, name), size, render(size))
        scale = "1x" if "@" not in name else name.split("@")[1].split(".")[0]
        images.append({"filename": name, "idiom": "universal", "scale": scale})

    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "template"},
    }
    with open(os.path.join(GLYPH_DIR, "Contents.json"), "w", encoding="utf-8") as handle:
        json.dump(contents, handle, indent=2)
        handle.write("\n")
    print(f"wrote glyph assets in {GLYPH_DIR}")


if __name__ == "__main__":
    main()
