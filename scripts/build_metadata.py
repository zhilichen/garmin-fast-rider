#!/usr/bin/env python3
"""Stamp build inputs and binary hashes without recording host paths or keys."""
import argparse,hashlib,json,subprocess,xml.etree.ElementTree as ET
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def version():return ET.parse(ROOT/'manifest.xml').find('{http://www.garmin.com/xml/connectiq}application').attrib['version']

def inputs_hash(device,mode):
    d=json.loads((ROOT/'config/devices.json').read_text())['devices'][device]
    roots=['source/app','source/model','source/ui','source/input/'+('touch' if d['touch'] else 'buttons'),'config/'+('demo' if mode=='test' else mode),'config/display/'+d['profile'],'resources/common','resources/fonts/'+d['profile'],'resources/icons/'+str(d['icon_size'])]
    if mode=='test':
        roots+=['tests/monkeyc/common','tests/monkeyc/'+('legacy' if d['legacy_api'] else 'modern')]
        if d['touch']:roots.append('tests/monkeyc/touch')
    files=[ROOT/'manifest.xml',ROOT/('monkey.jungle' if mode=='live' else mode+'.jungle')]
    for folder in roots:files.extend(p for p in (ROOT/folder).rglob('*') if p.is_file())
    digest=hashlib.sha256()
    for p in sorted(set(files)):
        digest.update(str(p.relative_to(ROOT)).encode()+b'\0'+p.read_bytes()+b'\0')
    return digest.hexdigest()

def stamp(device,mode):
    p=ROOT/'bin'/device/('FastRider-'+mode+'.prg');data=p.read_bytes()
    compiler=subprocess.check_output(['monkeyc','-v'],text=True).strip()
    record={'device':device,'mode':mode,'version':version(),'compiler':compiler,'inputs_sha256':inputs_hash(device,mode),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
    (p.parent/('build-'+mode+'.json')).write_text(json.dumps(record,indent=2)+'\n')
    return record

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('device');p.add_argument('mode');a=p.parse_args();stamp(a.device,a.mode)
