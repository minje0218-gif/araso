# Hanyeong's icons, as the system's input methods draw theirs: one glyph, no badge.
# 가 while converting (Araso.ico), A while paused, keys going in as typed (ArasoPaused.ico).
#   python windows/scripts/make-icon.py
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

FONTS = Path("C:/Windows/Fonts")
INK = (31, 31, 31, 255)  # the light taskbar's text
SIZES = [16, 20, 24, 32, 40, 48, 64, 256]
OUT = Path(__file__).resolve().parents[1] / "Resources"


def glyph(text: str, font_file: str, size: int) -> Image.Image:
    # Drawn 4x and scaled down, so small sizes stay smooth; the glyph fills ~80% of the height.
    big = size * 4
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(FONTS / font_file), int(big * 0.8))
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    x = (big - (right - left)) / 2 - left
    y = (big - (bottom - top)) / 2 - top
    draw.text((x, y), text, font=font, fill=INK)
    return image.resize((size, size), Image.LANCZOS)


def save(text: str, font_file: str, name: str) -> None:
    images = [glyph(text, font_file, size) for size in SIZES]
    images[-1].save(OUT / name, format="ICO", sizes=[(s, s) for s in SIZES], append_images=images[:-1])


save("가", "malgunbd.ttf", "Araso.ico")
save("A", "segoeuib.ttf", "ArasoPaused.ico")
