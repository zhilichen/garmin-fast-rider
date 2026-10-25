#!/usr/bin/env bash
# Export the production, multi-device Connect IQ Store upload file.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$TASK_ROOT"
python3 scripts/generate-project.py --check
if [ ! -f "$TASK_KEY" ]; then
  echo 'Set CIQ_DEVELOPER_KEY to the existing application signing key before export.' >&2
  exit 1
fi
while IFS= read -r device; do
  "$TASK_ROOT/scripts/check-env.sh" "$device"
done < <(python3 -c 'import json;print("\n".join(json.load(open("config/devices.json"))["devices"]))')
store_version="$(python3 -c 'import sys;sys.path.insert(0,"scripts");from build_metadata import version;print(version())')"
store_dir="dist/connect-iq/v$store_version"
mkdir -p "$store_dir"
monkeyc -e -r -f monkey.jungle -o "$store_dir/FastRider-$store_version.iq" -y "$TASK_KEY" -w
python3 - "$store_dir/FastRider-$store_version.iq" "$TASK_DEVICE_HOME" <<'PY'
import hashlib,json,subprocess,sys,xml.etree.ElementTree as ET
from pathlib import Path
sys.path.insert(0,'scripts')
from build_metadata import inputs_hash,version
p=Path(sys.argv[1]);data=p.read_bytes()
devices=json.loads(Path('config/devices.json').read_text())['devices']
if not data:raise SystemExit('Empty store package')
# SDK 9.3 IQ exports are signed 7-Zip archives, not sideload ZIP files.
members=subprocess.check_output(['tar','-tf',str(p)],text=True).splitlines()
if any(n.lower().endswith(('.der','.pem','.ttf')) for n in members):
    raise SystemExit('Unexpected private key or source font in store package')
ns={'iq':'http://www.garmin.com/xml/connectiq'}
app=ET.fromstring(subprocess.check_output(['tar','-xOf',str(p),'manifest.xml'])).find('iq:application',ns)
source=ET.parse('manifest.xml').getroot().find('iq:application',ns)
if app.attrib['id']!=source.attrib['id'] or app.attrib['version']!=version():
    raise SystemExit('Store app identity/version mismatch')
products=app.findall('iq:products/iq:product',ns)
included={d.attrib['partNumber'] for d in products}
expected={part['number'] for d in devices for part in json.loads(
    (Path(sys.argv[2])/'Devices'/d/'compiler.json').read_text())['partNumbers']}
if included!=expected:raise SystemExit('Store regional device coverage differs: '+str(included ^ expected))
if any(d.attrib['filename'] not in members for d in products):
    raise SystemExit('Missing program in store package')
record={'version':version(),'mode':'live','release':True,'bytes':len(data),
    'sha256':hashlib.sha256(data).hexdigest(),
    'devices':[{ 'device':d,'inputs_sha256':inputs_hash(d,'live')} for d in devices],
    'regional_part_numbers':sorted(included),
    'acceptance_record':'docs/validation.md'}
p.with_suffix('.json').write_text(json.dumps(record,indent=2)+'\n')
print('Store upload file: '+str(p))
print('SHA256: '+record['sha256'])
print('Verified '+str(len(devices))+' models / '+str(len(included))+' regional products.')
PY
