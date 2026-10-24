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
    ('Live38', 'RobotoCondensed-Bold.ttf', 38, '0123456789.-'),
    ('Average54', 'RobotoCondensed-Bold.ttf', 54, '0123456789-'),
    ('Average36', 'RobotoCondensed-Bold.ttf', 36, '0123456789-'),
    ('Meta18', 'DejaVuSans_Cd_SemiBold_WGL4.ttf', 18, '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz %().:-<>'),
    ('Chart26', 'RobotoCondensed-Bold.ttf', 26, '0123456789.:-'),
    ('Stats32', 'RobotoCondensed-Bold.ttf', 32, '0123456789.:-'),
    ('Stats30', 'RobotoCondensed-Bold.ttf', 30, '0123456789.:-'),
    ('ZoneDigit44', 'RobotoCondensed-Bold.ttf', 44, '0123456789'),
    ('SmallZ16', 'RobotoCondensed-Bold.ttf', 16, 'Z'),
    ('SmallZ10', 'RobotoCondensed-Bold.ttf', 10, 'Z'),
    ('Climb18', 'RobotoCondensed-Bold.ttf', 18, '0123456789-'),
    ('Units18', 'RobotoCondensed-Regular.ttf', 18, 'mift'),
    ('Remaining24', 'RobotoCondensed-Bold.ttf', 24, '0123456789().-'),
    ('Remaining22', 'RobotoCondensed-Bold.ttf', 22, '0123456789().-'),
    ('Remaining21', 'RobotoCondensed-Bold.ttf', 21, '0123456789().-'),
]

def generate(font_dir, out):
    out.mkdir(parents=True, exist_ok=True)
    resources = ['<fonts>']
    ink = {}
    for name, filename, size, characters in FONT_SPECS:
        font = ImageFont.truetype(str(font_dir / filename), size)
        glyphs=[]; x=y=1; row=0
        character_fonts = {}
        if name.startswith('Remaining'):
            # Keep regular-weight parentheses at the bold digits' cap height;
            # they must not enlarge the text backdrop into neighboring rows.
            cap = max(-font.getbbox(c, anchor='ls')[1] for c in '0123456789')
            choices = [ImageFont.truetype(str(font_dir / 'RobotoCondensed-Regular.ttf'), n) for n in range(8, size+1)]
            small = min(choices, key=lambda f: abs((f.getbbox('(', anchor='ls')[3]-f.getbbox('(', anchor='ls')[1])-cap))
            for c in '()':
                b = small.getbbox(c, anchor='ls'); h = b[3]-b[1]
                shift = -cap-b[1]+(cap-h)//2
                character_fonts[c] = (small, shift)
        for c in sorted(set(characters)):
            face, shift = character_fonts.get(c, (font, 0))
            raw = face.getbbox(c, anchor='ls')
            box = (raw[0], raw[1]+shift, raw[2], raw[3]+shift)
            w=max(1,box[2]-box[0]); h=max(1,box[3]-box[1])
            if x+w+1>256: x=1; y+=row+1; row=0
            glyphs.append((c,x,y,w,h,box)); x+=w+1; row=max(row,h)
        height=1
        while height<y+row+1: height*=2
        # CIQ imports BMFont coverage from luminance. White RGB with only an
        # alpha mask loses its gray edges during import, even with AA enabled.
        atlas=Image.new('RGB',(256,height),(0,0,0))
        draw=ImageDraw.Draw(atlas)
        bold = 1 if 'Bold' in filename else 0
        lines=[f'info face="{name}" size={size} bold={bold} italic=0 unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1',
               f'common lineHeight={size+6} base={size} scaleW=256 scaleH={height} pages=1 packed=0',
               f'page id=0 file="{name}.png"',f'chars count={len(glyphs)}']
        for c,x,y,w,h,box in glyphs:
            face, shift = character_fonts.get(c, (font, 0))
            if name.startswith('SmallZ'):
                # Add a quarter-pixel stroke within the glyph bounds. Render at
                # 4x so the small Z gains weight without a whole-pixel outline.
                scale = 4
                mask = Image.new('L', (w*scale, h*scale), 0)
                heavy = ImageFont.truetype(str(font_dir / filename), size*scale)
                ImageDraw.Draw(mask).text((-box[0]*scale, (-box[1]+shift)*scale), c,
                    font=heavy, anchor='ls', fill=255, stroke_width=1, stroke_fill=255)
                mask = mask.resize((w,h), Image.Resampling.LANCZOS)
                atlas.paste((255,255,255), (x,y,x+w,y+h), mask)
            else:
                draw.text((x-box[0],y-box[1]+shift),c,font=face,anchor='ls',fill=(255,255,255))
            advance = round(face.getlength(c))
            # Optical tracking for the compact mixed-size distance row: retain
            # full glyph width/height and weight, trim only inter-glyph spacing.
            if name.startswith('Remaining') or (name == 'Units18' and c == 'm'):
                advance = max(1, advance-1)
            lines.append(f'char id={ord(c)} x={x} y={y} width={w} height={h} xoffset={box[0]} yoffset={size+box[1]} xadvance={advance} page=0 chnl=15')
        atlas.save(out/f'{name}.png')
        (out/f'{name}.fnt').write_text('\n'.join(lines)+'\n')
        ink[name] = (size, max(-g[-1][1] for g in glyphs), max(g[-1][3] for g in glyphs))
        # Preserve grayscale coverage; the CIQ default is a 1-bit font.
        resources.append(f'  <font id="{name}" filename="{name}.fnt" antialias="true"/>')
    (out/'fonts.xml').write_text('\n'.join(resources+['</fonts>'])+'\n')
    # Runtime drawText paints its logical line box when AA has a solid backdrop.
    # Clip to actual glyph bounds so adjacent rows cannot erase one another.
    order = ['Primary58', 'Live38', 'Average54', 'Meta18', 'Chart26',
             'Stats32', 'Average36', 'Stats30', 'ZoneDigit44', 'SmallZ16',
             'SmallZ10', 'Climb18', 'Units18', 'Remaining24', 'Remaining22', 'Remaining21']
    metrics = '// Generated by scripts/generate-fonts.py; actual glyph ink bounds.\nmodule FontInk {\n'
    for field, column in [('SIZES', 0), ('TOP', 1), ('BOTTOM', 2)]:
        metrics += f'    const {field} = '+str([ink[name][column] for name in order])+';\n'
    metrics += '}\n'
    (Path(__file__).resolve().parents[1]/'source/FontInk.mc').write_text(metrics)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--font-dir',type=Path,default=Path.home()/'Library/Application Support/Garmin/ConnectIQ/Fonts');args=p.parse_args()
    generate(args.font_dir,Path(__file__).resolve().parents[1]/'resources/fonts')
