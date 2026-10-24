#!/usr/bin/env python3
"""Compare native glyphs from build-font-probe.sh against unclipped references.

Requires Pillow. Input must be a 246x322 File > Save Screen Capture PNG.
"""
import argparse,json
from pathlib import Path
from PIL import Image,ImageChops

ROWS=[(0,2),(1,8),(6,5),(7,4),(13,14),(15,3),(11,12),(9,10)]
HEIGHTS=[50,40,34,30,26,26,23,22]
NAMES=['Primary58','Live38','Average54','Meta18','Chart26','Stats32','Average36','Stats30','ZoneDigit44','SmallZ16','SmallZ10','Climb18','Units18','Remaining24','Remaining22','Remaining21']

def inspect(path):
    im=Image.open(path).convert('RGB')
    if im.size!=(246,322):raise ValueError('Expected native 246x322 capture')
    bg=im.getpixel((0,0));y=22;cases=[]
    for pair,h in zip(ROWS,HEIGHTS):
        for side,f in enumerate(pair):
            x=2+side*124
            ref=im.crop((x+90,y,x+118,y+h))
            for method,name in enumerate(['text','digits','packed']):
                if f in (9,10) and method:continue
                actual=im.crop((x+30*method,y,x+30*method+28,y+h))
                diff=ImageChops.difference(actual,ref)
                missing=[(px,y+py) for py in range(h) for px in range(28) if ref.getpixel((px,py))!=bg and actual.getpixel((px,py))==bg]
                cases.append({'font':NAMES[f],'method':name,'equal_to_unclipped':diff.getbbox() is None,'missing_pixels':len(missing),'missing_rows':sorted({py for _,py in missing}),'reference_ink_rows':[y+py for py in range(h) if any(ref.getpixel((px,py))!=bg for px in range(28))]})
        y+=h
    return {'capture':str(path),'size':list(im.size),'cases':cases,'mismatches':sum(not c['equal_to_unclipped'] for c in cases),'comparisons':len(cases)}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path);p.add_argument('--report',type=Path);p.add_argument('--expect-clipped',action='store_true');a=p.parse_args();r=inspect(a.capture)
    if a.report:a.report.write_text(json.dumps(r,indent=2)+'\n')
    print(json.dumps({'comparisons':r['comparisons'],'mismatches':r['mismatches'],'missing_pixels':sum(c['missing_pixels'] for c in r['cases'])}))
    if a.expect_clipped:assert r['mismatches']>0,'Probe did not reproduce clipping'
    else:assert r['mismatches']==0,'Glyph differs from unclipped reference'
