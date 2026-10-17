#!/usr/bin/env python3
"""
Pionowy short reklamowy (1080×1920, 30 fps) na TikToka / YouTube Shorts / Reels.

    make promo                              # z katalogu głównego repo
    python3 docs/promo/short.py [plik.mp4]

Scena z terminalem to prawdziwa sesja grypsa (renderer z docs/demo/render.py).
Podkład to prosty bit syntezowany w kodzie – zero cudzej muzyki, zero problemów
z prawami. W aplikacji możesz go podmienić na popularny dźwięk.

Wymagania: python3, pip install pyte pillow numpy, ffmpeg (z libx264), git,
fonty DejaVu i Noto Color Emoji. Opcjonalnie GH_USER=login – pokaże link w napisach.
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "docs", "demo"))
import render as R  # noqa: E402

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "dist", "gryps-short.mp4")
W, H, FPS = 1080, 1920, 30
BPM = 100
BEAT = 60 / BPM
GH_USER = os.environ.get("GH_USER", "")

BG = (13, 14, 20)
YELLOW, RED, GREEN = (255, 210, 127), (247, 118, 142), (158, 206, 106)
GREY, WHITE, DIM = (125, 130, 155), (236, 238, 245), (70, 74, 96)

SANS_B = R.find_font("DejaVuSans-Bold.ttf")
SANS = R.find_font("DejaVuSans.ttf")
MONO_B = R.find_font("DejaVuSansMono-Bold.ttf")
EMOJI = R.find_font("NotoColorEmoji.ttf")
_fonts, _emoji_cache = {}, {}


def font(path, size):
    key = (path, size)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(path, size)
    return _fonts[key]


def emoji_img(ch, size):
    key = (ch, size)
    if key not in _emoji_cache:
        big = Image.new("RGBA", (160, 160))
        ImageDraw.Draw(big).text((0, 0), ch, font=ImageFont.truetype(EMOJI, 109), embedded_color=True)
        _emoji_cache[key] = big.crop(big.getbbox()).resize((size, size), Image.LANCZOS)
    return _emoji_cache[key]


# ── Tło: ciemno, a w tle kraty ──
def make_background():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    for y in range(H):  # delikatny gradient od góry
        v = int(8 * (1 - y / H))
        d.line([(0, y), (W, y)], fill=(BG[0] + v, BG[1] + v, BG[2] + v + 4))
    for x in range(60, W, 120):  # pionowe pręty
        d.rectangle([x, 0, x + 10, H], fill=(22, 24, 33))
        d.rectangle([x + 2, 0, x + 4, H], fill=(28, 30, 41))
    d.rectangle([0, 210, W, 226], fill=(22, 24, 33))
    d.rectangle([0, H - 300, W, H - 284], fill=(22, 24, 33))
    return img


BACKGROUND = make_background()


def text_layer(text, size, color, path=SANS_B, strike=False):
    """Napis jako przezroczysta warstwa; emoji wstawiane z Noto Color Emoji."""
    f = font(path, size)
    runs, buf = [], ""
    for c in text:
        if R.is_emoji(c):
            if buf:
                runs.append(("t", buf))
                buf = ""
            runs.append(("e", c))
        elif c != "️":
            buf += c
    if buf:
        runs.append(("t", buf))
    widths = [f.getlength(r) if k == "t" else size * 1.15 for k, r in runs]
    w, h = int(sum(widths)) + 8, int(size * 1.35)
    layer = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(layer)
    x = 4
    for (k, r), rw in zip(runs, widths):
        if k == "t":
            d.text((x, size * 0.12), r, font=f, fill=color)
        else:
            e = emoji_img(r, size)
            layer.paste(e, (int(x + size * 0.08), int(size * 0.18)), e)
        x += rw
    if strike:
        y = int(h * 0.55)
        d.rectangle([0, y - size // 14, w, y + size // 14], fill=RED)
    return layer


def paste_center(canvas, layer, cy, scale=1.0, alpha=1.0, cx=W // 2):
    if scale != 1.0:
        layer = layer.resize((max(1, int(layer.width * scale)), max(1, int(layer.height * scale))), Image.BICUBIC)
    if alpha < 1.0:
        a = layer.getchannel("A").point(lambda v: int(v * alpha))
        layer = layer.copy()
        layer.putalpha(a)
    canvas.paste(layer, (int(cx - layer.width / 2), int(cy - layer.height / 2)), layer)


def slam(t):
    """Wjazd z uderzeniem: skala 1.6→1.0 i pojawienie się w ~0.2 s."""
    if t < 0:
        return None
    p = min(1.0, t / 0.18)
    ease = 1 - (1 - p) ** 3
    return 1.6 - 0.6 * ease, min(1.0, p * 1.4)


def fit(text, size, maxw, **kw):
    """Zmniejsza czcionkę, aż napis zmieści się w szerokości."""
    while size > 20:
        layer = text_layer(text, size, **kw)
        if layer.width <= maxw:
            return layer
        size -= 4
    return text_layer(text, size, **kw)


# ── Sceny: (start, koniec, funkcja rysująca(canvas, t_lokalny)) ──
def scene_hook(c, t):
    items = [
        (0.0, fit("„GIT”", 300, 980, color=YELLOW), 760),
        (BEAT, fit("to słowo z grypsery", 84, 980, color=WHITE), 980),
        (BEAT * 2, fit("git-człowiek = grypsujący", 46, 980, color=GREY, path=SANS), 1080),
        (BEAT * 3, fit("więc Git dostał gwarę 🔒", 70, 980, color=WHITE), 1300),
    ]
    for start, layer, y in items:
        s = slam(t - start)
        if s:
            paste_center(c, layer, y, *s)


CARDS = [
    ("git add", "gryps skitrac", "skitrać = schować", None),
    ("git commit -m", "gryps przyklep", "przyklepanie = dowód w papierach", None),
    ("git push", "gryps wywozka", "towar jedzie na serwer", "🚐"),
    ("git pull", "gryps rakieta", "rakieta = paczka z wolki", "📦"),
    ("git reset --hard", "gryps kipisz", "kipisz = rewizja", "🚨"),
]
CARD_LEN = BEAT * 3


def scene_cards(c, t):
    i = min(int(t / CARD_LEN), len(CARDS) - 1)
    lt = t - i * CARD_LEN
    old, new, gloss, emo = CARDS[i]
    paste_center(c, fit(f"{i + 1}/{len(CARDS)}", 40, 600, color=DIM, path=MONO_B), 480)
    paste_center(c, fit(old, 92, 940, color=GREY, path=MONO_B, strike=lt > 0.25), 800)
    s = slam(lt - 0.3)
    if s:
        paste_center(c, fit("↓", 90, 300, color=DIM), 930, alpha=s[1])
        label = new + (f" {emo}" if emo else "")
        paste_center(c, fit(label, 104, 1000, color=YELLOW, path=MONO_B), 1070, *s)
    s2 = slam(lt - 0.75)
    if s2:
        paste_center(c, fit(gloss, 52, 980, color=WHITE, path=SANS), 1220, alpha=s2[1])


def record_terminal():
    """Prawdziwa sesja grypsa w terminalu na szerokość telefonu."""
    cols, rows, fs = 42, 19, 36
    tmp, env, work = R.setup_world()
    env.update(COLUMNS=str(cols), LINES=str(rows))
    srv = env.pop("_GRYPS_DEMO_SRV")
    subprocess.run(["git", "clone", "-q", "https://github.com/ekipa/projekt.git", "projekt"],
                   cwd=work, env=env, check=True)
    cwd = os.path.join(work, "projekt")
    subprocess.run(["git", "switch", "-qc", "nowa-robota"], cwd=cwd, env=env, check=True)
    with open(os.path.join(cwd, "drzwi.txt"), "a") as f:
        f.write("zamek: naprawiony\n")
    steps = [
        ("gryps skitrac", 700, None),
        ('gryps przyklep "Zamek naprawiony"', 900, None),
        ("gryps wywozka", 1700, None),
        ("echo syf >> drzwi.txt", 150, None),
        ("gryps kipisz", 2600, "t"),
    ]
    rec = R.Recorder(cols=cols, rows=rows, font_size=fs, title="gryps")
    ps = "\033[1;32m~/projekt\033[0m $ "
    try:
        for cmd, hold, answer in steps:
            rec.feed(ps)
            rec.snapshot(250)
            for ch in cmd:
                rec.feed(ch)
                rec.snapshot(28)
            rec.snapshot(200)
            rec.feed("\r\n")

            def on_out(data):
                rec.feed(data.replace(srv.encode(), b"github.com/ekipa/projekt"))
                rec.snapshot(50, cursor=False)

            R.run_in_pty(cmd, cwd, env, on_out, answer, lambda _: rec.snapshot(900), cols=cols, rows=rows)
            rec.snapshot(hold, cursor=False)
    finally:
        import shutil
        shutil.rmtree(tmp, ignore_errors=True)
    times, acc = [], 0.0
    for img, ms in rec.frames:
        times.append(acc)
        acc += ms / 1000
    return rec.frames, times, acc


def make_scene_terminal(frames, times):
    import bisect
    label = fit("a tak to działa naprawdę 👇", 60, 980, color=WHITE)
    cache = {}

    def draw(c, t):
        i = max(0, bisect.bisect_right(times, t) - 1)
        if i not in cache:
            cache[i] = frames[i][0]
        term = cache[i]
        paste_center(c, label, 300)
        y = 400
        c.paste(term, ((W - term.width) // 2, y))
        ImageDraw.Draw(c).rectangle([(W - term.width) // 2 - 3, y - 3, (W + term.width) // 2 + 2,
                                     y + term.height + 2], outline=(60, 64, 86), width=3)
    return draw


def scene_cta(c, t):
    logo = R.find_font("DejaVuSansMono-Bold.ttf")
    banner = ["  ____ ______   ______  ____", " / ___|  _ \\ \\ / /  _ \\/ ___|",
              "| |  _| |_) \\ V /| |_) \\___ \\", "| |_| |  _ < | | |  __/ ___) |",
              " \\____|_| \\_\\|_| |_|   |____/"]
    s = slam(t)
    if s:
        f = font(logo, 46)
        layer = Image.new("RGBA", (int(f.getlength(banner[2])) + 10, 60 * len(banner)))
        d = ImageDraw.Draw(layer)
        for i, line in enumerate(banner):
            d.text((5, i * 58), line, font=f, fill=RED)
        paste_center(c, layer, 600, *s)
    items = [
        (BEAT, fit("Git w grypserze", 88, 980, color=WHITE), 880),
        (BEAT * 2, fit("open source • MIT • Linux i macOS", 44, 980, color=GREY, path=SANS), 980),
        (BEAT * 3, fit(f"github.com/{GH_USER}/gryps" if GH_USER else "link w bio 🔗", 64, 980, color=YELLOW,
                       path=MONO_B), 1120),
        (BEAT * 4, fit("⭐ w celi każda paczka się liczy", 50, 980, color=WHITE, path=SANS), 1240),
    ]
    for start, layer, y in items:
        s = slam(t - start)
        if s:
            paste_center(c, layer, y, *s)


# ── Dźwięk: prosty bit 100 BPM + „łup” przy każdym wjeździe ──
def make_audio(path, total, hits):
    sr = 44100
    n = int(total * sr) + sr
    out = np.zeros(n)
    rng = np.random.default_rng(7)

    def add(sig, at):
        i = int(at * sr)
        j = min(n, i + len(sig))
        out[i:j] += sig[: j - i]

    t = np.arange(int(0.35 * sr)) / sr
    kick = np.sin(2 * np.pi * (45 + 90 * np.exp(-t * 30)) * t) * np.exp(-t * 9)
    tn = np.arange(int(0.22 * sr)) / sr
    snare = (rng.standard_normal(len(tn)) * 0.6 + np.sin(2 * np.pi * 190 * tn)) * np.exp(-tn * 18) * 0.5
    th = np.arange(int(0.05 * sr)) / sr
    hat = rng.standard_normal(len(th)) * np.exp(-th * 90) * 0.18
    hat = np.diff(hat, prepend=0) * 3  # jaśniej
    tb = np.arange(int(0.5 * sr)) / sr
    boom = np.sin(2 * np.pi * (35 + 60 * np.exp(-tb * 12)) * tb) * np.exp(-tb * 5) * 0.9

    beat, k = 0.0, 0
    while beat < total - 0.05:
        if k % 4 in (0, 2) or (k % 8 == 7):
            add(kick * 0.8, beat)
        if k % 4 in (1, 3):
            add(snare, beat)
        add(hat, beat)
        add(hat * 0.6, beat + BEAT / 2)
        beat += BEAT
        k += 1
    for h in hits:
        add(boom, h)
    out = out[: int(total * sr)]
    fade = int(0.6 * sr)
    out[-fade:] *= np.linspace(1, 0, fade)
    out = out / max(1e-9, np.abs(out).max()) * 0.85
    pcm = (out * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def main():
    if not os.access(R.GRYPS, os.X_OK):
        sys.exit(f"Brak {R.GRYPS} – odpal najpierw: make build")
    print("🎥 Nagrywam prawdziwą sesję w terminalu...")
    frames, times, term_len = record_terminal()

    hook_len = BEAT * 5
    cards_len = CARD_LEN * len(CARDS)
    cta_len = BEAT * 7
    scenes, t0 = [], 0.0
    for length, fn in [(hook_len, scene_hook), (cards_len, scene_cards),
                       (term_len, make_scene_terminal(frames, times)), (cta_len, scene_cta)]:
        scenes.append((t0, t0 + length, fn))
        t0 += length
    total = t0
    hits = [0, BEAT * 3] + [hook_len + i * CARD_LEN + 0.3 for i in range(len(CARDS))] + \
           [hook_len + cards_len, hook_len + cards_len + term_len]

    os.makedirs(os.path.dirname(OUT) or ".", exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "bit.wav")
        make_audio(wav, total, hits)
        print(f"🎬 Renderuję {total:.1f} s wideo...")
        ff = subprocess.Popen(
            ["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
             "-r", str(FPS), "-i", "-", "-i", wav, "-c:v", "libx264", "-preset", "medium", "-crf", "19",
             "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", OUT],
            stdin=subprocess.PIPE)
        cover = None
        for fi in range(int(total * FPS)):
            t = fi / FPS
            canvas = BACKGROUND.copy()
            for start, end, fn in scenes:
                if start <= t < end:
                    fn(canvas, t - start)
                    break
            ff.stdin.write(canvas.tobytes())
            if cover is None and t >= BEAT * 3.6:
                cover = canvas
        ff.stdin.close()
        if ff.wait() != 0:
            sys.exit("ffmpeg się wywalił")
    cover_path = os.path.splitext(OUT)[0] + "-okladka.png"
    cover.save(cover_path)
    print(f"✅ {OUT} ({total:.1f} s, {os.path.getsize(OUT) / 1e6:.1f} MB) + okładka {cover_path}")


if __name__ == "__main__":
    main()
