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
def bolt(x,y,scale=1,color=BLUE):return f'<path d="M18 0 0 22h13L8 42l30-27H23L29 0Z" fill="{color}" transform="translate({x},{y}) scale({scale})"/>'
def ui_file(name='default'):
 paths={'default':BASE/'source/edge840-default.png','controls':BASE/'source/edge840-controls.png','whole':BASE/'source/edge840-default.png','z2':BASE/'source/edge840-z2.png','threshold':BASE/'source/edge840-threshold.png','paused':BASE/'source/edge840-paused.png','night':BASE/'source/edge840-night.png'}
 return paths[name]
def device(x,y,w,name='default'):
 # Skin screen opening is 246x322 at (69,78), exactly matching the native field.
 # Clip only the native skin's exterior white canvas. Hardware and screen pixels
 # remain the original SDK/capture images; the screen opening keeps its alpha.
 outline='M191 8 C101 8 23 27 22 78 L22 101 H18.5 V176 H22 V222 H18.5 V284 L22 295 L18.5 317 V371 H22 V421 C22 478 84 508 191 511 C298 508 357 477 357 421 V372 H361 V299 H357 V176 H361 V101 H357 V78 C357 27 281 8 191 8 Z'
 return f'<svg x="{x}" y="{y}" width="{w}" height="{w*518/382}" viewBox="0 0 382 518"><defs><clipPath id="device-outline"><path d="{outline}"/></clipPath></defs><g clip-path="url(#device-outline)">'+image(ui_file(name),69,78,246,322)+image(SKIN,0,0,382,518)+'</g></svg>'
def svg(body,w=1000,h=1000):
 landscape=BASE/'source/road-landscape.png'
 # A quiet cream fade protects headings; hills and a road add depth at the base.
 scene=f'<image href="{uri(landscape)}" x="0" y="0" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice"/>'
 fade='<defs><linearGradient id="scene-fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF8EB" stop-opacity="0.18"/><stop offset="0.7" stop-color="#FFF8EB" stop-opacity="0.25"/><stop offset="1" stop-color="#FFF8EB" stop-opacity="0.05"/></linearGradient></defs>' if w>h else '<defs><linearGradient id="scene-fade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF8EB" stop-opacity="0.65"/><stop offset="0.7" stop-color="#FFF8EB" stop-opacity="0.86"/><stop offset="1" stop-color="#FFF8EB" stop-opacity="0.45"/></linearGradient></defs>'
 return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+rect(0,0,w,h,CREAM,0)+scene+fade+rect(0,0,w,h,'url(#scene-fade)',0)+body+'</svg>'
def save(name,body,w=1000,h=1000):
 p=OUT/(name+'.svg');p.write_text(svg(body,w,h));return {'name':name,'svg':str(p),'width':w,'height':h}
def hero_callout(zh,en,x,y,color,points,english_only=False):
 # Both variants share the device, leaders and background. Only headings differ.
 if english_only:
  body=text(en,x,y+15,30,NAVY,True)
 else:
  body=text(zh,x,y,29,NAVY,True,family='Arial, Heiti SC, PingFang SC, sans-serif')
  body+=text(en,x,y+29,21,color,True)
 body+=f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>'
 px,py=points.split()[-1].split(',')
 return body+f'<circle cx="{px}" cy="{py}" r="5" fill="{color}" stroke="white" stroke-width="2"/>'

def dashboard_hero(english_only=False):
 # Keep the Store's 1440x720 hero format; fade the existing paved-road artwork.
 callout=lambda *args:hero_callout(*args,english_only=english_only)
 body='<rect width="1440" height="720" fill="#FFF8EB" fill-opacity="0.68"/>'
 body+=bolt(43,38,1.2)+text('Fast Rider',101,88,65,BLUE,True)
 body+=text('Your ride. One screen.',45,132,26,NAVY,True)
 body+='<ellipse cx="720" cy="701" rx="180" ry="12" fill="#152B3B" fill-opacity="0.08"/>'
 body+=device(505,128,430,'default')
 body+=callout('心率与心率区间','Heart rate + zone',48,229,'#C9003C','48,271 457,271 548,271 613,294')
 body+=callout('功率与功率区间','Power + zone',1000,229,BLUE,'1392,271 979,271 910,271 839,294')
 body+=callout('骑行实时数据','Live cycling data',48,398,'#00836D','48,440 457,440 548,440 626,413')
 body+=callout('全程 / 单圈统计','All / Lap stats',1000,398,'#006D87','1392,440 979,440 911,440 838,422')
 body+=callout('功率趋势图','Power graph',48,567,'#AC4A00','48,609 457,609 548,609 640,542')
 return body

