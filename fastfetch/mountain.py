"""Generate the fastfetch mountain logo as plain ASCII with truecolor escapes.

Same idea as the nvim header: a silhouette of per-row spans, colour bands
with wandering contours, and glacier/rock overrides. Glyphs are ASCII only:
'/' and '\\' on the slopes, a texture character per band inside, '^' trees.

Usage: mountain.py            # plain preview + colour-letter map
       mountain.py --ansi OUT # write the coloured logo file
"""
import random
import sys

W, H = 53, 14

# Main apex col 33, Shastina-style secondary apex col 12, Little Tahoma bump
# col 44. Apex rows are two cells wide so they render as "/\".
spans = {
    0: [(33, 34)],
    1: [(32, 35)],
    2: [(31, 36)],
    3: [(30, 37)],
    4: [(29, 38)],
    5: [(12, 13), (28, 39)],
    6: [(11, 14), (26, 40), (44, 45)],
    7: [(10, 15), (25, 41), (43, 46)],
    8: [(8, 17), (23, 47)],
    9: [(7, 19), (21, 48)],
    10: [(4, 49)],
    11: [(2, 50)],
    12: [(1, 51)],
}

overrides = [
    # central glacier drifting left off the summit
    (3, 32, 32, "i"), (4, 31, 32, "i"), (5, 30, 32, "i"), (6, 29, 31, "i"),
    (7, 28, 30, "i"), (8, 28, 29, "i"), (9, 28, 28, "i"),
    # right glacier
    (4, 36, 36, "i"), (5, 36, 37, "i"), (6, 37, 38, "i"), (7, 38, 39, "i"),
    (8, 39, 40, "i"),
    # secondary peak glacier
    (6, 12, 12, "i"), (7, 12, 13, "i"), (8, 12, 12, "i"),
    # rock rib on the main face
    (7, 34, 35, "r"), (8, 33, 35, "r"),
]

palette = {
    "s": "#F4F6FB",  # summit snow
    "i": "#9FD3F0",  # glacier ice
    "h": "#B9C6D8",  # shaded snowfields
    "r": "#8B8F9A",  # grey rock
    "b": "#7A6250",  # brown rock
    "f": "#3E7C3A",  # forest
    "d": "#24502A",  # tree line
}

# Texture glyph per band: lighter at the top, denser lower down.
fill = {"s": "*", "i": ":", "h": "+", "r": "#", "b": "%", "f": "&", "d": "^"}

rng = random.Random(7)


def contour(nominal, lo, hi, run=0.65):
    out, cur = [], nominal
    for _ in range(W):
        if rng.random() > run:
            cur = nominal + rng.randint(lo, hi)
        out.append(cur)
    return out


bands = [
    ("s", contour(6, 0, 1)),
    ("h", contour(9, -1, 1)),
    ("r", contour(11, -1, 1)),
    ("b", contour(13, -2, 1)),
    ("f", None),
]


def band_at(y, x):
    for letter, boundary in bands:
        if boundary is None or y < boundary[x]:
            return letter


tree_line = "dfdddfddddfdddfddddfddfdddddfdddfddddfddfdddfddddfddd"
assert len(tree_line) == W

grid = [[" "] * W for _ in range(H)]
for y, row in spans.items():
    for a, b in row:
        for x in range(a, b + 1):
            grid[y][x] = band_at(y, x)
for y, a, b, c in overrides:
    for x in range(a, b + 1):
        assert grid[y][x] != " ", (y, x)
        grid[y][x] = c
grid[H - 1] = list(tree_line)


def cell(y, x):
    if y < 0 or x < 0 or x >= W:
        return " "
    return grid[y][x]


def glyph(y, x):
    c = grid[y][x]
    if c == " ":
        return " "
    if y == H - 1:
        return "^" if c == "d" else fill["f"]
    if cell(y, x - 1) == " ":
        return "/"
    if cell(y, x + 1) == " ":
        return "\\"
    return fill[c]


art = ["".join(glyph(y, x) for x in range(W)) for y in range(H)]
cmap = ["".join(grid[y]) for y in range(H)]


def rgb(hex_):
    return tuple(int(hex_[i : i + 2], 16) for i in (1, 3, 5))


def ansi_line(y):
    out, cur = [], None
    for x in range(W):
        ch, key = art[y][x], cmap[y][x]
        if ch == " ":
            out.append(" ")
            continue
        if key != cur:
            r, g, b = rgb(palette[key])
            out.append(f"\x1b[38;2;{r};{g};{b}m")
            cur = key
        out.append(ch)
    return "".join(out).rstrip() + "\x1b[0m"


if len(sys.argv) == 3 and sys.argv[1] == "--ansi":
    with open(sys.argv[2], "w", encoding="utf-8") as fh:
        fh.write("\n".join(ansi_line(y) for y in range(H)) + "\n")
else:
    print("\n".join(art))
    print()
    print("\n".join(cmap))
