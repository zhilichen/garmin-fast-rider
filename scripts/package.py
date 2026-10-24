#!/usr/bin/env python3
"""Package verified live builds and licenses, using an explicit file allowlist."""
import argparse,hashlib,io,json,zipfile
from build_metadata import ROOT,inputs_hash,version

LICENSE_FILES = ['LICENSE', 'THIRD_PARTY_NOTICES.md',
    'third_party/fonts/LICENSE-Apache-2.0.txt', 'third_party/fonts/LICENSE-DejaVu.txt']
START = '<!-- downloads:start -->'
END = '<!-- downloads:end -->'
RAW = 'https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/'

def zip_bytes(files):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, data)
    return buffer.getvalue()

def download_table(manifest):
    ver = manifest['version']
    prefix = RAW + 'releases/v' + ver + '/'
    rows = [START, f'当前版本 **v{ver}**，下载后即可安装，无需 SDK 或 Java。PRG 可直接复制到设备；ZIP 包含同一程序、安装说明和许可证。', '',
        '| 设备 | 原生分辨率 | 操作 | PRG 直接下载 | ZIP 下载 |',
        '| --- | --- | --- | --- | --- |']
    for d in manifest['devices']:
        model = d['device'][4:].replace('bontrager', ' Bontrager').replace('plus', ' Plus')
        action = '触控切换与车铃' if d['touch'] else '默认视图'
        rows.append(f'| Edge {model} | {d["profile"].replace("x", "×")} | {action} | [PRG]({prefix+d["file"]}) | [ZIP]({prefix+d["archive"]}) |')
    rows += ['', f'[全部型号 ZIP]({prefix+manifest["bundle"]["file"]}) · [SHA256 校验值](releases/v{ver}/SHA256SUMS) · [版本清单](releases/v{ver}/manifest.json)', END]
    return '\n'.join(rows)

def publish_downloads(files, manifest, bundle):
    # Only verified production programs and their distribution notices enter Git.
    release = json.loads(json.dumps(manifest))
    common = {name: files[name] for name in LICENSE_FILES + ['INSTALL.md']}
    outputs = dict(common)
    for d in release['devices']:
        outputs[d['file']] = files[d['file']]
        archive = d['device'] + '/FastRider-' + release['version'] + '-' + d['device'] + '.zip'
        package = dict(common)
        package[d['file']] = files[d['file']]
        package['manifest.json'] = (json.dumps({'version': release['version'], 'devices': [dict(d)]}, indent=2)+'\n').encode()
        package['SHA256SUMS'] = (d['sha256']+'  '+d['file']+'\n').encode()
        outputs[archive] = zip_bytes(package)
        d.update({'archive': archive, 'archive_bytes': len(outputs[archive]),
            'archive_sha256': hashlib.sha256(outputs[archive]).hexdigest()})
    name = 'FastRider-' + release['version'] + '.zip'
    outputs[name] = bundle
    release['bundle'] = {'file': name, 'bytes': len(bundle), 'sha256': hashlib.sha256(bundle).hexdigest()}
    outputs['manifest.json'] = (json.dumps(release, indent=2)+'\n').encode()
    outputs['SHA256SUMS'] = ''.join(hashlib.sha256(data).hexdigest()+'  '+name+'\n'
        for name, data in sorted(outputs.items())).encode()
    folder = ROOT/'releases'/('v'+release['version'])
    # Published versioned downloads are immutable; a different build needs a new version.
    if folder.exists():
        existing = {str(p.relative_to(folder)): p.read_bytes() for p in folder.rglob('*') if p.is_file()}
        if existing != outputs:
            raise SystemExit('Published version already exists with different files; bump manifest.xml version.')
    readme = (ROOT/'README.md').read_text()
    if readme.count(START) != 1 or readme.count(END) != 1:
        raise SystemExit('README must contain one downloads:start/end marker pair.')
    updated = readme[:readme.index(START)] + download_table(release) + readme[readme.index(END)+len(END):]
    for name, data in outputs.items():
        p = folder/name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
    (ROOT/'README.md').write_text(updated)
    print(str(folder))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish', action='store_true', help='Also write versioned Git downloads and update README links')
    args = parser.parse_args()
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
    bundle = zip_bytes(files)
    target.write_bytes(bundle)
    (target.parent/('FastRider-'+version()+'-manifest.json')).write_text(json.dumps(manifest,indent=2)+'\n')
    print(str(target))
    if args.publish:
        publish_downloads(files, manifest, bundle)

if __name__=='__main__':main()
