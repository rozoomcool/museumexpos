#!/usr/bin/env python3
"""Собирает облегчённый набор ассетов приложения из ./assets/expos.

Исходники (5+ ГБ) остаются нетронутыми. На выходе:
    assets/data/catalog.json      — описание категорий и экспонатов
    assets/photos/<id>_NN.jpg     — фотографии до 1800 px
    assets/thumbs/<id>_NN.jpg     — превью до 600 px
    assets/models/<id>.glb        — задача на конвертацию (пишется отдельным скриптом)
"""

import json
import re
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "expos"
OUT = ROOT / "assets"
PHOTO_DIR = OUT / "photos"
THUMB_DIR = OUT / "thumbs"
DATA_DIR = OUT / "data"
MODEL_DIR = OUT / "models"

PHOTO_MAX = 1800
PHOTO_QUALITY = 84
THUMB_MAX = 640
THUMB_QUALITY = 80

# Слаги категорий и иконки для UI задаются вручную: транслитерация даёт
# нечитаемые имена, а категорий всего шесть.
CATEGORIES = {
    "01_Доспехи_и_оружие": ("armour-and-weapons", "shield"),
    "02_Костюм_и_украшения": ("costume-and-jewellery", "costume"),
    "03_Археология": ("archaeology", "amphora"),
    "04_Этнография_и_быт": ("ethnography", "home"),
    "05_Новейшая_история": ("modern-history", "medal"),
    "06_Живопись": ("painting", "palette"),
}

TRANSLIT = {
    "а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "e",
    "ж": "zh", "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m",
    "н": "n", "о": "o", "п": "p", "р": "r", "с": "s", "т": "t", "у": "u",
    "ф": "f", "х": "h", "ц": "c", "ч": "ch", "ш": "sh", "щ": "sch",
    "ъ": "", "ы": "y", "ь": "", "э": "e", "ю": "yu", "я": "ya",
}


def slugify(text: str, max_len: int = 44) -> str:
    out = []
    for ch in text.lower():
        if ch in TRANSLIT:
            out.append(TRANSLIT[ch])
        elif ch.isalnum() and ch.isascii():
            out.append(ch)
        else:
            out.append("-")
    slug = re.sub(r"-+", "-", "".join(out)).strip("-")
    if len(slug) > max_len:
        slug = slug[:max_len].rsplit("-", 1)[0]
    return slug


def parse_description(path: Path) -> dict:
    """Разбирает description.txt на поля. Формат стабилен для всех экспонатов."""
    raw = path.read_text(encoding="utf-8").strip()
    fields = {}
    for key, name in (
        ("Экспонат", "title"),
        ("Раздел", "section"),
        ("Почему выбран", "reason"),
        ("Исходные технические папки", "sources"),
        ("Примечание", "note"),
    ):
        m = re.search(rf"^{key}:\s*(.+?)(?=\n\s*\n|\n[А-ЯЁ][а-яё ]+:|\Z)", raw, re.M | re.S)
        if m:
            fields[name] = re.sub(r"\s+", " ", m.group(1)).strip()
    m = re.search(r"Номер в кураторской подборке:\s*(\d+)", raw)
    fields["number"] = int(m.group(1)) if m else 0
    return fields


def convert_photo(src: Path, dst: Path, max_side: int, quality: int) -> None:
    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im)
        if im.mode not in ("RGB", "L"):
            im = im.convert("RGB")
        im.thumbnail((max_side, max_side), Image.LANCZOS)
        im.save(dst, "JPEG", quality=quality, optimize=True, progressive=True)


def main() -> int:
    if not SRC.is_dir():
        print(f"нет исходной папки {SRC}", file=sys.stderr)
        return 1

    for d in (PHOTO_DIR, THUMB_DIR, DATA_DIR, MODEL_DIR):
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True)

    categories = []
    model_jobs = []

    for cat_dir in sorted(p for p in SRC.iterdir() if p.is_dir()):
        cat_slug, cat_icon = CATEGORIES.get(cat_dir.name, (slugify(cat_dir.name), "amphora"))
        cat_title = re.sub(r"^\d+_", "", cat_dir.name).replace("_", " ")
        exhibits = []

        for ex_dir in sorted(p for p in cat_dir.iterdir() if p.is_dir()):
            desc_file = ex_dir / "description.txt"
            if not desc_file.is_file():
                print(f"пропуск (нет description.txt): {ex_dir.name}")
                continue

            info = parse_description(desc_file)
            number = info.get("number") or int(ex_dir.name.split("_", 1)[0])
            title = info.get("title") or ex_dir.name.split("_", 1)[1].replace("_", " ")
            ex_id = f"{number:03d}-{slugify(title)}"

            images = sorted(
                p for p in ex_dir.iterdir()
                if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".tif", ".tiff")
            )
            photos, thumbs = [], []
            for i, img in enumerate(images, start=1):
                name = f"{ex_id}_{i:02d}.jpg"
                convert_photo(img, PHOTO_DIR / name, PHOTO_MAX, PHOTO_QUALITY)
                convert_photo(img, THUMB_DIR / name, THUMB_MAX, THUMB_QUALITY)
                photos.append(f"assets/photos/{name}")
                thumbs.append(f"assets/thumbs/{name}")

            glbs = sorted(p for p in ex_dir.iterdir() if p.suffix.lower() == ".glb")
            model = None
            if glbs:
                model = f"assets/models/{ex_id}.glb"
                model_jobs.append({"src": str(glbs[0]), "dst": str(MODEL_DIR / f"{ex_id}.glb")})

            exhibits.append({
                "id": ex_id,
                "number": number,
                "title": title,
                "categoryId": cat_slug,
                "reason": info.get("reason", ""),
                "note": info.get("note", ""),
                "sources": info.get("sources", ""),
                "photos": photos,
                "thumbs": thumbs,
                "model": model,
            })
            print(f"  {ex_id}: {len(photos)} фото, модель={'да' if model else 'нет'}")

        categories.append({
            "id": cat_slug,
            "title": cat_title,
            "icon": cat_icon,
            "exhibits": exhibits,
        })

    catalog = {
        "title": "Экспонаты ЧР",
        "subtitle": "Кураторская подборка 60 экспонатов",
        "categories": categories,
    }
    (DATA_DIR / "catalog.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (ROOT / "tools" / "model_jobs.json").write_text(
        json.dumps(model_jobs, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    total = sum(len(c["exhibits"]) for c in catalog["categories"])
    print(f"\nготово: {len(categories)} категорий, {total} экспонатов, {len(model_jobs)} моделей в очереди")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
