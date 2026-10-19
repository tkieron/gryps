#!/usr/bin/env python3
"""
Renderuje docs/demo.gif: odpala PRAWDZIWE komendy grypsa w pseudo-terminalu,
odtwarza ekran emulatorem (pyte) i rysuje klatki (Pillow).

    make demo                      # z katalogu głównego repo
    python3 docs/demo/render.py [plik.gif]

Wymagania: python3, pip install pyte pillow, git, fonty DejaVu Sans Mono
(+ opcjonalnie Noto Color Emoji – bez niego emoji zostaną pominięte).
"""
import fcntl
import hashlib
import os
import pty
import select
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time

import pyte
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "demo.gif")
GRYPS = os.environ.get("GRYPS", os.path.join(ROOT, "dist", "gryps"))

COLS, ROWS = 86, 24
FONT_SIZE = 15

# ── Scenariusz: (komenda, ile ms trzymać ekran po wykonaniu, odpowiedź na pytanie) ──
STEPS = [
    ("gryps jumaj https://github.com/ekipa/projekt.git", 1000, None),
    ("cd projekt", 150, None),
    ("gryps przerzutka -c nowa-robota", 900, None),
    ("echo 'zamek: naprawiony' >> drzwi.txt", 250, None),
    ("gryps lipo -s", 1300, None),
    ("gryps skitraj", 900, None),
    ('gryps przyklep "Naprawiony zamek w drzwiach"', 1100, None),
    ("gryps wywozka", 2400, None),
    ("clear", 0, None),
    ("gryps bialko", 2200, None),
    ("echo 'syf na biurku' >> drzwi.txt", 250, None),
    ("gryps kipisz", 3500, "t"),
]
TYPE_MS = 30          # pisanie jednego znaku
THINK_MS = 350        # pauza przed pisaniem komendy

# ── Wygląd ──
BG, FG = "#15161e", "#d6d8e0"
TITLEBAR = "#22232e"
PALETTE = {  # zwykły, jasny (bold)
    "black": ("#3b3e51", "#5c6080"), "red": ("#f7768e", "#ff8fa3"),
    "green": ("#9ece6a", "#b5e48c"), "brown": ("#e0af68", "#ffd27f"),
    "blue": ("#7aa2f7", "#9bb8ff"), "magenta": ("#bb9af7", "#d4bbff"),
    "cyan": ("#7dcfff", "#a6e0ff"), "white": ("#c0caf5", "#ffffff"),
}
TITLE = "gryps — system kontroli wersji dla prawilnych ludzi"

FONT_DIRS = ["/usr/share/fonts", "/usr/local/share/fonts", os.path.expanduser("~/.local/share/fonts"),
             "/Library/Fonts", "/System/Library/Fonts", os.path.expanduser("~/Library/Fonts")]


def find_font(name):
    for base in FONT_DIRS:
        for dirpath, _, files in os.walk(base):
            if name in files:
                return os.path.join(dirpath, name)
    return None


def load_fonts(size=FONT_SIZE):
    reg = find_font("DejaVuSansMono.ttf")
    bold = find_font("DejaVuSansMono-Bold.ttf") or reg
    if not reg:
        sys.exit("Brak fontu DejaVu Sans Mono (Debian/Ubuntu: apt install fonts-dejavu-core)")
    emoji_path = find_font("NotoColorEmoji.ttf")
    emoji = ImageFont.truetype(emoji_path, 109) if emoji_path else None
    if not emoji:
        print("⚠️  Brak Noto Color Emoji – emoji zostaną pominięte (apt install fonts-noto-color-emoji)")
    return ImageFont.truetype(reg, size), ImageFont.truetype(bold, size), emoji


def is_emoji(text):
    return any(ord(c) >= 0x1F000 or 0x2600 <= ord(c) <= 0x27BF or 0x2B00 <= ord(c) <= 0x2BFF
               or 0x231A <= ord(c) <= 0x23FF for c in text)


