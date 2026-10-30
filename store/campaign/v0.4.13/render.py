#!/usr/bin/env python3
"""Typeset the campaign around original AI art and unmodified native UI captures.

Requires Node+sharp. SVG artboards preserve screenshot pixels and keep all
marketing text independently editable. No app sources or binaries are modified.
Garmin's installed simulator skin supplies the device exterior; it is not copied
into this repository as a standalone asset.
"""
from pathlib import Path
import base64,html,json,os,subprocess,sys
BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
OUT=ROOT/'.local/campaign-v0413';OUT.mkdir(exist_ok=True,parents=True)
BLUE='#004CFF';NAVY='#152B3B';CREAM='#FFF8EB';ORANGE='#D05A00';PURPLE='#8000D8';RED='#D00020';GRAY='#555555';TEAL='#009D85'
SKIN=Path(os.environ.get('CIQ_DEVICE_HOME',str(Path.home()/'Library/Application Support/Garmin/ConnectIQ')))/'Devices/edge840/edge840.png'

def esc(s):return html.escape(str(s))
def uri(p):return 'data:image/png;base64,'+base64.b64encode(Path(p).read_bytes()).decode()
def image(p,x,y,w,h):return f'<image href="{uri(p)}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet"/>'
def rect(x,y,w,h,fill='white',r=24,stroke=None):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="2"' if stroke else '')+'/>'
def text(s,x,y,size=28,fill=NAVY,bold=False,anchor='start',family='Arial'):
 return f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" font-weight="{700 if bold else 400}" fill="{fill}" text-anchor="{anchor}">{esc(s)}</text>'
def lines(items,x,y,size=26,leading=38,fill=NAVY,bold=False):return ''.join(text(s,x,y+i*leading,size,fill,bold) for i,s in enumerate(items))
def title(a,b):return text(a,48,129,57,NAVY,True)+text(b,48,191,57,BLUE,True)
def bolt(x,y,scale=1,color=BLUE):return f'<path d="M18 0 0 22h13L8 42l30-27H23L29 0Z" fill="{color}" transform="translate({x},{y}) scale({scale})"/>'
def chip(s,x,y,w,fill=BLUE,txt='white',size=20):return rect(x,y,w,42,fill,21)+text(s,x+w/2,y+28,size,txt,True,'middle')
def rider(x,y,w):return image(BASE/'source/road-rider.png',x,y,w,w*2/3)
def ui_file(name='default'):
 paths={'default':BASE/'source/edge840-default.png','controls':BASE/'source/edge840-controls.png','whole':BASE/'source/edge840-default.png','z2':BASE/'source/edge840-z2.png','threshold':BASE/'source/edge840-threshold.png','paused':BASE/'source/edge840-paused.png','night':BASE/'source/edge840-night.png'}
 return paths[name]
def device(x,y,w,name='default'):
 # Skin screen opening is 246x322 at (69,78), exactly matching the native field.
 # Clip only the native skin's exterior white canvas. Hardware and screen pixels
 # remain the original SDK/capture images; the screen opening keeps its alpha.
 outline='M191 8 C101 8 23 27 22 78 L22 101 H18.5 V176 H22 V222 H18.5 V284 L22 295 L18.5 317 V371 H22 V421 C22 478 84 508 191 511 C298 508 357 477 357 421 V372 H361 V299 H357 V176 H361 V101 H357 V78 C357 27 281 8 191 8 Z'
 return f'<svg x="{x}" y="{y}" width="{w}" height="{w*518/382}" viewBox="0 0 382 518"><defs><clipPath id="device-outline"><path d="{outline}"/></clipPath></defs><g clip-path="url(#device-outline)">'+image(ui_file(name),69,78,246,322)+image(SKIN,0,0,382,518)+'</g></svg>'
def head(n):return bolt(48,34,.7)+text('FastRider',86,60,27,BLUE,True)+text(f'{n:02d}',952,60,23,NAVY,True,'end')
def footer(s='Edge 840 shown. Synthetic example data.'):
 return text(s,48,961,19,'#53636D')
