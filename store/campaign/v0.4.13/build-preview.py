#!/usr/bin/env python3
"""Build the offline Store-kit preview from the current copy and asset manifest."""
from pathlib import Path
import html
import json

BASE = Path(__file__).resolve().parent
VERSION = '0.4.13'
assets = json.loads((BASE/'assets.json').read_text())
e = html.escape
style = '''body{margin:0;background:#fff8eb;color:#152b3b;font:16px/1.65 Arial,sans-serif}main{max-width:1160px;margin:auto;padding:40px 28px}h1{font-size:40px;line-height:1.2;color:#004cff}h2{margin-top:44px}a{color:#004cff}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:22px}.grid img,.hero{display:block;width:100%;border-radius:20px}figure{margin:0}figcaption{font-size:14px;margin:8px 4px 20px}.icons{display:flex;gap:28px;align-items:center;background:white;padding:24px;border-radius:22px;flex-wrap:wrap}.icons img{max-width:220px;max-height:220px}.facts{display:flex;gap:14px;flex-wrap:wrap}.facts span{background:white;border-radius:16px;padding:10px 18px}table{border-collapse:collapse;width:100%;background:white}th,td{padding:12px 16px;text-align:left;vertical-align:top;border-bottom:1px solid #dde1e5}pre{white-space:pre-wrap;background:white;padding:24px;border-radius:18px;font:15px/1.65 Arial,sans-serif}.sub{color:#53636d}.pill{background:#004cff;color:white;border-radius:12px;padding:2px 8px}@media(max-width:750px){.grid{grid-template-columns:1fr}main{padding:24px 16px}h1{font-size:30px}}'''
parts = [f'<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fast Rider · Store Kit {VERSION}</title><style>{style}</style><main>',
    f'<h1>Fast Rider <span class="pill">{VERSION}</span></h1>',
    '<p>两版 Hero（纯英文 / 中英双语）：真实 Edge 840 日间骑行界面、五区功能标注与淡色公路背景；四张 PNG 功能图以设备和真实屏幕为主体。</p>',
    f'<div class="facts"><span>12 款 Edge</span><span>{len(assets)} 张图片</span><span>无需视频</span><span>英文介绍 4000 字符内</span></div>',
    '<p><a href="README.md">填写说明</a> · <a href="copy/description-en.txt">英文介绍</a> · <a href="copy/description-zh-CN.txt">中文介绍</a> · <a href="copy/whats-new-en.txt">What’s New</a></p>',
    '<h2>Hero · English only</h2><a href="upload/01-hero-en.png"><img class="hero" src="upload/01-hero-en.png" alt="Fast Rider English Hero: five dashboard feature callouts"></a>',
    '<h2>Hero · 中英双语</h2><a href="upload/01-hero-bilingual.png"><img class="hero" src="upload/01-hero-bilingual.png" alt="Fast Rider 中英双语 Hero：五区功能标注"></a>',
    '<h2>表单内容</h2><table><tr><th>字段</th><th>内容</th></tr>']
fields = [('App File',f'FastRider-{VERSION}.iq（使用同目录或Downloads中的签名IQ）'),('Title','Fast Rider'),('Category','Cycling'),('Subcategory','如不可选则留空'),('Collect user data?','No'),('ANT+ encode/decode?','No'),('Regional limits?','No'),('Activity types','Cycling及对应骑行子类'),('Public support email','沿用你已设置的公开支持邮箱'),('Source / support','https://github.com/zhilichen/garmin-fast-rider'),('Privacy','https://github.com/zhilichen/garmin-fast-rider/blob/main/PRIVACY.md'),('Monetization','No'),('Review notifications','沿用你的偏好'),('Automatic migration','建议No，新增型号后明确验收'),('Companion / hardware URL / video','留空')]
parts += [f'<tr><td>{e(a)}</td><td>{e(b)}</td></tr>' for a,b in fields]
parts += ['</table>','<h2>封面与设备图标</h2><div class="icons">']
for name in ['02-cover-500.png','03-device-icon-24-bit.png','03-device-icon-64-color.png']:
    parts.append(f'<figure><a href="upload/{name}"><img src="upload/{name}" alt="{name}"></a><figcaption>{name}</figcaption></figure>')
parts += ['</div>','<h2>功能图片</h2><p>四张图按顺序上传：白天骑行、双击响铃、自动停止统计、日夜视图。全部为 PNG，1000×1000，每张严格小于 150,000 bytes。</p><div class="grid">']
for item in assets:
    if item['file'].startswith('04-screen-'):
        name = item['file']
        parts.append(f'<figure><a href="upload/{name}"><img src="upload/{name}" alt="{name}" loading="lazy"></a><figcaption>{name} · {item["width"]}×{item["height"]} · {item["bytes"]:,} bytes</figcaption></figure>')
parts += ['</div>']
for title,name in [('英文介绍','description-en.txt'),('What’s New','whats-new-en.txt'),('中文介绍','description-zh-CN.txt')]:
    content = (BASE/'copy'/name).read_text().strip()
    parts.append(f'<h2>{title} <small class="sub">{len(content)}/4000</small></h2><pre>{e(content)}</pre>')
parts += ['<h2>素材说明</h2><p>截图为合成示例，屏幕由原生模拟器导出。设备外形采用官方SDK皮肤，外侧白底通过轮廓裁切移除。PNG 已压缩以符合商店体积限制；实际数据取决于传感器。商店资料未在本轮自动提交。</p></main></html>']
(BASE/'index.html').write_text('\n'.join(parts))
print('Built offline preview:', BASE/'index.html')