def screen_frame(number, heading, subtitle, night=False):
 bg='#F6F8FC' if night else CREAM
 body=rect(0,0,1000,1000,bg,0)
 body+=bolt(42,31,.6)+text('Fast Rider',76,53,24,BLUE,True)
 body+=text(f'{number:02d} / 04',958,53,19,'#53636D',False,'end')
 body+=text(heading,500,115,46,NAVY,True,'middle')
 body+=text(subtitle,500,157,24,'#53636D',False,'middle')
 return body

def save_screen(name,body):
 p=OUT/(name+'.svg')
 p.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000">'+body+'</svg>')
 return {'name':name,'svg':str(p),'width':1000,'height':1000}

def screen_cards():
 jobs=[]
 body=screen_frame(1,'Your ride. One screen.','Power, heart rate, bike data, lap stats + graph.')
 body+='<circle cx="500" cy="563" r="344" fill="#EAF0FF"/>'
 body+=device(210,180,580,'default')
 jobs.append(save_screen('04-screen-01-ride-day',body))
 body=screen_frame(2,'Double-tap. Ding!','A two-second bell, even without a native bike bell.')
 body+='<circle cx="500" cy="563" r="344" fill="#EAF0FF"/>'
 body+=device(210,180,580,'default')
 # Only the left interaction area is marked; the native data stays untouched.
 body+='<circle cx="379" cy="571" r="28" fill="#004CFF" fill-opacity="0.08" stroke="#004CFF" stroke-width="3"/><circle cx="379" cy="571" r="40" fill="none" stroke="#004CFF" stroke-width="2" stroke-dasharray="5 6"/>'
 body+=rect(787,324,167,175,'#FFFFFF',32)
 body+=f'<g transform="translate(824,348)" stroke="{NAVY}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"><path d="M0 70h90l-9-14V30c0-40-72-40-72 0v26Z" fill="#FFD35A"/><path d="M36 81q9 15 18 0" fill="none"/><path d="m-12 1-9-7m123 7 9-7m-120 36h-11m132 0h11" fill="none"/></g>'
 body+=text('2 taps',870,477,24,BLUE,True,'middle')
 body+=text('Touch models with tone support.',500,981,18,'#53636D',False,'middle')
 jobs.append(save_screen('04-screen-02-touch-bell',body))
 body=screen_frame(3,'Pause. See your ride.','Automatically switches to whole-ride statistics.')
 body+='<circle cx="500" cy="563" r="344" fill="#E4F1EB"/>'
 body+=device(210,180,580,'paused')
 jobs.append(save_screen('04-screen-03-auto-summary',body))
 body=screen_frame(4,'Day or night. Clear.','Automatically follows your Edge display theme.',True)
 body+=rect(0,193,500,807,CREAM,0)+rect(500,193,500,807,'#E6EDF8',0)
 body+=device(10,235,480,'default')+device(510,235,480,'night')
 body+=text('DAY',250,937,26,NAVY,True,'middle')+text('NIGHT',750,937,26,BLUE,True,'middle')
 jobs.append(save_screen('04-screen-04-day-night',body))
 return jobs

def main():
 jobs=[save('01-hero-en',dashboard_hero(english_only=True),1440,720),
       save('01-hero-bilingual',dashboard_hero(),1440,720)]+screen_cards()
 (OUT/'jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
 env=dict(os.environ)
 subprocess.run([env.get('NODE','node'),str(BASE/'render.cjs'),str(OUT/'jobs.json')],check=True,env=env)
 subprocess.run([sys.executable,str(BASE/'build-preview.py')],check=True)
if __name__=='__main__':main()
