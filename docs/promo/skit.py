#!/usr/bin/env python3
"""
Skecz „Pod celą” – 15 s, pionowo 1080×1920, na TikToka / Shorts / Reels.

    make skit                               # z katalogu głównego repo
    python3 docs/promo/skit.py [plik.mp4]

Dwóch ziomków koduje nocą pod celą:
  Młody: Mordo, użyj gita.
  Stary: Gita? Git to ja jestem.        (*git = grypsujący – w grypserze to słowo z gwary)
  Stary: Puścimy grypsa.
  Młody: A co to gryps?
  Stary: Patrz.                          → beat, ekran laptopa, prawdziwa sesja grypsa
  Stary: Skitrasz… przyklepiesz… i gryps idzie na wolność.

Gryps to w więzieniu przemycany list – „puścić grypsa” to wysłać go na zewnątrz,
czyli dokładnie git push. Animacja rysowana w kodzie, dźwięk syntezowany w kodzie.
Wymagania jak dla short.py (pyte, pillow, numpy, ffmpeg, fonty DejaVu + Noto Color Emoji).
"""
import math
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import short as S  # noqa: E402  (pomocnicze: fonty, napisy, nagrywanie terminala)

R = S.R
ROOT = S.ROOT
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "dist", "gryps-skecz.mp4")
W, H, FPS = 1080, 1920, 30
BW, BH = W * 2, H * 2           # scena rysowana w 2× – kamera robi z niej zbliżenia
FLOOR = 2950
CYAN = (110, 215, 255)
SIL = (9, 10, 14)               # kolor sylwetek
YOUNG, OLD = S.YELLOW, S.WHITE  # kolory napisów: Młody / Stary

# ───────────────────────── Scenariusz (sekundy) ─────────────────────────
T_DROP = 8.6                    # cięcie na ekran laptopa + wejście bitu
T_END = 12.6                    # plansza końcowa
TOTAL = 15.0

# (od, do, kto, tekst)
LINES = [
    (1.7, 3.3, YOUNG, "Mordo, użyj gita."),
    (3.3, 4.0, OLD, "Gita?"),
    (4.0, 5.1, OLD, "Git to ja jestem."),
    (5.1, 6.5, OLD, "Puścimy grypsa."),
    (6.5, 7.8, YOUNG, "A co to gryps?"),
    (7.8, T_DROP, OLD, "Patrz."),
]
FOOTNOTE = (4.15, 5.1, "*git = grypsujący. Tak mówi gwara.")
SPEAKING = {YOUNG: [(a, b) for a, b, who, _ in LINES if who == YOUNG],
            OLD: [(a, b) for a, b, who, _ in LINES if who == OLD]}

# Kamera: (od, do, (cx, cy, zoom) na początku, (cx, cy, zoom) na końcu) – współrzędne sceny 2×
SHOTS = [
    (0.0, 1.7, (1080, 2050, 1.0), (1080, 2080, 1.1)),     # szeroko: cela nocą
    (1.7, 3.3, (1480, 2230, 2.2), (1480, 2230, 2.3)),     # Młody
    (3.3, 5.1, (840, 1980, 2.5), (840, 1960, 2.8)),       # Stary, powolny najazd
    (5.1, 6.5, (1180, 2180, 1.55), (1180, 2180, 1.6)),    # obaj
    (6.5, 7.8, (1480, 2230, 2.3), (1480, 2230, 2.35)),    # Młody
    (7.8, T_DROP, (840, 1960, 2.7), (840, 1930, 3.4)),    # Stary – szybki najazd przed bitem
]


