#!/usr/bin/env bash
# Isolated DEMO fixture. Only synthetic metrics change; renderer stays identical.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TASK_ROOT"
python3 - "$TASK_ROOT" <<'PY'
from pathlib import Path
import shutil, sys
root=Path(sys.argv[1]); fixture=root/'.local/layout-sample'
(fixture/'source').mkdir(parents=True,exist_ok=True)
for source in (root/'source').glob('*.mc'):
    shutil.copyfile(source,fixture/'source'/source.name)
p=fixture/'source/FastRiderView.mc';s=p.read_text()
changes={
    'hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;':
        'hr = 158; cadence = 120; rearGear = 11; speed = 10.0138;',
    'meters = demoMeters(millis/1000.0);':'meters = 300.5*1609.344;',
    'remainingDistance = 19955.8656;':'remainingDistance = 200.5*1609.344;',
}
for old,new in changes.items():
    if s.count(old)!=1: raise SystemExit('Layout fixture source anchor changed: '+old)
    s=s.replace(old,new)
p.write_text(s)
(fixture/'sample.jungle').write_text('project.manifest = ../../manifest.xml\nbase.sourcePath = source;../../config/demo\nbase.resourcePath = ../../resources\n')
PY
monkeyc -f .local/layout-sample/sample.jungle -d edge840 -o .local/FastRider-layout-sample.prg -y "$TASK_KEY" -w
