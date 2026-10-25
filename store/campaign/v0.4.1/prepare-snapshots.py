#!/usr/bin/env python3
"""Build isolated Z2/threshold example inputs; never modify production sources."""
from pathlib import Path
import importlib.util,shutil,os
ROOT=Path(__file__).resolve().parents[3]
os.chdir(ROOT)
spec=importlib.util.spec_from_file_location('snap','scripts/prepare-snapshot.py');snap=importlib.util.module_from_spec(spec);spec.loader.exec_module(snap)
for case in ['z2','threshold']:
 src=snap.prepare('edge840','default').parent
 out=Path('.local/store-snapshots')/case;shutil.copytree(src,out,dirs_exist_ok=True)
 j=out/'snapshot.jungle';j.write_text(j.read_text().replace(str(src.resolve()),str(out.resolve())))
 p=out/'source/model/RideModel.mc';s=p.read_text();old='function demoPower(t) { return 210+95*Math.sin(t/19.0)+40*Math.sin(t/5.0); }'
 body='return 180;' if case=='z2' else 'if (t < 900) { return 125; } if (t < 2100) { return 245; } if (t < 2400) { return 100; } if (t < 3600) { return 245; } if (t < 3900) { return 100; } return 245;'
 assert s.count(old)==1;s=s.replace(old,'function demoPower(t) { '+body+' }');p.write_text(s)
 p=out/'source/app/FastRiderView.mc';s=p.read_text()
 if case=='z2':
  s=s.replace('hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;','hr = 128; cadence = 88; rearGear = 7; speed = 8.7174;').replace('grade = 6.4;','grade = 2.0;').replace('ridePower = 212;','ridePower = 180;')
 else:
  s=s.replace('hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;','hr = 166; cadence = 94; rearGear = 5; speed = 10.0138;').replace('grade = 6.4;','grade = 3.0;')
  s=s.replace('lapNumber = 3; demoSeeded = true;','lapNumber = 6; trend.boundaries = [0,900000,2100000,2400000,3600000,3900000]; ui.range = 2; demoSeeded = true;')
 p.write_text(s)
 print(j.resolve())