# ───────────────────────── Scena ─────────────────────────
def radial(size, color, alpha, radius):
    """Warstwa RGBA z miękką poświatą."""
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt((xx - w / 2) ** 2 + (yy - h / 2) ** 2) / radius
    a = np.clip(1 - d, 0, 1) ** 2 * alpha
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    arr[..., 0], arr[..., 1], arr[..., 2] = color
    arr[..., 3] = a.astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def build_static():
    rng = np.random.default_rng(3)
    # ściana: gradient + szum betonu
    yy = np.linspace(0, 1, BH)[:, None]
    base = np.zeros((BH, BW, 3))
    base[:] = (18, 20, 28)
    base *= (0.55 + 0.45 * np.clip(1 - abs(yy - 0.55) * 1.6, 0, 1))[..., None]
    base += rng.normal(0, 3.2, (BH, BW, 1))
    base[FLOOR:] = (12, 13, 18) + rng.normal(0, 2.5, (BH - FLOOR, BW, 1))
    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)

    # okno z kratami i księżycem
    wx0, wy0, wx1, wy1 = 820, 420, 1340, 980
    d.rectangle([wx0 - 30, wy0 - 30, wx1 + 30, wy1 + 30], fill=(26, 28, 38))
    d.rectangle([wx0, wy0, wx1, wy1], fill=(24, 38, 66))
    d.ellipse([1150, 520, 1290, 660], fill=(225, 232, 245))
    d.ellipse([1180, 515, 1310, 645], fill=(24, 38, 66))  # sierp
    for x in range(wx0 + 40, wx1, 80):
        d.rectangle([x, wy0, x + 16, wy1], fill=(14, 15, 20))
    d.rectangle([wx0, 690, wx1, 706], fill=(14, 15, 20))

    # snop światła z okna na podłogę, z cieniem krat
    beam = Image.new("RGBA", (BW, BH))
    bd = ImageDraw.Draw(beam)
    bd.polygon([(wx0, wy1), (wx1, wy1), (1780, 3700), (520, 3700)], fill=(150, 175, 230, 22))
    for x in range(wx0 + 40, wx1, 80):
        f = lambda X: (X - 1080) * 2.42 + 1150  # noqa: E731  rozbieżność cienia
        bd.polygon([(x, wy1), (x + 16, wy1), (f(x + 16), 3700), (f(x), 3700)], fill=(0, 0, 0, 30))
    img = Image.alpha_composite(img, beam.filter(ImageFilter.GaussianBlur(10)))
    d = ImageDraw.Draw(img)

    # kreski na ścianie – odliczanie dni
    for g in range(4):
        gx = 1720 + g * 105
        for i in range(4):
            d.line([(gx + i * 18, 1300), (gx + i * 18 - 6, 1420)], fill=(52, 55, 70), width=7)
        d.line([(gx - 12, 1400), (gx + 72, 1318)], fill=(52, 55, 70), width=7)

    # piętrowa prycza
    metal = (40, 43, 56)
    for x in (130, 960):
        d.rectangle([x, 1350, x + 34, FLOOR], fill=metal)
    for y in (1600, 2470):
        d.rectangle([130, y, 994, y + 36], fill=metal)
    d.rounded_rectangle([150, 1505, 975, 1600], 20, fill=(33, 36, 50))      # górny materac
    d.rounded_rectangle([150, 2375, 975, 2470], 20, fill=(33, 36, 50))      # dolny materac
    d.polygon([(300, 1600), (620, 1600), (600, 1840), (330, 1820)], fill=(42, 34, 40))  # zwisający koc

    # stół i taboret
    d.rectangle([1000, 2520, 1440, 2560], fill=(46, 40, 36))
    for x in (1020, 1400):
        d.rectangle([x, 2560, x + 22, FLOOR], fill=(36, 32, 29))
    d.rectangle([1560, 2600, 1800, 2630], fill=(40, 37, 34))
    for x in (1580, 1760):
        d.rectangle([x, 2630, x + 18, FLOOR], fill=(32, 29, 27))

    # laptop w 3/4, ekranem do Starego – widać świecącą matrycę z linijkami kodu
    d.polygon([(1040, 2500), (1330, 2500), (1350, 2522), (1060, 2522)], fill=(60, 64, 80))   # podstawa
    d.polygon([(1330, 2502), (1236, 2250), (1268, 2238), (1352, 2498)], fill=(72, 76, 94))   # klapa
    d.polygon([(1322, 2490), (1240, 2262), (1258, 2255), (1338, 2486)], fill=(70, 170, 215))  # matryca
    for k in range(7):
        y = 2275 + k * 30
        x = 1246 + (y - 2262) * 0.36
        d.line([(x + 6, y), (x + 6 + (10 + (k * 7) % 14) * 0.6, y + 4)], fill=(200, 245, 255), width=4)
    # kubek czaju
    d.rounded_rectangle([1360, 2430, 1430, 2520], 10, fill=(150, 60, 55))
    d.arc([1410, 2450, 1460, 2500], -90, 90, fill=(150, 60, 55), width=10)

    # poświata ekranu
    glow = radial((1500, 1500), CYAN, 105, 750)
    img.alpha_composite(glow, (1250 - 750, 2380 - 750))
    # winieta
    yy, xx = np.mgrid[0:BH:4, 0:BW:4]
    dist = np.sqrt(((xx - BW / 2) / (BW / 2)) ** 2 * 0.8 + ((yy - BH * 0.55) / (BH / 2)) ** 2)
    a = (np.clip((dist - 0.55) / 0.7, 0, 1) ** 1.4 * 200).astype(np.uint8)
    vig = Image.new("RGBA", (BW // 4, BH // 4), (0, 0, 0, 0))
    vig.putalpha(Image.fromarray(a, "L"))
    img.alpha_composite(vig.resize((BW, BH), Image.BILINEAR))
    return img


def talk(t, who):
    """Ile otwarte usta (0..1) – ruch szczęki, gdy postać mówi."""
    for a, b in SPEAKING[who]:
        if a <= t < b:
            return abs(math.sin(2 * math.pi * 4.2 * (t - a)))
    return 0.0


def limb(d, pts, width, col):
    d.line(pts, fill=col, width=width, joint="curve")
    for x, y in pts:
        d.ellipse([x - width / 2, y - width / 2, x + width / 2, y + width / 2], fill=col)


def draw_old(d, t, rim):
    """Stary: łysy, masywny, siedzi na dolnej pryczy, patrzy w prawo (na laptop)."""
    o = 10 if rim else 0            # obwódka światła od strony laptopa (z prawej)
    col = CYAN if rim else SIL
    jaw = talk(t, OLD) * 16
    hx, hy = 805 + o, 1850
    d.rounded_rectangle([600 + o, 2020, 900 + o, 2420], 110, fill=col)            # tułów
    d.ellipse([780 + o, 1990, 940 + o, 2150], fill=col)                           # pochylony bark
    d.polygon([(745 + o, 1930), (860 + o, 1930), (890 + o, 2040), (720 + o, 2040)], fill=col)  # kark
    limb(d, [(880 + o, 2080), (985 + o, 2320), (1125 + o, 2475)], 84, col)       # ręka na klawiaturze
    d.rounded_rectangle([800 + o, 2330, 1100 + o, 2445], 55, fill=col)           # udo
    limb(d, [(1065 + o, 2400), (1060 + o, FLOOR - 40)], 70, col)                  # łydka
    d.ellipse([1020 + o, FLOOR - 70, 1150 + o, FLOOR - 5], fill=col)              # but
    d.ellipse([hx - 128, hy - 128, hx + 128, hy + 128], fill=col)                 # głowa
    d.polygon([(hx + 116, hy - 24), (hx + 158, hy + 30), (hx + 114, hy + 42)], fill=col)    # nos
    d.ellipse([hx + 52, hy + 62 + jaw, hx + 136, hy + 128 + jaw], fill=col)       # broda (rusza się)
    d.polygon([(hx - 20, hy + 60), (hx + 110, hy + 70 + jaw), (hx + 60, hy + 125 + jaw), (hx - 40, hy + 110)],
              fill=col)                                                            # żuchwa
    if not rim:
        d.ellipse([hx - 42, hy - 6, hx + 8, hy + 44], fill=(15, 16, 22))          # ucho
        d.arc([hx - 120, hy - 128, hx + 100, hy + 60], 200, 300, fill=(80, 92, 120), width=7)  # łysina w księżycu
        if (t % 3.1) >= 0.12:
            d.ellipse([hx + 70, hy - 20, hx + 88, hy - 4], fill=(180, 240, 255))  # odblask ekranu w oku


def draw_young(d, t, rim):
    """Młody: w czapce, na taborecie, nachyla się w lewo do laptopa."""
    o = -10 if rim else 0           # obwódka od strony laptopa (z lewej)
    col = (95, 180, 225) if rim else SIL
    jaw = talk(t, YOUNG) * 13
    hx, hy = 1565 + o, 2090
    d.rounded_rectangle([1520 + o, 2240, 1790 + o, 2610], 95, fill=col)           # bluza
    d.ellipse([1490 + o, 2220, 1630 + o, 2360], fill=col)                         # bark
    d.polygon([(1525 + o, 2160), (1625 + o, 2160), (1640 + o, 2260), (1510 + o, 2260)], fill=col)  # szyja
    limb(d, [(1560 + o, 2300), (1470 + o, 2440), (1405 + o, 2505)], 66, col)     # ręka do laptopa
    d.rounded_rectangle([1470 + o, 2560, 1720 + o, 2660], 48, fill=col)          # udo
    limb(d, [(1505 + o, 2630), (1500 + o, FLOOR - 40)], 60, col)                  # łydka
    d.ellipse([1430 + o, FLOOR - 64, 1550 + o, FLOOR - 5], fill=col)              # but
    d.ellipse([hx - 106, hy - 106, hx + 106, hy + 106], fill=col)                 # głowa
    d.polygon([(hx - 96, hy - 8), (hx - 134, hy + 34), (hx - 94, hy + 44)], fill=col)      # nos
    d.ellipse([hx - 112, hy + 52 + jaw, hx - 44, hy + 104 + jaw], fill=col)       # broda
    d.polygon([(hx + 20, hy + 55), (hx - 95, hy + 64 + jaw), (hx - 60, hy + 104 + jaw), (hx + 30, hy + 95)],
              fill=col)                                                            # żuchwa
    d.chord([hx - 116, hy - 152, hx + 116, hy + 70], 180, 360, fill=col)          # czapka
    d.rounded_rectangle([hx - 122, hy - 54, hx + 122, hy - 20], 14, fill=col)     # wywinięcie
    if not rim:
        d.rounded_rectangle([hx - 122, hy - 54, hx + 122, hy - 20], 14, fill=(46, 30, 36))
        d.ellipse([hx - 18, hy - 154, hx + 18, hy - 118], fill=(46, 30, 36))      # pompon
        if (t % 2.7) >= 0.12:
            d.ellipse([hx - 72, hy - 6, hx - 56, hy + 10], fill=(160, 225, 250))


def draw_steam(img, t):
    layer = Image.new("RGBA", (220, 380))
    d = ImageDraw.Draw(layer)
    for k in range(3):
        ph = (t * 0.45 + k / 3) % 1
        x0, y0 = 110 + (k - 1) * 22, 340 - ph * 280
        a = int(90 * math.sin(math.pi * ph))
        pts = [(x0 + 16 * math.sin(5 * ph + j * 0.9 + k), y0 - j * 24) for j in range(5)]
        d.line(pts, fill=(200, 210, 225, a), width=10, joint="curve")
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(6)), (1395 - 110, 2430 - 340))


