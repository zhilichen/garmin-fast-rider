#!/usr/bin/env python3
"""Render the README architecture illustration using the Store campaign style.

Needs Node.js + sharp (optionally NODE / NODE_PATH). Only writes docs/media and
ignored .local artboards. The native UI, release packages and Store assets stay
unchanged. Device counts and display sizes come from the shared catalog.
"""
from pathlib import Path
import base64
import html
import json
import os
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CAMPAIGN = ROOT / 'store/campaign/v0.4.1/source'
BLUE, NAVY, CREAM, TEAL = '#004CFF', '#152B3B', '#FFF8EB', '#009D85'


def text(value, x, y, size=30, color=NAVY, weight=400):
    return f'<text x="{x}" y="{y}" font-family="Arial, sans-serif" font-size="{size}" font-weight="{weight}" fill="{color}">{html.escape(str(value))}</text>'


def rect(x, y, w, h, color='white', radius=24):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{color}"/>'


def image(path, x, y, w, h):
    uri = 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()
    return f'<image href="{uri}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice"/>'


def main():
    catalog = json.loads((ROOT/'config/devices.json').read_text())
    devices, profiles = catalog['devices'], catalog['profiles']
    touch = sum(d['touch'] for d in devices.values())
    body = image(CAMPAIGN/'road-landscape.png', 0, 0, 1600, 840)
    body += '<rect width="1600" height="840" fill="#FFF8EB" fill-opacity="0.88"/>'
    body += text('FOR DEVELOPERS', 64, 70, 26, BLUE, 700)
    body += text('One codebase. Every Edge.', 64, 155, 68, NAVY, 700)
    body += text('Shared metrics and design. Generated layouts. Tested device builds.', 66, 211, 30)
    body += image(CAMPAIGN/'rider-icon.png', 1400, 38, 136, 136)
    cards = [(64, '01', 'Shared logic', BLUE), (584, '02', 'Display profiles', TEAL), (1104, '03', 'Device builds', '#D05A00')]
    for x, number, title, accent in cards:
        body += rect(x, 266, 432, 362)
        body += rect(x+24, 290, 55, 42, accent, 14) + text(number, x+35, 320, 25, 'white', 700)
        body += text(title, x+24, 382, 37, NAVY, 700)
    body += text('Metrics · laps · history', 88, 440, 29)
    body += text('Formatting · zones · rendering', 88, 491, 26)
    body += text('One layout specification', 88, 542, 29)
    body += text('Change once, reuse across models.', 88, 596, 23, '#53636D')
    for i, p in enumerate(profiles.values()):
        x, y = 608 + (i % 2)*192, 407 + (i//2)*82
        body += rect(x, y, 174, 64, '#E6F5EF', 16)
        body += text(f'{p["width"]} × {p["height"]}', x+13, y+42, 26, '#006D5E', 700)
    body += text('Layout + font assets generated.', 608, 596, 23, '#53636D')
    body += text(f'{len(devices)} Edge models', 1128, 446, 42, BLUE, 700)
    body += text(f'{touch} touch · {len(devices)-touch} button-only', 1128, 500, 28)
    body += text('Inputs follow device capabilities.', 1128, 547, 23)
    body += text('Keep the renderer shared.', 1128, 596, 23, '#53636D')
    for x in [516, 1036]:
        body += f'<path d="M{x} 448h44m-13-13 13 13-13 13" stroke="{TEAL}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    body += rect(64, 686, 1472, 106, NAVY, 24)
    steps = [('BUILD', 107), ('VM TESTS', 405), ('NATIVE SCREENS', 747), ('PACKAGE', 1222)]
    for label, x in steps:
        body += text(label, x, 750, 29, 'white', 700)
    for x in [316, 658, 1132]:
        body += f'<path d="M{x} 740h36m-12-12 12 12-12 12" stroke="#6CD7C3" stroke-width="4" fill="none" stroke-linecap="round"/>'
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="840" viewBox="0 0 1600 840">' + body + '</svg>'
    tmp = ROOT/'.local/readme'; tmp.mkdir(parents=True, exist_ok=True)
    target = ROOT/'docs/media/developer-map.png'; target.parent.mkdir(parents=True, exist_ok=True)
    source = tmp/'developer-map.svg'; source.write_text(svg)
    js = "require('sharp')(process.argv[1]).flatten({background:'#FFF8EB'}).removeAlpha().toColourspace('srgb').png({compressionLevel:9}).toFile(process.argv[2]).then(x=>console.log(JSON.stringify(x))).catch(e=>{console.error(e);process.exit(1)});"
    subprocess.run([os.environ.get('NODE', 'node'), '-e', js, str(source), str(target)], check=True)


if __name__ == '__main__':
    main()
