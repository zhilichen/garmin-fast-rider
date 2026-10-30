#!/usr/bin/env python3
"""Prepare deterministic current-UI marketing fixtures without editing production."""
from pathlib import Path
import importlib.util
import os

ROOT = Path(__file__).resolve().parents[3]
os.chdir(ROOT)
spec = importlib.util.spec_from_file_location('snapshot', ROOT/'scripts/prepare-snapshot.py')
snap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(snap)
for case in ['z2', 'threshold', 'controls']:
    dest = ROOT/'.local/store-v0413'/case
    jungle = snap.prepare('edge840', 'default', dest)
    path = dest/'source/app/FastRiderView.mc'
    source = path.read_text()
    if case in ['z2', 'threshold']:
        model = dest/'source/model/RideModel.mc'
        text = model.read_text()
        old = 'function demoPower(t) { return 210+95*Math.sin(t/19.0)+40*Math.sin(t/5.0); }'
        body = 'return 180;' if case == 'z2' else 'if (t < 900) { return 125; } if (t < 2100) { return 245; } if (t < 2400) { return 100; } if (t < 3600) { return 245; } if (t < 3900) { return 100; } return 245;'
        assert text.count(old) == 1
        model.write_text(text.replace(old, 'function demoPower(t) { '+body+' }'))
        source = source.replace('var ftp = RideMath.clamp(Application.Properties.getValue("ftp"), 50, 600);', 'var ftp = 250;')
        source = source.replace('var maxHr = RideMath.clamp(Application.Properties.getValue("maxHr"), 100, 240);', 'var maxHr = 190;')
        if case == 'z2':
            source = source.replace('hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;', 'hr = 128; cadence = 88; rearGear = 7; speed = 8.7174;')
            source = source.replace('grade = 6.4;', 'grade = 2.0;').replace('ridePower = 212;', 'ridePower = 180;')
        else:
            source = source.replace('hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;', 'hr = 166; cadence = 94; rearGear = 5; speed = 10.0138;')
            source = source.replace('grade = 6.4;', 'grade = 3.0;').replace('ridePower = 212;', 'ridePower = 206;')
            source = source.replace('lapNumber = 3; demoSeeded = true;', 'lapNumber = 6; trend.boundaries = [0,900000,2100000,2400000,3600000,3900000]; ui.range = 2; demoSeeded = true;')
    else:
        anchor = '        trend.update(millis, power, true);\n    }\n    function onTimerReset()'
        assert source.count(anchor) == 1
        source = source.replace(anchor, '        trend.update(millis, power, true);\n        ui.powerSeconds = 10; ui.allStats = false; ui.range = 1;\n    }\n    function onTimerReset()')
    path.write_text(source)
    print(jungle)