def lerp(a, b, p):
    return a + (b - a) * p


def camera(t):
    for a, b, s0, s1 in SHOTS:
        if a <= t < b:
            p = (t - a) / (b - a)
            p = p * p * (3 - 2 * p)
            return tuple(lerp(x, y, p) for x, y in zip(s0, s1))
    return SHOTS[-1][3]


def render_scene(static, t):
    img = static.copy()
    d = ImageDraw.Draw(img)
    draw_old(d, t, rim=True)
    draw_old(d, t, rim=False)
    draw_young(d, t, rim=True)
    draw_young(d, t, rim=False)
    draw_steam(img, t)
    cx, cy, z = camera(t)
    cw, ch = BW / z, BH / z
    x0 = min(max(0, cx - cw / 2), BW - cw)
    y0 = min(max(0, cy - ch / 2), BH - ch)
    return img.crop((int(x0), int(y0), int(x0 + cw), int(y0 + ch))).resize((W, H), Image.BILINEAR).convert("RGB")


# ───────────────────────── Napisy ─────────────────────────
def caption(canvas, text, color, t_in, y=1470, size=82):
    f = S.font(S.SANS_B, size)
    while f.getlength(text) > 960 and size > 40:
        size -= 4
        f = S.font(S.SANS_B, size)
    tw = f.getlength(text)
    layer = Image.new("RGBA", (int(tw) + 40, int(size * 1.6)))
    ImageDraw.Draw(layer).text((20, size * 0.2), text, font=f, fill=color, stroke_width=7, stroke_fill=(0, 0, 0))
    sl = S.slam(t_in)
    scale = 1.0 if not sl else 1 + (sl[0] - 1) * 0.25   # delikatniejszy wjazd niż w shortcie
    S.paste_center(canvas, layer, y, scale)


