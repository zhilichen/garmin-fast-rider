#!/usr/bin/env python3
"""Generate small BMFont atlases matching the approved 246x322 design.

Requires Pillow; source fonts and their licenses are bundled in third_party/fonts.
Only raster glyph subsets are packaged; no TTF files are copied to the app.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import argparse
import math

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

# Keep the original faces as width-constrained fallbacks. Larger screens gain
# numeric emphasis wherever it fits, rather than dropping straight to a smaller
# face when a three-digit cadence or decimal speed is too wide.
EMPHASIS_SPECS = [
    ('LiveEmphasis', 'RobotoCondensed-Bold.ttf', 46, '0123456789.:-'),
    ('StatsEmphasis', 'RobotoCondensed-Bold.ttf', 36, '0123456789.:-'),
    ('AverageEmphasis', 'RobotoCondensed-Bold.ttf', 68, '0123456789-'),
    ('RemainingEmphasis', 'RobotoCondensed-Bold.ttf', 25, '0123456789().-'),
]
# Tall, narrow numeric roles are shared by live cells and enlarged ride distance.
# Keep the four live numeric role indices while enlarging their visible ink.
SIDE_SPECS = [
    ('LiveSide68', 'RobotoCondensed-Bold.ttf', 68, '0123456789.-'),
    ('LiveSide60', 'RobotoCondensed-Bold.ttf', 60, '0123456789.-'),
    ('LiveSide54', 'RobotoCondensed-Bold.ttf', 54, '0123456789.-'),
    ('LiveSide46', 'RobotoCondensed-Bold.ttf', 46, '0123456789.-'),
    ('LiveSideLabel13', 'RobotoCondensed-Bold.ttf', 13, 'GEARPMH'),
    ('LiveSidePercent22', 'RobotoCondensed-Bold.ttf', 22, '%'),
]

SUMMARY_SPECS = [
    ('SummaryLabel14', 'DejaVuSans_Cd_SemiBold_WGL4.ttf', 14,
     '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz %().:-<>'),
]

RIDE_SPECS = [
    ('PrimaryCompact58', 'RobotoCondensed-Bold.ttf', 58, '0123456789-'),
    ('RemainingRide30', 'RobotoCondensed-Bold.ttf', 30, '0123456789().-'),
]
SECOND_SPECS = [
    ('RideSeconds32', 'RobotoCondensed-Bold.ttf', 21, '0123456789:'),
    ('RideSeconds30', 'RobotoCondensed-Bold.ttf', 19, '0123456789:'),
    ('RideSeconds26', 'RobotoCondensed-Bold.ttf', 18, '0123456789:'),
    ('RideSeconds18', 'DejaVuSans_Cd_SemiBold_WGL4.ttf', 12, '0123456789:'),
    ('SummaryValue46', 'RobotoCondensed-Bold.ttf', 46, '0123456789.-'),
]
SECOND_LARGE_SPECS = [
    ('RideSeconds46', 'RobotoCondensed-Bold.ttf', 31, '0123456789:'),
    ('RideSeconds36', 'RobotoCondensed-Bold.ttf', 24, '0123456789:'),
]
# Keep the original broad Meta18 atlas for reproducibility, but load only the
# characters the dashboard uses. Glyph raster, advances and role index stay equal.
RESOURCE_ONLY_SPECS = [
    ('MetaDisplay18', 'DejaVuSans_Cd_SemiBold_WGL4.ttf', 18,
     '0123456789AFGLMPRVWadefilmprst %().:-<>'),
]

SECOND_PARENTS = {'RideSeconds46':'LiveEmphasis', 'RideSeconds36':'StatsEmphasis',
    'RideSeconds32':'Stats32', 'RideSeconds30':'Stats30', 'RideSeconds26':'Chart26', 'RideSeconds18':'Meta18'}

BASE_ORDER = ['Primary58', 'Live38', 'Average54', 'Meta18', 'Chart26',
    'Stats32', 'Average36', 'Stats30', 'ZoneDigit44', 'SmallZ16',
    'SmallZ10', 'Climb18', 'Units18', 'Remaining24', 'Remaining22', 'Remaining21']

def generate(font_dir, out, scale, metrics_path, emphasize=False):
    out.mkdir(parents=True, exist_ok=True)
    resources = ['<fonts>']
    ink = {}
    numeric = {}
    specs = FONT_SPECS + (EMPHASIS_SPECS if emphasize else []) + SIDE_SPECS + SUMMARY_SPECS + RIDE_SPECS + (SECOND_LARGE_SPECS if emphasize else []) + SECOND_SPECS + RESOURCE_ONLY_SPECS
    for name, filename, base_size, characters in specs:
        size = max(1, math.floor(base_size*scale) if name in ('Chart26', 'Remaining21') else round(base_size*scale))
        if name in SECOND_PARENTS:
            parent_size,parent_top,_ = ink[SECOND_PARENTS[name]]
            target = round(parent_top*2/3)
            def score(candidate):
                probe = ImageFont.truetype(str(font_dir/filename),candidate,layout_engine=ImageFont.Layout.BASIC)
                cap = max(-probe.getbbox(c,anchor='ls')[1] for c in characters)
                return abs(cap-target),abs(candidate-parent_size*2/3)
            size = min(range(max(1,parent_size//3),parent_size),key=score)
        # These atlases contain individual Latin glyphs. Explicit BASIC layout
        # keeps their advances independent of optional host RAQM/HarfBuzz builds.
        font = ImageFont.truetype(str(font_dir / filename), size, layout_engine=ImageFont.Layout.BASIC)
        narrow = name in ('LiveSide68', 'LiveSide60', 'LiveSide54', 'LiveSide46', 'PrimaryCompact58')
        horizontal = .78 if name == 'PrimaryCompact58' else ({'LiveSide68':.50,'LiveSide60':.56,'LiveSide54':.48,'LiveSide46':.42}.get(name,1.0))
        glyphs=[]; x=y=1; row=0
        character_fonts = {}
        if name.startswith('Remaining'):
            # Keep regular-weight parentheses at the bold digits' cap height;
            # they must not enlarge the text backdrop into neighboring rows.
            cap = max(-font.getbbox(c, anchor='ls')[1] for c in '0123456789')
            choices = [ImageFont.truetype(str(font_dir / 'RobotoCondensed-Regular.ttf'), n, layout_engine=ImageFont.Layout.BASIC) for n in range(8, size+1)]
            small = min(choices, key=lambda f: abs((f.getbbox('(', anchor='ls')[3]-f.getbbox('(', anchor='ls')[1])-cap))
            for c in '()':
                b = small.getbbox(c, anchor='ls'); h = b[3]-b[1]
                shift = -cap-b[1]+(cap-h)//2
                character_fonts[c] = (small, shift)
        for c in sorted(set(characters)):
            face, shift = character_fonts.get(c, (font, 0))
            raw = face.getbbox(c, anchor='ls')
            box = (math.floor(raw[0]*horizontal), raw[1], math.ceil(raw[2]*horizontal), raw[3]) if narrow else (raw[0], raw[1]+shift, raw[2], raw[3]+shift)
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
            if narrow:
                # Rasterize from the vector source at 4x into the narrow target,
                # retaining grayscale AA rather than stretching an existing atlas.
                raw = face.getbbox(c, anchor='ls')
                mask = Image.new('L', ((raw[2]-raw[0])*4, h*4), 0)
                high = ImageFont.truetype(str(font_dir / filename), size*4, layout_engine=ImageFont.Layout.BASIC)
                ImageDraw.Draw(mask).text((-raw[0]*4,-raw[1]*4),c,font=high,anchor='ls',fill=255)
                mask = mask.resize((w,h),Image.Resampling.LANCZOS)
                # Remove sub-3% resampling halos: invisible on MIP, but they
                # otherwise inflate every digit's measured ink width.
                mask = mask.point([0 if value < 8 else value for value in range(256)])
                atlas.paste((255,255,255),(x,y,x+w,y+h),mask)
            elif name.startswith('SmallZ'):
                # Add a quarter-pixel stroke within the glyph bounds. Render at
                # 4x so the small Z gains weight without a whole-pixel outline.
                raster_scale = 4
                mask = Image.new('L', (w*raster_scale, h*raster_scale), 0)
                heavy = ImageFont.truetype(str(font_dir / filename), size*raster_scale, layout_engine=ImageFont.Layout.BASIC)
                ImageDraw.Draw(mask).text((-box[0]*raster_scale, (-box[1]+shift)*raster_scale), c,
                    font=heavy, anchor='ls', fill=255, stroke_width=1, stroke_fill=255)
                mask = mask.resize((w,h), Image.Resampling.LANCZOS)
                atlas.paste((255,255,255), (x,y,x+w,y+h), mask)
            else:
                draw.text((x-box[0],y-box[1]+shift),c,font=face,anchor='ls',fill=(255,255,255))
            advance = max(w,round(face.getlength(c)*horizontal)) if narrow else round(face.getlength(c))
            # Keep full glyphs in CIQ. Optical spacing is applied at draw time,
            # rather than reducing advance widths and clipping imported glyphs.
            if name.startswith('Remaining') or name == 'Units18':
                advance = max(advance, w)
            offset = 0 if name.startswith('Remaining') else box[0]
            lines.append(f'char id={ord(c)} x={x} y={y} width={w} height={h} xoffset={offset} yoffset={size+box[1]} xadvance={advance} page=0 chnl=15')
        numeric[name] = {}
        for c,x,y,w,h,box in glyphs:
            bounds = atlas.crop((x,y,x+w,y+h)).convert('L').getbbox()
            offset = 0 if name.startswith('Remaining') else box[0]
            numeric[name][c] = (offset+bounds[0], offset+bounds[2]) if bounds else (0,0)
        atlas.save(out/f'{name}.png')
        (out/f'{name}.fnt').write_text('\n'.join(lines)+'\n')
        ink[name] = (size, max(-g[-1][1] for g in glyphs), max(g[-1][3] for g in glyphs))
        # Preserve grayscale coverage; the CIQ default is a 1-bit font.
        resources.append(f'  <font id="{name}" filename="{name}.fnt" antialias="true"/>')
    (out/'fonts.xml').write_text('\n'.join(resources+['</fonts>'])+'\n')
    # Runtime drawText paints its logical line box when AA has a solid backdrop.
    # Clip to actual glyph bounds so adjacent rows cannot erase one another.
    order = BASE_ORDER + ([spec[0] for spec in EMPHASIS_SPECS] if emphasize else []) + [spec[0] for spec in SIDE_SPECS + SUMMARY_SPECS + RIDE_SPECS + (SECOND_LARGE_SPECS if emphasize else []) + SECOND_SPECS]
    metrics = '// Generated by scripts/generate-fonts.py; actual glyph ink bounds.\nmodule FontInk {\n'
    for field, column in [('SIZES', 0), ('TOP', 1), ('BOTTOM', 2)]:
        metrics += f'    const {field} = '+str([ink[name][column] for name in order])+';\n'
    # Edge 840's BMFont raster begins one pixel below source atlas offsets.
    # Include that native bottom row without changing the approved baselines.
    metrics += '    const NATIVE_BOTTOM_PAD = 1;\n'
    # Actual horizontal ink bounds allow same-size digit tracking via original
    # glyphs. CIQ crops glyphs whose BMFont xadvance is tightened, so keep font
    # resources intact and clip each original glyph only to its actual ink.
    for field, column in [('NUMERIC_LEFT', 0), ('NUMERIC_RIGHT', 1)]:
        rows = [[numeric[name].get(c, (0,0))[column] for c in '0123456789.-()mi:'] for name in order]
        metrics += f'    const {field} = '+str(rows)+';\n'
    metrics += f'    const PACK_STATS = {str(emphasize).lower()};\n'
    metrics += '    const LIVE_FACES = '+str(([16,1,17] if emphasize else [1])+[5,7,4])+';\n'
    metrics += '    const STATS_FACES = '+str(([16,17] if emphasize else [])+[5,7,4])+';\n'
    metrics += '    const AVERAGE_FACES = '+str(([18] if emphasize else [])+[2,6])+';\n'
    metrics += '    const DISTANCE_PAIRS = '+str(([[17,19]] if emphasize else [])+[[5,13],[7,14],[4,15]])+';\n'
    side = len(BASE_ORDER) + (len(EMPHASIS_SPECS) if emphasize else 0)
    metrics += '    const LIVE_SIDE_FACES = '+str(list(range(side,side+4)))+';\n'
    metrics += f'    const LIVE_SIDE_LABEL = {side+4};\n'
    metrics += f'    const LIVE_SIDE_PERCENT = {side+5};\n'
    metrics += f'    const SUMMARY_LABEL = {side+6};\n'
    metrics += '    const SUMMARY_INT_FACES = '+str(([16,17] if emphasize else [])+[6,5,7,4])+';\n'
    metrics += '    const SUMMARY_VALUE_FACES = '+str(([16] if emphasize else [])+[order.index('SummaryValue46'),side+1,side+2,side+3,1,5,7,4])+';\n'
    metrics += '    const SUMMARY_INT_VALUE_FACES = '+str([2,order.index('SummaryValue46'),side+1,side+2,side+3,1,5,7,4])+';\n'
    metrics += '    const SUMMARY_DISTANCE_PAIRS = '+str(([[16,19]] if emphasize else [])+[[order.index('SummaryValue46'),13],[side+1,13],[side+2,13],[side+3,14],[1,13],[5,13],[7,14],[4,15]])+';\n'
    metrics += f'    const PRIMARY_COMPACT = {order.index("PrimaryCompact58")};\n'
    time_parents = (['LiveEmphasis','StatsEmphasis'] if emphasize else [])+['Stats32','Stats30','Chart26','Meta18']
    seconds_names = (['RideSeconds46','RideSeconds36'] if emphasize else [])+['RideSeconds32','RideSeconds30','RideSeconds26','RideSeconds18']
    metrics += '    const RIDE_TIME_PAIRS = '+str([[order.index(p),order.index(c)] for p,c in zip(time_parents,seconds_names)])+';\n'
    metrics += '    const RIDE_DISTANCE_PAIRS = '+str([[side+i,order.index('RemainingRide30')] for i in range(4)]+[[1,13],[5,13],[7,14],[4,15]])+';\n'
    metrics += '    const RIDE_STACK_PAIRS = '+str([[side,13],[side+1,13],[side+2,14],[side+3,14],[1,15],[5,15],[7,15],[4,15]])+';\n'
    metrics += '    function resources() {\n        return ['+', '.join('Rez.Fonts.'+('MetaDisplay18' if name == 'Meta18' else name) for name in order)+'];\n    }\n'
    metrics += '}\n'
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(metrics)

if __name__=='__main__':
    import json
    root=Path(__file__).resolve().parents[1]
    profiles=json.loads((root/'config/devices.json').read_text())['profiles']
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--font-dir',type=Path,default=root/'third_party/fonts')
    p.add_argument('--profile',choices=['all']+list(profiles),default='all')
    args=p.parse_args()
    for key,profile in profiles.items():
        if args.profile not in ('all',key):continue
        generate(args.font_dir,root/'resources/fonts'/key,profile['width']/246,root/'config/display'/key/'FontInk.mc',profile.get('emphasize_numbers',False))