# ── Przygotowanie świata: HOME, „serwer” i git ──
def setup_world():
    tmp = tempfile.mkdtemp(prefix="gryps-demo-")
    home = os.path.join(tmp, "home")
    srv = os.path.join(tmp, "serwer", "projekt.git")
    seed = os.path.join(tmp, "seed")
    os.makedirs(home)
    env = dict(os.environ, HOME=home, GIT_CONFIG_NOSYSTEM="1", LANG="C.UTF-8", LC_ALL="C.UTF-8",
               TERM="xterm-256color", COLUMNS=str(COLS), LINES=str(ROWS), GIT_PAGER="cat")
    env.pop("NO_COLOR", None)
    bindir = os.path.join(tmp, "bin")
    os.makedirs(bindir)
    os.symlink(GRYPS, os.path.join(bindir, "gryps"))
    env["PATH"] = bindir + os.pathsep + env["PATH"]

    def git(*args, cwd=None):
        subprocess.run(["git", *args], cwd=cwd, env=env, check=True, capture_output=True)

    git("config", "--global", "user.name", "Ziomal")
    git("config", "--global", "user.email", "ziomal@cela.pl")
    git("config", "--global", "init.defaultBranch", "main")
    git("config", "--global", "advice.detachedHead", "false")
    # Adres z demo wygląda jak GitHub, a naprawdę jedzie do lokalnego „serwera”
    git("config", "--global", f"url.{srv}.insteadOf", "https://github.com/ekipa/projekt.git")
    git("init", "-q", "--bare", srv)
    git("clone", "-q", srv, seed)
    with open(os.path.join(seed, "drzwi.txt"), "w") as f:
        f.write("zamek: zepsuty\n")
    with open(os.path.join(seed, "README.md"), "w") as f:
        f.write("# Projekt\n")
    git("add", "-A", cwd=seed)
    git("commit", "-qm", "Początek odsiadki", cwd=seed)
    with open(os.path.join(seed, "krata.txt"), "w") as f:
        f.write("krata: solidna\n")
    git("add", "-A", cwd=seed)
    git("commit", "-qm", "Wzmocniona krata", cwd=seed)
    git("push", "-q", "origin", "main", cwd=seed)
    work = os.path.join(home, "robota")
    os.makedirs(work)
    env["_GRYPS_DEMO_SRV"] = srv
    return tmp, env, work


def run_in_pty(cmd, cwd, env, on_output, answer=None, on_answer=None, cols=COLS, rows=ROWS):
    """Odpala komendę w pseudo-terminalu o rozmiarze COLS×ROWS i przekazuje wyjście."""
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
    proc = subprocess.Popen(["bash", "-c", cmd], cwd=cwd, env=env, stdin=slave, stdout=slave,
                            stderr=slave, close_fds=True, start_new_session=True)
    os.close(slave)
    seen = b""
    answered = answer is None
    while True:
        r, _, _ = select.select([master], [], [], 0.05)
        if r:
            try:
                data = os.read(master, 4096)
            except OSError:
                break
            if not data:
                break
            seen += data
            on_output(data)
            if not answered and b"[t/N]" in seen:
                time.sleep(0.1)
                on_answer(answer)
                os.write(master, (answer + "\n").encode())
                answered = True
        elif proc.poll() is not None:
            break
    proc.wait()
    os.close(master)


