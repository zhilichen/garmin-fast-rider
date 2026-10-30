#!/usr/bin/env python3
"""Render the readability README card from native captures and the Edge 840 skin.

Optional documentation export: Node + sharp and an installed Edge 840 device pack.
Captured application pixels are embedded unchanged; only the surrounding card is SVG.
"""
import base64
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CAPTURES = ROOT / 'docs/validation/summary/v0.4.12'


def image(path, x, y, w, h):
    uri = 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()
    return f'<image href="{uri}" x="{x}" y="{y}" width="{w}" height="{h}"/>'


def main():
    home = Path(os.environ.get('CIQ_HOME', str(Path.home() / 'Library/Application Support/Garmin/ConnectIQ')))
    configured = home / 'sdkmanager-download-location.cfg'
    devices = Path(os.environ.get('CIQ_DEVICE_HOME', configured.read_text().strip() if configured.exists() else str(home)))
    skin = devices / 'Devices/edge840/edge840.png'
    outline = 'M191 8 C101 8 23 27 22 78 L22 101 H18.5 V176 H22 V222 H18.5 V284 L22 295 L18.5 317 V371 H22 V421 C22 478 84 508 191 511 C298 508 357 477 357 421 V372 H361 V299 H357 V176 H361 V101 H357 V78 C357 27 281 8 191 8 Z'
    body = '<rect width="1440" height="890" fill="#FFF8EB"/><rect x="720" width="720" height="890" fill="#EAF4FF"/>'
    body += '<g font-family="Arial, sans-serif" fill="#152B3B">'
    panels = [('RIDE', 'Bigger numbers. Quick glances.', 'edge840-day.png', 'Gear · cadence · gradient · speed', 'More room for your miles.'),
              ('PAUSE', 'Your whole ride, clearly.', 'edge840-stopped-day.png', 'Short labels. Units beside numbers.', 'More space where it matters.')]
    for i, (tag, title, capture, line1, line2) in enumerate(panels):
        x = i * 720
        body += f'<text x="{x+50}" y="64" fill="#004CFF" font-size="24" font-weight="700">FASTRIDER · {tag}</text>'
        body += f'<text x="{x+50}" y="120" font-size="33" font-weight="700">{title}</text>'
        body += f'<svg x="{x+169}" y="165" width="382" height="518" viewBox="0 0 382 518"><defs><clipPath id="device-{i}"><path d="{outline}"/></clipPath></defs><g clip-path="url(#device-{i})">'
        body += image(CAPTURES / capture, 69, 78, 246, 322)
        body += image(skin, 0, 0, 382, 518) + '</g></svg>'
        body += f'<text x="{x+360}" y="741" text-anchor="middle" font-size="24">{line1}</text>'
        body += f'<text x="{x+360}" y="785" text-anchor="middle" fill="#004CFF" font-size="24">{line2}</text>'
    body += '<text x="50" y="858" fill="#53636D" font-size="18">Edge 840 · native simulator captures · synthetic ride data · v0.4.12</text></g>'
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="890">' + body + '</svg>'
    temp = ROOT / '.local/readme/readability.svg'
    temp.parent.mkdir(parents=True, exist_ok=True)
    temp.write_text(svg)
    target = ROOT / 'docs/media/readability.png'
    js = "require('sharp')(process.argv[1]).removeAlpha().toColourspace('srgb').png({compressionLevel:9}).toFile(process.argv[2]).then(x=>console.log(JSON.stringify(x))).catch(e=>{console.error(e);process.exit(1)});"
    subprocess.run([os.environ.get('NODE', 'node'), '-e', js, str(temp), str(target)], check=True)


if __name__ == '__main__':
    main()