def svg(body,w=1000,h=1000):
 landscape=BASE/'source/road-landscape.png'
 # A quiet cream fade protects headings; hills and a road add depth at the base.
 scene=f'<image href="{uri(landscape)}" x="0" y="0" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice"/>'
 fade='<defs><linearGradient id="scene-fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF8EB" stop-opacity="0.18"/><stop offset="0.7" stop-color="#FFF8EB" stop-opacity="0.25"/><stop offset="1" stop-color="#FFF8EB" stop-opacity="0.05"/></linearGradient></defs>' if w>h else '<defs><linearGradient id="scene-fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF8EB" stop-opacity="0.65"/><stop offset="0.7" stop-color="#FFF8EB" stop-opacity="0.86"/><stop offset="1" stop-color="#FFF8EB" stop-opacity="0.45"/></linearGradient></defs>'
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+rect(0,0,w,h,CREAM,0)+scene+fade+rect(0,0,w,h,'url(#scene-fade)',0)+body+'</svg>'
def save(name,body,w=1000,h=1000):
 p=OUT/(name+'.svg');p.write_text(svg(body,w,h));return {'name':name,'svg':str(p),'width':w,'height':h}
def card_body(n,a,b,name='default'):
 return head(n)+title(a,b)+device(43,228,462,name)
def note(heading,body,x,y,w=394,tint='white',accent=BLUE):
 return rect(x,y,w,133,tint,24)+text(heading,x+24,y+39,23,accent,True)+lines(body,x+24,y+77,23,32)

