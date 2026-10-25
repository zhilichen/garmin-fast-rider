#!/usr/bin/env python3
"""Run native VM tests in owned macOS simulator instances.

Close other Connect IQ simulators first. Only instances launched here are stopped.
"""
import argparse,json,os,re,signal,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def simulator_pids(binary):
    p=subprocess.run(['pgrep','-f',str(binary)],capture_output=True,text=True)
    return {int(x) for x in p.stdout.split()}

def launch(binary):
    # LaunchServices owns the real Cocoa PID; directly exec'ing the binary can
    # leave a second, untracked application after an activation event.
    launcher=subprocess.Popen(['open','-W','-n',str(binary.parents[2])],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    pid=None
    for attempt in range(300):
        pids=simulator_pids(binary)
        if len(pids)==1:
            pid=next(iter(pids))
            if subprocess.run(['lsof','-nP','-a','-p',str(pid),'-iTCP:1234','-sTCP:LISTEN'],capture_output=True).returncode==0:return launcher,pid
        elif len(pids)>1:break
        if launcher.poll() is not None:break
        time.sleep(0.1)
    if pid is not None:
        try:os.kill(pid,signal.SIGTERM)
        except ProcessLookupError:pass
    launcher.terminate();launcher.wait(timeout=5)
    raise RuntimeError('Simulator startup failed; close stale instances and retry')

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('devices',nargs='*');ap.add_argument('--no-build',action='store_true');a=ap.parse_args()
    catalog=json.loads((ROOT/'config/devices.json').read_text())['devices'];targets=a.devices or list(catalog)
    if any(d not in catalog for d in targets):raise SystemExit('Unknown device')
    sdk=Path(os.environ['CIQ_SDK_PATH']);binary=sdk/'bin/ConnectIQ.app/Contents/MacOS/simulator'
    if not binary.exists():raise SystemExit('This batch driver requires macOS. Other hosts: scripts/run.sh test <device>.')
    if simulator_pids(binary):raise SystemExit('Close the existing simulator before starting the owned-process test matrix.')
    out=ROOT/'.local/test-results';out.mkdir(parents=True,exist_ok=True);report=[]
    (out/'matrix.json').write_text('[]\n')
    for device in targets:
        if not a.no_build:subprocess.run([str(ROOT/'scripts/build.sh'),'test',device],cwd=ROOT,check=True)
        launcher,pid=launch(binary)
        try:
            result=subprocess.run([str(sdk/'bin/monkeydo'),str(ROOT/'bin'/device/'FastRider-test.prg'),device,'-t'],capture_output=True,text=True,timeout=60)
            text=result.stdout+result.stderr;(out/(device+'.txt')).write_text(text.replace(str(ROOT),'<workspace>'))
            match=re.search(r'^PASSED \(passed=(\d+), failed=0, errors=0\)$',text,re.M)
            record={'device':device,'passed':int(match[1]) if match else 0,'ok':bool(match)};report.append(record);print(json.dumps(record),flush=True)
            (out/'matrix.json').write_text(json.dumps(report,indent=2)+'\n')
            if not match:print(text[-5000:],flush=True)
        finally:
            try:os.kill(pid,signal.SIGTERM)
            except ProcessLookupError:pass
            try:launcher.wait(timeout=5)
            except subprocess.TimeoutExpired:launcher.terminate();launcher.wait()
    (out/'matrix.json').write_text(json.dumps(report,indent=2)+'\n')
    if not all(r['ok'] for r in report):raise SystemExit(1)

if __name__=='__main__':main()
