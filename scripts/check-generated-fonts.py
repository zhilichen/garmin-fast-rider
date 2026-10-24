#!/usr/bin/env python3
"""Compare generated glyph pixels and metrics without changing committed assets.

PNG encoders can produce different compressed bytes on different hosts. Device
rendering depends on the decoded pixels and BMFont metrics, so compare those
exactly while retaining the original 840 files and their SHA256 reference.
"""
import importlib.util
import json
import os
from pathlib import Path
import tempfile

from PIL import Image, features
import PIL

ROOT = Path(__file__).resolve().parents[1]


def main():
    spec = importlib.util.spec_from_file_location(
        "font_generator", ROOT / "scripts/generate-fonts.py"
    )
    generator = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(generator)
    profiles = json.loads((ROOT / "config/devices.json").read_text())["profiles"]
    differences = []
    encoding_only = 0
    with tempfile.TemporaryDirectory(prefix="fastrider-fonts-") as folder:
        for profile, size in profiles.items():
            generated = Path(folder) / profile
            metrics = generated / "FontInk.mc"
            generator.generate(
                ROOT / "third_party/fonts", generated, size["width"] / 246, metrics
            )
            for actual in generated.iterdir():
                expected = (
                    ROOT / "config/display" / profile / actual.name
                    if actual.name == "FontInk.mc"
                    else ROOT / "resources/fonts" / profile / actual.name
                )
                if not expected.exists():
                    differences.append(str(expected.relative_to(ROOT)) + " missing")
                    continue
                if actual.suffix == ".png":
                    with Image.open(actual) as a, Image.open(expected) as b:
                        equal = a.size == b.size and a.mode == b.mode and a.tobytes() == b.tobytes()
                    if equal and actual.read_bytes() != expected.read_bytes():
                        encoding_only += 1
                else:
                    equal = actual.read_bytes() == expected.read_bytes()
                if not equal:
                    differences.append(str(expected.relative_to(ROOT)))
    print(
        f"Pillow {PIL.__version__}; FreeType {features.version('freetype2')}; "
        f"zlib {features.version('zlib')}; RAQM {features.version('raqm')}; "
        f"PNG encoding-only differences {encoding_only}"
    )
    if differences:
        message = "Generated glyph pixels or metrics differ: " + ", ".join(differences)
        if os.environ.get("GITHUB_ACTIONS") == "true":
            print("::error::" + message)
        raise SystemExit(message)
    print(f"All {len(profiles)} profiles have identical glyph pixels and font metrics.")


if __name__ == "__main__":
    main()
