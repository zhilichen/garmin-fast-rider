#!/usr/bin/env python3
"""Prepare an isolated deterministic demo; never modify production sources."""
import argparse,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def prepare(device,case,destination=None):
    devices=json.loads((ROOT/'config/devices.json').read_text())['devices'];d=devices[device]
    target=Path(destination) if destination is not None else ROOT/'.local/snapshots'/device
    shutil.copytree(ROOT/'source',target/'source',dirs_exist_ok=True)
    p=target/'source/app/FastRiderView.mc';s=p.read_text()
    for a,b in [('var t = (System.getTimer()-start)/1000.0;','var t = 0.0;'),('var clock = System.getClockTime();',''),('RideMath.clock12(clock.hour, clock.min)','RideMath.clock12(15, 47)')]:
        if s.count(a)!=1:raise ValueError('Snapshot anchor changed: '+a)
        s=s.replace(a,b)
    base_case=case.removeprefix('stopped-') if case.startswith('stopped-') else case
    if case == 'power-four-capacity':base_case='capacity'
    if base_case=='stress':
        s=s.replace('hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;','hr = 199; cadence = 120; rearGear = 11; speed = 44.927;')
        s=s.replace('meters = demoMeters(millis/1000.0);','meters = 300.5*1609.344;').replace('remainingDistance = 19955.8656;','remainingDistance = 200.5*1609.344;').replace('ridePower = 212;','ridePower = 1234;')
        s=s.replace('grade = 6.4;','grade = -16.4;').replace('rolling.update(timerMillis, power, true);','power = 1234; rolling.reset(); rolling.update(timerMillis, power, true);')
    elif base_case=='missing':
        s=s.replace('hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;','hr = null; cadence = null; rearGear = null; speed = null;')
        s=s.replace('grade = 6.4;','grade = null;').replace('remainingDistance = 19955.8656;','remainingDistance = null;')
        s=s.replace('rolling.update(timerMillis, power, true);','rolling.reset(); power = null;')
    if case in ('power-three','power-four','power-four-wide','power-four-capacity'):
        watts={'power-three':888,'power-four':1234,'power-four-wide':4444,'power-four-capacity':4444}[case]
        anchor='rolling.update(timerMillis, power, true);'
        if s.count(anchor)!=1:raise ValueError('Power snapshot anchor changed')
        s=s.replace(anchor,f'power = {watts}; rolling.reset(); rolling.update(timerMillis, power, true);')
    if case in ('lap', 'lap-hours', 'hours-stress', 'ten-second'):
        anchor='        trend.update(millis, power, true);\n    }\n    function onTimerReset()'
        extra=''
        if case in ('lap', 'lap-hours'):
            extra+='        ui.allStats = false;\n'
        if case == 'lap-hours':
            extra+='        lapNumber = 12; lap.timeMs = 4992000; lap.distance = 12.34*1609.344;\n'
        if case == 'hours-stress':
            extra+='        timerMillis = 360000000;\n'
        if case == 'ten-second':
            extra+='        ui.powerSeconds = 10;\n'
        if s.count(anchor)!=1:raise ValueError('Riding snapshot anchor changed')
        s=s.replace(anchor,'        trend.update(millis, power, true);\n'+extra+'    }\n    function onTimerReset()')
    if base_case == 'capacity':
        anchor='        trend.update(millis, power, true);\n    }\n    function onTimerReset()'
        extra='''        if (trend.boundaries.size() < 100) {
            trend.points = []; trend.medium.points = []; trend.whole.points = []; trend.boundaries = [];
            for (var i = 0; i < trend.MAX_POINTS; i += 1) {
                var at = (4988-trend.MAX_POINTS+i)*1000;
                trend.points.add([at,at,250,1,i]);
                at = (4988-5*trend.medium.MAX_POINTS+i*5)*1000; trend.medium.points.add([at,at,250,1,i]);
                at = 30000*i; trend.whole.points.add([at,at,250,1,i]);
            }
            for (var i = 0; i < 100; i += 1) { trend.boundaries.add(i*49000); }
        }
'''
        if s.count(anchor)!=1:raise ValueError('Capacity snapshot anchor changed')
        s=s.replace(anchor,'        trend.update(millis, power, true);\n'+extra+'    }\n    function onTimerReset()')
    if case.startswith('stopped'):
        anchor='    }\n    function onTimerReset()'
        if s.count(anchor)!=1:raise ValueError('Summary snapshot anchor changed')
        extra='        screen.update(Activity.TIMER_STATE_STOPPED);\n'
        if base_case=='missing':extra+='        averageHr = null; averageCadence = null; averageSpeed = null; normalized.reset();\n'
        if base_case=='stress':
            s=s.replace('averageCadence = 86; averageSpeed = 8.9408;', 'averageCadence = 123; averageSpeed = 44.927;')
            s=s.replace('ascent = 682.0+t/10.0;', 'ascent = 30479.6952;').replace('RideMath.clock12(15, 47)','RideMath.clock12(0, 59)')
            extra+='        millis = 360000000;\n'
        s=s.replace(anchor,extra+anchor)
    p.write_text(s)
    paths=[target/'source/app',target/'source/model',target/'source/ui',target/'source/input'/('touch' if d['touch'] else 'buttons'),ROOT/'config/demo',ROOT/'config/display'/d['profile']]
    resources=[ROOT/'resources/common',ROOT/'resources/fonts'/d['profile'],ROOT/'resources/icons'/str(d['icon_size'])]
    quote=lambda p:'"'+str(p)+'"'
    jungle='project.manifest = '+quote(ROOT/'manifest.xml')+'\nbase.sourcePath = '+';'.join(map(quote,paths))+'\nbase.resourcePath = '+';'.join(map(quote,resources))+'\n'
    (target/'snapshot.jungle').write_text(jungle)
    return target/'snapshot.jungle'

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('device');p.add_argument('--case',choices=['default','stress','missing','stopped','stopped-stress','stopped-missing','lap','lap-hours','hours-stress','ten-second','capacity','stopped-capacity','power-three','power-four','power-four-wide','power-four-capacity'],default='default');a=p.parse_args();print(prepare(a.device,a.case))