def small_text(canvas, text, y, color=S.GREY, size=38, path=None, alpha=1.0, box=False):
    layer = S.fit(text, size, 980, color=color, path=path or S.SANS)
    if box:
        bg = Image.new("RGBA", (layer.width + 40, layer.height + 16), (0, 0, 0, int(170 * alpha)))
        S.paste_center(canvas, bg, y)
    S.paste_center(canvas, layer, y, alpha=alpha)


# ───────────────────────── Ekran laptopa ─────────────────────────
def record_terminal():
    cols, rows, fs = 40, 20, 36
    tmp, env, work = R.setup_world()
    env.update(COLUMNS=str(cols), LINES=str(rows))
    srv = env.pop("_GRYPS_DEMO_SRV")
    subprocess.run(["git", "clone", "-q", "https://github.com/ekipa/projekt.git", "projekt"], cwd=work, env=env,
                   check=True)
    cwd = os.path.join(work, "projekt")
    subprocess.run(["git", "switch", "-qc", "do-ziomka"], cwd=cwd, env=env, check=True)
    with open(os.path.join(cwd, "gryps.txt"), "w") as f:
        f.write("Pozdro z celi 14\n")
    steps = ["gryps skitraj", 'gryps przyklep "Pozdro z celi 14"', "gryps wywozka"]
    rec = R.Recorder(cols=cols, rows=rows, font_size=fs, title="cela 14 — gryps")
    starts, typing = [], []
    elapsed = lambda: sum(ms for _, ms in rec.frames) / 1000  # noqa: E731
    try:
        for cmd in steps:
            rec.feed("\033[1;32m~/projekt\033[0m $ ")
            rec.snapshot(120)
            starts.append(elapsed())
            t0 = elapsed()
            for ch in cmd:
                rec.feed(ch)
                rec.snapshot(30)
            typing.append((t0, elapsed()))
            rec.snapshot(120)
            rec.feed("\r\n")

            def on_out(data):
                rec.feed(data.replace(srv.encode(), b"github.com/ekipa/projekt"))
                rec.snapshot(35, cursor=False)

            R.run_in_pty(cmd, cwd, env, on_out, cols=cols, rows=rows)
            rec.snapshot(350, cursor=False)
    finally:
        import shutil
        shutil.rmtree(tmp, ignore_errors=True)
    times, acc = [], 0.0
    for _, ms in rec.frames:
        times.append(acc)
        acc += ms / 1000
    return rec.frames, times, acc, starts, typing


