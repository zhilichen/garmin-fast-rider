#!/usr/bin/env bash
# Isolated native glyph probe: text / digits / packed / uncropped reference.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TASK_ROOT"
python3 - "$TASK_ROOT" <<'PY'
from pathlib import Path
import shutil,sys
root=Path(sys.argv[1]);fixture=root/'.local/font-probe'
(fixture/'source').mkdir(parents=True,exist_ok=True)
shutil.copytree(root/'source',fixture/'source',dirs_exist_ok=True)
p=fixture/'source/app/FastRiderView.mc';s=p.read_text();start=s.index('    function onUpdate(dc) {');end=s.index('    function drawPrimary(dc)',start)
s=s[:start]+'''    function onUpdate(dc) {
        width = dc.getWidth(); height = dc.getHeight(); loadFonts();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        var rows = [[0,2],[1,8],[6,5],[7,4],[13,14],[15,3],[11,12],[9,10]];
        var heights = [50,40,34,30,26,26,23,22];
        var names = ["T","D","P","R"];
        for (var col = 0; col < 8; col += 1) {
            text(dc, 2+col*30+(col >= 4 ? 4 : 0), 18, 3, names[col%4], DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
        }
        var y = 22;
        for (var row = 0; row < rows.size(); row += 1) {
            var pair = rows[row];
            var baseline = y+2+(FontInk.TOP[pair[0]] > FontInk.TOP[pair[1]] ? FontInk.TOP[pair[0]] : FontInk.TOP[pair[1]]);
            for (var side = 0; side < 2; side += 1) {
                var f = pair[side]; var sample = f == 9 || f == 10 ? "Z" : (f == 12 ? "m" : "8");
                var left = sample.equals("Z") ? 0 : FontInk.NUMERIC_LEFT[f][digitIndex(sample)];
                for (var method = 0; method < 4; method += 1) {
                    var x = 2+side*124+method*30;
                    if (method == 0) { text(dc, x-left, baseline, f, sample, DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT); }
                    else if (method == 1 && !sample.equals("Z")) { drawDigits(dc, x-left, baseline, f, sample, DisplayRules.INK, 0, false); }
                    else if (method == 2 && !sample.equals("Z")) { drawPacked(dc, x, baseline, f, sample, DisplayRules.INK); }
                    else if (method == 3) {
                        dc.setClip(x,y,28,heights[row]); dc.setColor(DisplayRules.INK,Graphics.COLOR_WHITE);
                        dc.drawText(x-left,baseline-fontSizes[f],fonts[f],sample,Graphics.TEXT_JUSTIFY_LEFT); dc.clearClip();
                    }
                }
            }
            y += heights[row];
        }
    }
''' +s[end:];p.write_text(s)
(fixture/'probe.jungle').write_text('project.manifest = ../../manifest.xml\nbase.sourcePath = source/app;source/model;source/ui;source/input/touch;../../config/demo;../../config/display/246x322\nbase.resourcePath = ../../resources/common;../../resources/fonts/246x322;../../resources/icons/35\n')
PY
monkeyc -f .local/font-probe/probe.jungle -d edge840 -o .local/FastRider-font-probe.prg -y "$TASK_KEY" -w
