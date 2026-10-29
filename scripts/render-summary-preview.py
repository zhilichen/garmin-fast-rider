#!/usr/bin/env python3
"""Make a README paused/stopped card from unmodified native captures and the SDK skin.

Optional docs export: requires Node + sharp and the installed Edge 840 package.
No AI rendering, recoloring or resampling is applied to the captured app content.
"""
import base64
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CAPTURES = ROOT / 'docs/validation/summary/v0.4.3'


def image(path, x, y, w, h):
    uri = 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()
    return f'<image href="{uri}" x="{x}" y="{y}" width="{w}" height="{h}"/>'


def main():
    home = Path(os.environ.get('CIQ_HOME', str(Path.home() / 'Library/Application Support/Garmin/ConnectIQ')))
    configured = home / 'sdkmanager-download-location.cfg'
    devices = Path(os.environ.get('CIQ_DEVICE_HOME', configured.read_text().strip() if configured.exists() else str(home)))
    skin = devices / 'Devices/edge840/edge840.png'
    outline = 'M191 8 C101 8 23 27 22 78 L22 101 H18.5 V176 H22 V222 H18.5 V284 L22 295 L18.5 317 V371 H22 V421 C22 478 84 508 191 511 C298 508 357 477 357 421 V372 H361 V299 H357 V176 H361 V101 H357 V78 C357 27 281 8 191 8 Z'
    body = '<rect width="1440" height="850" fill="#FFF8EB"/><rect x="720" width="720" height="850" fill="#0C1724"/>'
    body += '<g font-family="Arial, sans-serif">'
    for mode, x, color, accent in [('day', 0, '#152B3B', '#004CFF'), ('night', 720, '#FFFFFF', '#55AAFF')]:
        body += f'<text x="{x+50}" y="65" fill="{accent}" font-size="24" font-weight="700">FASTRIDER · {mode.upper()}</text>'
        title = 'Pause. See your ride.' if mode == 'day' else 'Your ride, after dark.'
        body += f'<text x="{x+50}" y="123" fill="{color}" font-size="43" font-weight="700">{title}</text>'
        body += f'<svg x="{x+169}" y="159" width="382" height="518" viewBox="0 0 382 518"><defs><clipPath id="outline-{mode}"><path d="{outline}"/></clipPath></defs><g clip-path="url(#outline-{mode})">'
        body += image(CAPTURES / ('edge840-' + mode + '.png'), 69, 78, 246, 322)
        body += image(skin, 0, 0, 382, 518) + '</g></svg>'
        sentence = 'Heart rate. Time. Distance. Avg W. NP.'
        body += f'<text x="{x+360}" y="724" text-anchor="middle" fill="{color}" font-size="28">{sentence}</text>'
        body += f'<text x="{x+360}" y="772" text-anchor="middle" fill="{accent}" font-size="23">A dedicated view when the timer stops.</text>'
    body += '<text x="50" y="827" fill="#53636D" font-size="18">Edge 840 · actual native simulator captures · synthetic ride data</text></g>'
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="850">' + body + '</svg>'
    temp = ROOT / '.local/readme/summary.svg'; temp.parent.mkdir(parents=True, exist_ok=True); temp.write_text(svg)
    target = ROOT / 'docs/media/ride-summary.png'
    js = "require('sharp')(process.argv[1]).removeAlpha().toColourspace('srgb').png({compressionLevel:9}).toFile(process.argv[2]).then(x=>console.log(JSON.stringify(x))).catch(e=>{console.error(e);process.exit(1)});"
    subprocess.run([os.environ.get('NODE', 'node'), '-e', js, str(temp), str(target)], check=True)


if __name__ == '__main__':
    main()