class Recorder:
    def __init__(self, cols=COLS, rows=ROWS, font_size=FONT_SIZE, title=TITLE):
        self.cols, self.rows, self.fs, self.title = cols, rows, font_size, title
        self.screen = pyte.Screen(cols, rows)
        self.stream = pyte.ByteStream(self.screen)
        self.font, self.bold, self.emoji = load_fonts(font_size)
        self.cw = round(self.font.getlength("M"))
        self.ch = round(font_size * 1.42)
        self.pad = round(font_size * 1.2)
        self.title_h = round(font_size * 2.25)
        self.w = self.pad * 2 + cols * self.cw
        self.h = self.title_h + self.pad * 2 + rows * self.ch
        self.frames = []   # [obraz, ms]
        self.emoji_cache = {}
        self.chrome = self._chrome()

    def _chrome(self):
        img = Image.new("RGB", (self.w, self.h), BG)
        d = ImageDraw.Draw(img)
        th, r = self.title_h, max(6, round(self.fs * 0.4))
        d.rectangle([0, 0, self.w, th], fill=TITLEBAR)
        for i, col in enumerate(["#ff5f57", "#febc2e", "#28c840"]):
            x = self.pad + r + i * (r * 3 + 2)
            d.ellipse([x - r, th // 2 - r, x + r, th // 2 + r], fill=col)
        tw = self.font.getlength(self.title)
        d.text(((self.w - tw) / 2, (th - self.fs) / 2 - 1), self.title, font=self.font, fill="#8a8fa8")
        return img

    def feed(self, data):
        data = data if isinstance(data, bytes) else data.encode()
        # pyte gubi resztę linii po selektorze wariantu U+FE0F (np. 👁️), więc go wycinamy
        self.stream.feed(data.replace(b"\xef\xb8\x8f", b""))

    def _emoji(self, text):
        key = text.replace("\ufe0f", "")
        if key not in self.emoji_cache:
            big = Image.new("RGBA", (160, 160))
            ImageDraw.Draw(big).text((0, 0), key, font=self.emoji, embedded_color=True)
            bbox = big.getbbox()
            img = big.crop(bbox) if bbox else big
            size = self.ch - max(3, self.fs // 5)
            img = img.resize((size, size), Image.LANCZOS)
            self.emoji_cache[key] = img
        return self.emoji_cache[key]

    def _color(self, name, bold, default):
        if name == "default":
            return default
        if name in PALETTE:
            return PALETTE[name][1 if bold else 0]
        if len(name) == 6:
            return "#" + name
        return default

    def snapshot(self, ms, cursor=True):
        img = self.chrome.copy()
        d = ImageDraw.Draw(img)
        top = self.title_h + self.pad
        for y in range(self.rows):
            line = self.screen.buffer[y]
            x = 0
            while x < self.cols:
                ch = line[x]
                fg = self._color(ch.fg, ch.bold, FG)
                bg = self._color(ch.bg, False, None)
                if ch.reverse:
                    fg, bg = (bg or BG), fg
                px, py = self.pad + x * self.cw, top + y * self.ch
                wide = x + 1 < self.cols and line[x + 1].data == ""
                cells = 2 if wide else 1
                if bg:
                    d.rectangle([px, py, px + cells * self.cw - 1, py + self.ch - 1], fill=bg)
                if ch.data and ch.data != " ":
                    if is_emoji(ch.data):
                        if self.emoji:
                            e = self._emoji(ch.data)
                            ex = px + (cells * self.cw - e.width) // 2 if wide else px
                            img.paste(e, (ex, py + 1), e)
                    else:
                        d.text((px, py + 2), ch.data, font=self.bold if ch.bold else self.font, fill=fg)
                x += cells
        if cursor and not self.screen.cursor.hidden:
            cx, cy = self.screen.cursor.x, self.screen.cursor.y
            px, py = self.pad + cx * self.cw, top + cy * self.ch
            d.rectangle([px, py + 1, px + self.cw - 1, py + self.ch - 2], fill="#c0caf5")
        if self.frames and self._same(img, self.frames[-1][0]):
            self.frames[-1][1] += ms
        else:
            self.frames.append([img, ms])

    @staticmethod
    def _same(a, b):
        return hashlib.md5(a.tobytes()).digest() == hashlib.md5(b.tobytes()).digest()

    def type_text(self, text):
        for c in text:
            self.feed(c)
            self.snapshot(TYPE_MS)


def prompt(cwd, home):
    short = "~" + cwd[len(home):] if cwd.startswith(home) else cwd
    return f"\033[1;32mziomal@cela\033[0m:\033[1;34m{short}\033[0m$ "


def main():
    if not os.access(GRYPS, os.X_OK):
        sys.exit(f"Brak {GRYPS} – odpal najpierw: make build")
    tmp, env, cwd = setup_world()
    home = env["HOME"]
    rec = Recorder()
    try:
        for cmd, hold, answer in STEPS:
            rec.feed(prompt(cwd, home))
            rec.snapshot(THINK_MS)
            rec.type_text(cmd)
            rec.snapshot(250)
            rec.feed("\r\n")
            if cmd.startswith("cd "):
                cwd = os.path.normpath(os.path.join(cwd, cmd[3:].strip()))
            else:
                def on_out(data):
                    # git wypisuje lokalną ścieżkę „serwera” – w demo pokazujemy adres z komendy
                    rec.feed(data.replace(env["_GRYPS_DEMO_SRV"].encode(), b"https://github.com/ekipa/projekt.git"))
                    rec.snapshot(60, cursor=False)

                def on_answer(_):
                    rec.snapshot(1100)  # chwila namysłu, echo odpowiedzi zrobi terminal

                run_in_pty(cmd, cwd, env, on_out, answer, on_answer)
            rec.snapshot(hold, cursor=False)
        rec.feed(prompt(cwd, home))
        rec.snapshot(1800)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    os.makedirs(os.path.dirname(OUT) or ".", exist_ok=True)
    imgs = [f[0] for f in rec.frames]
    durs = [max(20, int(f[1])) for f in rec.frames]
    pal = imgs[-1].quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    frames = [im.quantize(palette=pal, dither=Image.Dither.NONE) for im in imgs]
    frames[0].save(OUT, save_all=True, append_images=frames[1:], duration=durs, loop=0, optimize=True)
    total = sum(durs) / 1000
    print(f"✅ {OUT}: {len(frames)} klatek, {total:.1f} s, {os.path.getsize(OUT) / 1024:.0f} KB, {rec.w}×{rec.h}px")


if __name__ == "__main__":
    main()