def make_screen_shot(frames, times, total_rec, starts):
    import bisect
    dur = T_END - T_DROP
    hold = 0.75
    speed = total_rec / (dur - hold)       # przyspieszenie nagrania, żeby zmieściło się w ujęciu
    term0 = frames[0][0]
    tw, th = term0.width, term0.height
    bez = Image.new("RGBA", (tw + 60, th + 60))
    ImageDraw.Draw(bez).rounded_rectangle([0, 0, tw + 59, th + 59], 34, fill=(38, 40, 52))
    glow = radial((W, H), CYAN, 60, 900)
    ty = 250
    lines = [(starts[0] / speed, "Skitrasz…"), (starts[1] / speed, "przyklepiesz…"),
             (starts[2] / speed, "i gryps idzie na wolność.")]

    def draw(c, t):
        rt = min(t * speed, total_rec)
        i = max(0, bisect.bisect_right(times, rt) - 1)
        c.paste(Image.new("RGB", (W, H), (8, 9, 13)))
        c.paste(glow, (0, 0), glow)
        zoom = 1 + 0.04 * (t / dur)
        term = frames[i][0]
        b = bez
        if zoom != 1:
            term = term.resize((int(tw * zoom), int(th * zoom)), Image.BILINEAR)
            b = bez.resize((int(bez.width * zoom), int(bez.height * zoom)), Image.BILINEAR)
        c.paste(b, ((W - b.width) // 2, ty - int(30 * zoom)), b)
        c.paste(term, ((W - term.width) // 2, ty))
        for k, (st, txt) in enumerate(lines):
            nxt = lines[k + 1][0] if k + 1 < len(lines) else dur
            if st <= t < nxt:
                caption(c, txt, OLD, t - st, y=1590)
    return draw, speed


# ───────────────────────── Plansza końcowa ─────────────────────────
def end_card(c, t):
    c.paste(S.BACKGROUND)
    banner = ["  ____ ______   ______  ____", " / ___|  _ \\ \\ / /  _ \\/ ___|",
              "| |  _| |_) \\ V /| |_) \\___ \\", "| |_| |  _ < | | |  __/ ___) |",
              " \\____|_| \\_\\|_| |_|   |____/"]
    sl = S.slam(t)
    if sl:
        f = S.font(S.MONO_B, 46)
        layer = Image.new("RGBA", (int(f.getlength(banner[2])) + 10, 60 * len(banner)))
        d = ImageDraw.Draw(layer)
        for i, line in enumerate(banner):
            d.text((5, i * 58), line, font=f, fill=S.RED)
        S.paste_center(c, layer, 640, *sl)
    items = [
        (0.25, S.fit("Git w grypserze", 92, 980, color=S.WHITE), 900),
        (0.55, S.fit("skitraj · przyklep · wywozka · kipisz", 44, 980, color=S.GREY, path=S.MONO_B), 1010),
        (0.85, S.fit(f"github.com/{S.GH_USER}/gryps" if S.GH_USER else "link w bio 🔗", 66, 980,
                     color=S.YELLOW, path=S.MONO_B), 1150),
        (1.15, S.fit("⭐ w celi każda paczka się liczy", 48, 980, color=S.WHITE, path=S.SANS), 1265),
    ]
    for start, layer, y in items:
        sl = S.slam(t - start)
        if sl:
            S.paste_center(c, layer, y, *sl)


# ───────────────────────── Dźwięk ─────────────────────────
def make_audio(path, cues, typing):
    sr = 44100
    n = int(TOTAL * sr)
    out = np.zeros(n)
    rng = np.random.default_rng(11)

    def add(sig, at, gain=1.0):
        i = int(at * sr)
        if i >= n:
            return
        j = min(n, i + len(sig))
        out[i:j] += sig[: j - i] * gain

    def env_t(sec):
        return np.arange(int(sec * sr)) / sr

    # cisza celi: brzęczenie świetlówki 50 Hz + szum
    t = np.arange(int(T_DROP * sr)) / sr
    room = 0.025 * np.sin(2 * np.pi * 50 * t) + 0.012 * np.sin(2 * np.pi * 100 * t)
    room += np.convolve(rng.standard_normal(len(t)), np.ones(40) / 40, "same") * 0.05
    add(room, 0)
    # trzask zamykanych drzwi celi na początek
    tc = env_t(1.6)
    clang = sum(np.sin(2 * np.pi * f * tc) * np.exp(-tc * dk) * g
                for f, dk, g in [(118, 3.5, 0.6), (231, 4, 0.5), (567, 6, 0.35), (933, 8, 0.25), (1471, 11, 0.2)])
    clang += rng.standard_normal(len(tc)) * np.exp(-tc * 40) * 0.6
    for k, (dl, g) in enumerate([(0, 1.0), (0.09, 0.35), (0.21, 0.2)]):
        add(clang, 0.05 + dl, g * 0.9)
    # „tyk” przy każdej kwestii
    tt = env_t(0.05)
    tick = np.sin(2 * np.pi * 1400 * tt) * np.exp(-tt * 120) * 0.25
    for at in cues:
        add(tick, at)
    # BIT od T_DROP
    tk = env_t(0.35)
    kick = np.sin(2 * np.pi * (45 + 90 * np.exp(-tk * 30)) * tk) * np.exp(-tk * 9)
    ts = env_t(0.22)
    snare = (rng.standard_normal(len(ts)) * 0.6 + np.sin(2 * np.pi * 190 * ts)) * np.exp(-ts * 18) * 0.5
    th = env_t(0.05)
    hat = np.diff(rng.standard_normal(len(th)) * np.exp(-th * 90) * 0.18, prepend=0) * 3
    tb = env_t(0.8)
    boom = np.sin(2 * np.pi * (32 + 70 * np.exp(-tb * 10)) * tb) * np.exp(-tb * 4) * 1.2
    beat = 60 / 100
    b, k = T_DROP, 0
    while b < TOTAL - 0.1:
        if k % 4 in (0, 2) or k % 8 == 7:
            add(kick, b, 0.8)
        if k % 4 in (1, 3):
            add(snare, b)
        add(hat, b)
        add(hat, b + beat / 2, 0.6)
        b += beat
        k += 1
    add(boom, T_DROP)
    add(boom, T_END, 0.9)
    # stukanie klawiatury
    tkb = env_t(0.025)
    click = np.diff(rng.standard_normal(len(tkb)) * np.exp(-tkb * 200), prepend=0) * 0.35
    for a, z in typing:
        x = a
        while x < z:
            add(click, x, 0.6 + 0.4 * rng.random())
            x += 0.045 + 0.02 * rng.random()
    fade = int(0.5 * sr)
    out[-fade:] *= np.linspace(1, 0, fade)
    out = out / np.abs(out).max() * 0.88
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((out * 32767).astype(np.int16).tobytes())


# ───────────────────────── Składanie ─────────────────────────
def main():
    if not os.access(R.GRYPS, os.X_OK):
        sys.exit(f"Brak {R.GRYPS} – odpal najpierw: make build")
    print("🎥 Nagrywam prawdziwą sesję na laptopie...")
    frames, times, total_rec, starts, typing_rec = record_terminal()
    screen, speed = make_screen_shot(frames, times, total_rec, starts)
    print("🧱 Stawiam celę...")
    static = build_static()

    typing = [(T_DROP + a / speed, T_DROP + b / speed) for a, b in typing_rec]
    cues = [a for a, *_ in LINES] + [T_DROP + s / speed for s in starts]

    os.makedirs(os.path.dirname(OUT) or ".", exist_ok=True)
    cover = None
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "dzwiek.wav")
        make_audio(wav, cues, typing)
        print(f"🎬 Renderuję {TOTAL:.0f} s...")
        ff = subprocess.Popen(
            ["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
             "-r", str(FPS), "-i", "-", "-i", wav, "-c:v", "libx264", "-preset", "medium", "-crf", "18",
             "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", OUT],
            stdin=subprocess.PIPE)
        for fi in range(int(TOTAL * FPS)):
            t = fi / FPS
            if t < T_DROP:
                c = render_scene(static, t)
                if t < 1.7:   # podpis miejsca, pisany jak na maszynie
                    txt = "Areszt Śledczy, cela 14, 23:47"
                    n = int(len(txt) * min(1, (t - 0.3) / 0.9)) if t > 0.3 else 0
                    if n:
                        small_text(c, txt[:n], 230, color=(190, 196, 215), size=40, path=S.MONO_B)
                for a, b, who, txt in LINES:
                    if a <= t < b:
                        caption(c, txt, who, t - a)
                fa, fb, ftxt = FOOTNOTE
                if fa <= t < fb:
                    small_text(c, ftxt, 1585, color=(205, 210, 225), alpha=min(1, (t - fa) / 0.2), box=True)
            elif t < T_END:
                c = Image.new("RGB", (W, H))
                screen(c, t - T_DROP)
            else:
                c = Image.new("RGB", (W, H))
                end_card(c, t - T_END)
            if cover is None and t >= 4.6:
                cover = c.copy()
            ff.stdin.write(c.tobytes())
        ff.stdin.close()
        if ff.wait() != 0:
            sys.exit("ffmpeg się wywalił")
    cover_path = os.path.splitext(OUT)[0] + "-okladka.png"
    cover.save(cover_path)
    print(f"✅ {OUT} ({TOTAL:.0f} s, {os.path.getsize(OUT) / 1e6:.1f} MB) + okładka {cover_path}")


if __name__ == "__main__":
    main()
