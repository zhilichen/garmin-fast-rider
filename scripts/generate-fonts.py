#!/usr/bin/env python3
"""Generate small BMFont atlases matching the approved 246x322 design.

Requires Pillow and the fonts shipped in the local Connect IQ SDK installation.
Only raster glyph subsets are packaged; no TTF files are copied to the app.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import argparse

FONT_SPECS = [
    ('Primary58', 'RobotoCondensed-Bold.ttf', 58, '0123456789-'),
    ('Live38', 'RobotoCondensed-Regular.ttf', 38, '0123456789.-'),
    ('Average50', 'RobotoCondensed-Bold.ttf', 50, '0123456789-'),
    ('Average36', 'RobotoCondensed-Bold.ttf', 36, '0123456789-'),
    ('Meta18', 'DejaVuSans_Cd_SemiBold_WGL4.ttf', 18, '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz %().:-<>'),
    ('Chart26', 'RobotoCondensed-Bold.ttf', 26, '0123456789().:-'),
    ('Stats32', 'RobotoCondensed-Bold.ttf', 32, '0123456789.:-'),
    ('Stats30', 'RobotoCondensed-Bold.ttf', 30, '0123456789.:-'),
    ('Footer24', 'RobotoCondensed-Bold.ttf', 24, '0123456789().:-'),
]

def generate(font_dir, out):
    out.mkdir(parents=True, exist_ok=True)
    resources = ['<fonts>']
    for name, filename, size, characters in FONT_SPECS:
        font = ImageFont.truetype(str(font_dir / filename), size)
        glyphs=[]; x=y=1; row=0
        for c in sorted(set(characters)):
            box=font.getbbox(c, anchor='ls'); w=max(1,box[2]-box[0]); h=max(1,box[3]-box[1])
            if x+w+1>256: x=1; y+=row+1; row=0
            glyphs.append((c,x,y,w,h,box)); x+=w+1; row=max(row,h)
        height=1
        while height<y+row+1: height*=2
        atlas=Image.new('RGBA',(256,height),(255,255,255,0))
        draw=ImageDraw.Draw(atlas)
        bold = 1 if 'Bold' in filename else 0
        lines=[f'info face="{name}" size={size} bold={bold} italic=0 unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1',
               f'common lineHeight={size+6} base={size} scaleW=256 scaleH={height} pages=1 packed=0',
               f'page id=0 file="{name}.png"',f'chars count={len(glyphs)}']
        for c,x,y,w,h,box in glyphs:
            draw.text((x-box[0],y-box[1]),c,font=font,anchor='ls',fill=(255,255,255,255))
            lines.append(f'char id={ord(c)} x={x} y={y} width={w} height={h} xoffset={box[0]} yoffset={size+box[1]} xadvance={round(font.getlength(c))} page=0 chnl=15')
        atlas.save(out/f'{name}.png')
        (out/f'{name}.fnt').write_text('\n'.join(lines)+'\n')
        resources.append(f'  <font id="{name}" filename="{name}.fnt"/>')
    (out/'fonts.xml').write_text('\n'.join(resources+['</fonts>'])+'\n')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--font-dir',type=Path,default=Path.home()/'Library/Application Support/Garmin/ConnectIQ/Fonts');args=p.parse_args()
    generate(args.font_dir,Path(__file__).resolve().parents[1]/'resources/fonts')
