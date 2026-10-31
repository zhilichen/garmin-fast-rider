# Fast Rider 商店宣传材料 · v0.4.13

Hero采用中间居中的真实Edge840日间骑行界面，五组引线以中英双语标出心率与区间、功率与区间、骑行实时数据、全程/单圈统计和功率趋势图。放大Fast Rider名称，淡色公路背景保持标题清晰，无额外简述。四张PNG功能图改为设备与真实屏幕为主体，配小号Fast Rider标识及简短英文说明；设备外侧白底仍采用矢量轮廓裁切。

## 可填写内容

| 字段 | 内容 |
| --- | --- |
| App File | `FastRider-0.4.13.iq`，完整Downloads素材包包含；源码仓库中从`dist/connect-iq/v0.4.13`导出取得 |
| Title | [Fast Rider](copy/title-en.txt)，10字符 |
| Description | [英文](copy/description-en.txt)，4000字符内；[中文](copy/description-zh-CN.txt)可选 |
| What’s New | [英文更新说明](copy/whats-new-en.txt) |
| Category | Cycling，子分类如不可选则留空 |
| User data collection / ANT+ encode-decode / regional limits | No / No / No |
| Activity types | Cycling及相关骑行子类 |
| Public support email | 沿用已设置的公开支持邮箱；不复制个人邮箱到公开仓库 |
| Source / support | https://github.com/zhilichen/garmin-fast-rider |
| Privacy | https://github.com/zhilichen/garmin-fast-rider/blob/main/PRIVACY.md |
| Monetization / companion app / hardware URL / video | No / 留空 / 留空 / 留空 |
| Automatic device migration | 建议No，新增型号后明确验收 |
| Review notifications | 按你的偏好 |

## 图片

Hero 保持1440×720且小于2048KB。四张Screen Images均为1000×1000 PNG，每张严格小于150,000 bytes；以屏幕与Edge840外形为主体，使用小号Fast Rider标识和简短英文说明。封面500×500小于300KB；设备图标128×128，其中一个限制为Garmin64色立方体。

按01–04顺序上传这四张功能图：

1. **Your ride. One screen.** 白天骑行，展示功率、心率、实时骑行数据、圈统计和功率图。
2. **Double-tap. Ding!** 双击左侧区域，播放两秒电子铃声；需要触控及设备提示音支持。
3. **Pause. See your ride.** 暂停时自动切换全程统计。
4. **Day or night. Clear.** 日夜界面对照，跟随Edge数据字段主题。

| 文件 | 尺寸 | bytes |
| --- | --- | --- |
| [01-hero-en.png](upload/01-hero-en.png) | 1440×720 | 658,097 |
| [04-screen-01-ride-day.png](upload/04-screen-01-ride-day.png) | 1000×1000 | 76,362 |
| [04-screen-02-touch-bell.png](upload/04-screen-02-touch-bell.png) | 1000×1000 | 76,118 |
| [04-screen-03-auto-summary.png](upload/04-screen-03-auto-summary.png) | 1000×1000 | 75,876 |
| [04-screen-04-day-night.png](upload/04-screen-04-day-night.png) | 1000×1000 | 86,813 |
| [02-cover-500.png](upload/02-cover-500.png) | 500×500 | 299,584 |
| [03-device-icon-24-bit.png](upload/03-device-icon-24-bit.png) | 128×128 | 26,793 |
| [03-device-icon-64-color.png](upload/03-device-icon-64-color.png) | 128×128 | 3,098 |

图中数值为合成示例；设备内使用原生模拟器导出的界面，未用AI重绘。PNG优先无损导出，必要时使用调色板压缩以满足体积限制。除双击响铃图的点击示意标记外，未改写屏幕内容。此前的八张JPG已从当前upload目录移除，历史版本可从Git历史或v0.4.1素材中查看。

## 使用与再生成

直接打开[index.html](index.html)预览和复制文案，所有上传文件在`upload/`。本轮交付为本地素材与安装包，未更新或提交商店页面。

在仓库根目录执行`python3 store/campaign/v0.4.13/render.py`，需要Node+sharp及本机Edge840设备包；可设置NODE、NODE_PATH、CIQ_DEVICE_HOME。`prepare-snapshots.py`为当前源码准备隔离的Z2、阈值、点击切换示例，用官方monkeyc编译后通过模拟器File → Save Screen Capture导出到source/。生产源码与安装包不包含这些示例输入。

[assets.json](assets.json)记录尺寸、大小和SHA256；[source/captures.json](source/captures.json)记录原生截图哈希。当前版重用的骑手、封面和背景来源见[PROMPTS.json](PROMPTS.json)，提示词与原图哈希保留；当前四张功能图不使用骑手插画。最终界面未被AI重画，机身来自官方SDK皮肤，未将皮肤作为独立资源复制进仓库。Garmin保留设备外观与商标权。
