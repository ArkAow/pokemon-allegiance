#!/usr/bin/env python3
"""
Usage:
    python tools/import_pmd.py sprite_imports/bulbasaur_sprite.zip sprite_imports/charmander_sprite.zip
    python tools/import_pmd.py sprite_imports
Le nom du dossier créé = nom du zip sans "_sprite" en minuscules ("en" du pokédex).
"""
import sys, zipfile, shutil
from pathlib import Path

DEST = Path("assets/pokemons")

def keep(name: str) -> bool:
    return name == "AnimData.xml" or (name.endswith("-Anim.png") and "-Shadow" not in name)


def clean_shadows():
    n = 0
    for f in list(DEST.glob("*/*-Shadow*")) + list(DEST.glob("*/*-Offsets*")):
        f.unlink(); n += 1
    if n:
        print(f"{n} fichier(s) -Shadow/-Offsets suppr")

def from_zip(z: Path):
    name = z.stem.lower().replace("_sprite", "").replace("-sprite", "").replace(" ", "_")
    out = DEST / name
    out.mkdir(parents=True, exist_ok=True)
    n = 0
    with zipfile.ZipFile(z) as zf:
        for info in zf.infolist():
            base = Path(info.filename).name
            if info.is_dir() or not keep(base):
                continue
            (out / base).write_bytes(zf.read(info))
            n += 1
    print(f"{z.name} -> {out} ({n} fichiers)")

def from_dir(d: Path):
    out = DEST / d.name.lower()
    out.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in d.rglob("*"):
        if f.is_file() and keep(f.name):
            shutil.copy(f, out / f.name); n += 1
    print(f"{d} -> {out} ({n} fichiers)")

if __name__ == "__main__":
    args = [Path(a) for a in sys.argv[1:]]
    if not args:
        print(__doc__); sys.exit(1)
    for a in args:
        if a.is_dir() and not (a / "AnimData.xml").exists():
            for z in sorted(a.glob("*.zip")): from_zip(z)
        elif a.is_dir(): from_dir(a)
        else: from_zip(a)
    clean_shadows()
