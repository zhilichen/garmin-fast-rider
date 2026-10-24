#!/usr/bin/env python3
"""Package verified live builds and licenses, using an explicit file allowlist."""
import hashlib,json,zipfile
from pathlib import Path
from build_metadata import ROOT,inputs_hash,version

def main():
    catalog=json.loads((ROOT/'config/devices.json').read_text())['devices'];files={};manifest={'version':version(),'devices':[]}
    for device,d in catalog.items():
        p=ROOT/'bin'/device/'FastRider-live.prg';meta=p.parent/'build-live.json'
        if not meta.exists():raise SystemExit('Missing build metadata; run scripts/build.sh live '+device)
        m=json.loads(meta.read_text());data=p.read_bytes();sha=hashlib.sha256(data).hexdigest()
        if m['version']!=version() or m['inputs_sha256']!=inputs_hash(device,'live') or m['sha256']!=sha:raise SystemExit('Stale build; run scripts/build.sh live '+device)
        name=device+'/FastRider.prg';files[name]=data
        manifest['devices'].append({'device':device,'file':name,'profile':d['profile'],'touch':d['touch'],'bytes':len(data),'sha256':sha})
    for name,source in {'LICENSE':'LICENSE','THIRD_PARTY_NOTICES.md':'THIRD_PARTY_NOTICES.md','third_party/fonts/LICENSE-Apache-2.0.txt':'third_party/fonts/LICENSE-Apache-2.0.txt','third_party/fonts/LICENSE-DejaVu.txt':'third_party/fonts/LICENSE-DejaVu.txt'}.items():files[name]=(ROOT/source).read_bytes()
    files['INSTALL.md']=('FastRider '+version()+'\n\nChoose the folder matching your Edge model. Copy that folder\'s FastRider.prg to GARMIN/APPS via USB, disconnect, then choose Connect IQ > FastRider in a one-field activity page.\n\nThese are real-data builds. Defaults:3s / All / 5m. Button-only models have no touch interactions.\n').encode()
    files['manifest.json']=(json.dumps(manifest,indent=2)+'\n').encode()
    files['SHA256SUMS']=(''.join(x['sha256']+'  '+x['file']+'\n' for x in manifest['devices'])).encode()
    target=ROOT/'dist'/('FastRider-'+version()+'.zip');target.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(target,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for name,data in sorted(files.items()):
            info=zipfile.ZipInfo(name,date_time=(1980,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,data)
    (target.parent/('FastRider-'+version()+'-manifest.json')).write_text(json.dumps(manifest,indent=2)+'\n')
    print(str(target))

if __name__=='__main__':main()
