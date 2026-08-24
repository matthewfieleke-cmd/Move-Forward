#!/usr/bin/env python3
"""Generate Move Forward app icons as PNG without third-party libraries."""

from __future__ import annotations

import math
import os
import struct
import zlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: str, width: int, height: int, rgba_rows: list[bytes]) -> None:
    raw = bytearray()
    for row in rgba_rows:
        raw.append(0)
        raw.extend(row)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(png)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c0, c1, t):
    return tuple(int(lerp(c0[i], c1[i], t)) for i in range(3))


def clamp(v: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, v))


def render_icon(size: int) -> list[bytes]:
    navy = (14, 26, 43)
    navy2 = (11, 48, 58)
    teal = (46, 160, 163)
    teal_light = (186, 236, 232)
    amber = (217, 148, 62)
    ink = (232, 240, 244)

    cx = cy = (size - 1) / 2.0
    radius = size * 0.42
    ring_w = size * 0.055
    rows: list[bytes] = []

    for y in range(size):
        row = bytearray(size * 4)
        for x in range(size):
            nx = (x - cx) / size
            ny = (y - cy) / size
            dist_center = math.hypot(x - cx, y - cy)
            # radial background
            t = clamp(dist_center / (size * 0.72))
            bg = mix(navy2, navy, t * t)
            # faint vignette
            vig = clamp((dist_center - size * 0.28) / (size * 0.5))
            bg = mix(bg, (8, 14, 24), vig * 0.35)

            px, py, pz = bg[0], bg[1], bg[2]
            alpha = 255

            # outer soft glow ring
            glow = abs(dist_center - radius)
            if glow < ring_w * 3.2:
                g = clamp(1.0 - glow / (ring_w * 3.2))
                px, py, pz = mix((px, py, pz), teal, g * 0.16)

            # main progress ring
            ang = math.atan2(cy - y, x - cx)  # 0 at east, CCW
            # convert so 0 is 12 o'clock, clockwise
            clock = (math.pi / 2 - ang) % (math.tau)
            progress = 0.72
            on_progress = clock <= progress * math.tau
            # amber exit tick around 11/20 = 0.55 of the ring
            exit_start = 0.52 * math.tau
            exit_end = 0.60 * math.tau
            on_exit = exit_start <= clock <= exit_end

            ring_dist = abs(dist_center - radius)
            if ring_dist < ring_w:
                k = clamp(1.0 - ring_dist / ring_w)
                k = k ** 0.55
                if on_exit:
                    col = amber
                elif on_progress:
                    col = teal
                else:
                    col = (38, 58, 74)
                px, py, pz = mix((px, py, pz), col, k)

            # inner disc
            inner_r = radius - ring_w * 1.65
            if dist_center < inner_r:
                k = clamp((inner_r - dist_center) / inner_r)
                inner = mix((18, 36, 48), (16, 56, 62), 1 - dist_center / inner_r)
                px, py, pz = mix((px, py, pz), inner, 0.88)

            # chevron / forward mark
            # two bars forming >
            lx = (x - cx) / size
            ly = (y - cy) / size
            # rounded chevron using distance to two segments
            def dist_seg(px_, py_, x0, y0, x1, y1):
                vx, vy = x1 - x0, y1 - y0
                wx, wy = px_ - x0, py_ - y0
                len2 = vx * vx + vy * vy
                t_ = 0 if len2 == 0 else clamp((wx * vx + wy * vy) / len2)
                dx, dy = px_ - (x0 + t_ * vx), py_ - (y0 + t_ * vy)
                return math.hypot(dx, dy)

            d1 = dist_seg(lx, ly, -0.06, -0.13, 0.10, 0.00)
            d2 = dist_seg(lx, ly, -0.06, 0.13, 0.10, 0.00)
            d3 = dist_seg(lx, ly, -0.13, -0.13, 0.03, 0.00)
            d4 = dist_seg(lx, ly, -0.13, 0.13, 0.03, 0.00)
            thickness = 0.028
            chev = min(d1, d2)
            chev2 = min(d3, d4)
            if chev < thickness:
                k = clamp(1.0 - chev / thickness)
                px, py, pz = mix((px, py, pz), teal_light, k)
            elif chev2 < thickness * 0.82:
                k = clamp(1.0 - chev2 / (thickness * 0.82)) * 0.55
                px, py, pz = mix((px, py, pz), teal, k)

            # tiny amber origin dot at left of chevron
            dot = math.hypot(lx + 0.155, ly)
            if dot < 0.018:
                k = clamp(1.0 - dot / 0.018)
                px, py, pz = mix((px, py, pz), amber, k)

            idx = x * 4
            row[idx : idx + 4] = bytes((px, py, pz, alpha))
        rows.append(bytes(row))
        # unused ink to keep palette referenced
        _ = ink
    return rows


def main() -> None:
    size = 1024
    rows = render_icon(size)
    ios = os.path.join(ROOT, "MoveForward/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    watch = os.path.join(ROOT, "MoveForwardWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    write_png(ios, size, size, rows)
    write_png(watch, size, size, rows)
    print(f"wrote {ios} and {watch}")


if __name__ == "__main__":
    main()