def main():
 jobs=[]
 hero=bolt(64,54,1.15)+text('FastRider',119,93,48,BLUE,True)
 hero+=text('Your ride.',64,200,80,NAVY,True)+text('One screen.',64,286,80,BLUE,True)
 hero+=lines(['Power. Heart rate. Lap stats.','The essentials, together.'],68,338,27,36)
 hero+=chip('COLOR-CODED EFFORT',66,437,300)+chip('TOUCH BELL',66,494,226,TEAL)+chip('Power Graph',66,551,240,ORANGE)
 hero+=rider(355,296,630)
 hero+=device(989,55,390,'threshold' if ui_file('threshold').exists() else 'default')+rect(1063,619,240,38,CREAM,19)+text('Edge 840 • sample data',1183,644,19,'#53636D',False,'middle')
 jobs.append(save('01-hero-en',hero,1440,720))
 b=card_body(1,'Your key numbers.','One screen!')
 b+=note('POWER + HEART RATE',['Big numbers. Bold zones.'],550,243)
 b+=note('GEAR · RPM · MPH · GRADE',['Keep the essentials together.'],550,401)
 b+=note('RIDE + PAUSE VIEWS',['Lap stats while you ride.','A full summary when paused.'],550,559)
 b+=rider(546,691,400)+footer()
 jobs.append(save('04-screen-01-one-screen',b))
 b=card_body(2,'No native bell?','Double-tap. Ding!')
 b+=f'<g transform="translate(665,250)" stroke="{NAVY}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"><path d="M0 100h150l-15-22V47c0-70-120-70-120 0v31Z" fill="#FFD35A"/><path d="M61 118q15 25 30 0" fill="none"/><path d="m-28 5-17-10m223 10 17-10m-218 44-22 0m250 0h22" fill="none"/></g>'
 b+=text('2 taps. 2 seconds.',550,452,37,BLUE,True)
 b+=lines(['Double-tap the left side.','Hear a three-strike bell effect.','No native bike-bell feature','needed. Uses your Edge’s tones.'],550,501,24,35)
 # Diagram callout points to the native left-side tap area without changing UI.
 b+=f'<circle cx="196" cy="540" r="36" fill="{BLUE}" fill-opacity="0.10" stroke="{BLUE}" stroke-width="4"/><circle cx="196" cy="540" r="54" fill="none" stroke="{BLUE}" stroke-width="2" stroke-dasharray="7 8"/>'
 b+=rider(548,662,410)+footer('Touch models only. Sound depends on device tone support.')
 jobs.append(save('04-screen-02-touch-bell',b))
 z2name='z2' if ui_file('z2').exists() else 'default'
 b=card_body(3,'Ride blue.','Hold your Z2.',z2name)
 b+=chip('ENDURANCE',550,249,205)
 b+=text('Close to the cap.',550,344,37,NAVY,True)
 b+=lines(['Stay blue through Z2.','The blue guide marks its ceiling.','Cross it, and the color changes.'],550,396,25,38)
 b+=rect(550,520,394,154,'#E7EDFF',24)+text('180 W',576,572,41,BLUE,True)+text('Example: FTP 250 W',576,607,22,BLUE)
 for i in range(31):b+=rect(576+i*10,625-(i%3)*2,7,23+(i%3)*2,BLUE,0)
 b+=text('Z2: above 55% through 75% FTP',550,715,21,BLUE,True)
 b+=rider(610,741,330)+footer('Screen: sample ride. Blue training strip: illustration.')
 jobs.append(save('04-screen-03-z2-training',b))
 tname='threshold' if ui_file('threshold').exists() else 'whole'
 b=card_body(4,'Long intervals.','Clear targets.',tname)
 b+=chip('THRESHOLD',550,249,215,ORANGE)
 b+=text('3 × 20 minutes.',550,344,40,ORANGE,True)
 b+=lines(['Hold orange through Z4.','See recoveries and lap markers.','Zoom out to review the ride.'],550,396,25,38)
 for i in range(3):b+=rect(550+i*132,539,112,74,ORANGE,13)+text('20m',606+i*132,586,28,'white',True,'middle')
 b+=text('Z4: above 90% through 105% FTP',550,665,21,ORANGE,True)
 b+=text('Training sketch · recovery between efforts',550,703,20,'#53636D')
 b+=rider(610,749,330)+footer('Screen: sample ride. Orange interval blocks: illustration.')
 jobs.append(save('04-screen-04-threshold-intervals',b))
 b=card_body(5,'Less decoding.','More riding.')
 b+=text('Power, color coded.',550,272,34,NAVY,True)
 for i,(label,color) in enumerate([('Z1 / Z3 · easy / tempo',GRAY),('Z2 · endurance',BLUE),('Z4 · threshold',ORANGE),('Z5 · high intensity',PURPLE),('Z6 / Z7 · hard efforts',RED)]):
  y=299+i*67;b+=rect(550,y,394,55,color,18)+text(label,574,y+36,24,'white',True)
 b+=lines(['Heart-rate zones are independent.','Cadence and gradient have','their own color alerts, too.'],550,687,23,33)
 b+=rider(622,801,290)+footer()
 jobs.append(save('04-screen-05-color-coded',b))
 b=card_body(6,'Tap. Switch.','Keep rolling.','controls')
 b+=note('POWER',['3s  ↔  10s'],550,249,accent=BLUE)
 b+=note('STATISTICS',['All ride  ↔  Current lap'],550,407,accent=TEAL)
 b+=note('POWER GRAPH',['5m  →  20m  →  All'],550,565,accent=ORANGE)
 b+=text('Native laps select the latest lap.',550,744,22,NAVY,True)
 b+=rider(593,772,330)+footer('Touch models shown. Button models use 3s / All / 5m.')
 jobs.append(save('04-screen-06-tap-controls',b))
 b=card_body(7,'Stop. Breathe.','See your whole ride.','paused')
 b+=note('WHOLE-RIDE SUMMARY',['Heart rate, Avg HR,','Avg PWR and NP.'],550,249)
 b+=note('MORE THAN DISTANCE',['Distance, ascent, Avg CAD,','Avg SPD. Small, clear units.'],550,407,accent=TEAL)
 b+=note('AUTOMATIC VIEW SWITCH',['Pause for your ride summary.','Resume for your live dashboard.'],550,565,accent=ORANGE)
 b+=rider(593,772,330)+footer()
 jobs.append(save('04-screen-07-paused-summary',b))
 b=card_body(8,'Bright days.','Clear nights.','night')
 b+=note('FOLLOWS YOUR EDGE',['Automatic day / night colors.'],550,249)
 b+=note('SAME ZONES, MORE CONTRAST',['Bright colors on a dark screen.','Your zone meanings stay familiar.'],550,407,accent=TEAL)
 b+=note('READY WHEN YOU ARE',['Ride and paused summary','both support night mode.'],550,565,accent=ORANGE)
 b+=rider(593,772,330)+footer()
 jobs.append(save('04-screen-08-day-night',b))
 (OUT/'jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
 env=dict(os.environ)
 subprocess.run([env.get('NODE','node'),str(BASE/'render.cjs'),str(OUT/'jobs.json')],check=True,env=env)
 subprocess.run([sys.executable,str(BASE/'build-preview.py')],check=True)
if __name__=='__main__':main()
