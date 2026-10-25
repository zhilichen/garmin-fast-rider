#!/usr/bin/env python3
"""Validate committed installation downloads and README links without an SDK."""
import hashlib
import json
import zipfile

from build_metadata import ROOT, version
from package import END, LICENSE_FILES, README_LANGUAGES, START, SCREENSHOTS_START, SCREENSHOTS_END, download_table, screenshot_table


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def check_archive(path, folder, manifest, devices):
    names = LICENSE_FILES + ['INSTALL.md', 'manifest.json', 'SHA256SUMS']
    names += [d['file'] for d in devices]
    with zipfile.ZipFile(path) as z:
        require(sorted(z.namelist()) == sorted(names), f'Unexpected ZIP contents: {path}')
        require(z.testzip() is None, f'ZIP CRC failure: {path}')
        for name in LICENSE_FILES + ['INSTALL.md'] + [d['file'] for d in devices]:
            require(z.read(name) == (folder/name).read_bytes(), f'ZIP file differs: {path}: {name}')
        basic = [{k: v for k, v in d.items() if not k.startswith('archive')} for d in devices]
        require(json.loads(z.read('manifest.json')) == {'version': manifest['version'], 'devices': basic},
                f'ZIP model/version mismatch: {path}')
        sums = ''.join(d['sha256']+'  '+d['file']+'\n' for d in devices).encode()
        require(z.read('SHA256SUMS') == sums, f'ZIP program checksums differ: {path}')


def check_release(folder):
    manifest = json.loads((folder/'manifest.json').read_text())
    ver = manifest['version']
    require(folder.name == 'v'+ver, f'Wrong version directory: {folder}')
    devices = manifest['devices']
    require(devices and len({d['device'] for d in devices}) == len(devices), 'Duplicate or missing models')
    allowed = set(LICENSE_FILES + ['INSTALL.md', 'manifest.json', 'SHA256SUMS'])
    for d in devices:
        require(d['file'] == d['device']+'/FastRider.prg', f'Wrong PRG path: {d["device"]}')
        archive = d['device']+'/FastRider-'+ver+'-'+d['device']+'.zip'
        require(d['archive'] == archive, f'Wrong ZIP path: {d["device"]}')
        for name, size, digest in [(d['file'], d['bytes'], d['sha256']),
                                    (archive, d['archive_bytes'], d['archive_sha256'])]:
            data = (folder/name).read_bytes()
            require(len(data) == size and sha256(data) == digest, f'File checksum mismatch: {name}')
            allowed.add(name)
        check_archive(folder/archive, folder, manifest, [d])
    bundle = manifest['bundle']
    require(bundle['file'] == 'FastRider-'+ver+'.zip', 'Wrong complete ZIP filename')
    data = (folder/bundle['file']).read_bytes()
    require(len(data) == bundle['bytes'] and sha256(data) == bundle['sha256'], 'Complete ZIP checksum mismatch')
    allowed.add(bundle['file'])
    check_archive(folder/bundle['file'], folder, manifest, devices)
    actual = {str(p.relative_to(folder)) for p in folder.rglob('*') if p.is_file()}
    require(actual == allowed, f'Unexpected or missing release files: {actual ^ allowed}')
    sums = ''.join(sha256((folder/name).read_bytes())+'  '+name+'\n'
                   for name in sorted(actual - {'SHA256SUMS'}))
    require((folder/'SHA256SUMS').read_text() == sums, f'Invalid SHA256SUMS: {folder}')
    print(f'{folder.name}: {len(devices)} PRGs, {len(devices)+1} ZIPs, licenses and all SHA256 values verified.')
    return manifest


def main():
    latest = ROOT/'releases'/('v'+version())
    require((latest/'manifest.json').exists(), 'Publish current downloads with scripts/package.py --publish')
    for p in sorted((ROOT/'releases').glob('v*/manifest.json')):
        manifest = check_release(p.parent)
        if p.parent == latest:
            catalog = json.loads((ROOT/'config/devices.json').read_text())['devices']
            require([d['device'] for d in manifest['devices']] == list(catalog), 'Download models differ from catalog')
            for d in manifest['devices']:
                require(all(d[k] == catalog[d['device']][k] for k in ['profile', 'touch']), 'Download capabilities differ')
            for filename, language in README_LANGUAGES.items():
                readme = (ROOT/filename).read_text()
                for start, end, render in [(START, END, download_table), (SCREENSHOTS_START, SCREENSHOTS_END, screenshot_table)]:
                    require(readme.count(start) == 1 and readme.count(end) == 1, f'Missing {filename} markers: {start}')
                    section = readme[readme.index(start):readme.index(end)+len(end)]
                    require(section == render(manifest, language), f'{filename} generated section is stale: {start}')
            for d in manifest['devices']:
                require((ROOT/'docs/validation/screens'/(d['device']+'.png')).exists(),'Missing model screenshot: '+d['device'])
    print('English and Chinese README downloads and galleries match the published version and device catalog.')


if __name__ == '__main__':
    main()
