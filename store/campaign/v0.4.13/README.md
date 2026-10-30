# Fast Rider 商店宣传材料 · v0.4.13

沿用戴骑行太阳镜的男性公路骑手、蓝色闪电与铺装道路场景。Hero和八张功能图全部换成当前原生界面，新增暂停统计与日夜模式；设备外侧白底仍采用矢量轮廓裁切。

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

按此前已确认的表单规格导出：Hero1440×720且小于2048KB；封面500×500且小于300KB；设备图标128×128，其中一个限制为Garmin64色立方体；八张功能图1000×1000且每张小于150KB。

| 文件 | 尺寸 | bytes |
| --- | --- | --- |
| [01-hero-en.png](upload/01-hero-en.png) | 1440×720 | 1,095,979 |
| [04-screen-01-one-screen.jpg](upload/04-screen-01-one-screen.jpg) | 1000×1000 | 135,862 |
| [04-screen-02-touch-bell.jpg](upload/04-screen-02-touch-bell.jpg) | 1000×1000 | 140,753 |
| [04-screen-03-z2-training.jpg](upload/04-screen-03-z2-training.jpg) | 1000×1000 | 136,364 |
| [04-screen-04-threshold-intervals.jpg](upload/04-screen-04-threshold-intervals.jpg) | 1000×1000 | 141,507 |
| [04-screen-05-color-coded.jpg](upload/04-screen-05-color-coded.jpg) | 1000×1000 | 138,977 |
| [04-screen-06-tap-controls.jpg](upload/04-screen-06-tap-controls.jpg) | 1000×1000 | 135,022 |
| [04-screen-07-paused-summary.jpg](upload/04-screen-07-paused-summary.jpg) | 1000×1000 | 137,549 |
| [04-screen-08-day-night.jpg](upload/04-screen-08-day-night.jpg) | 1000×1000 | 147,072 |
| [02-cover-500.png](upload/02-cover-500.png) | 500×500 | 299,584 |
| [03-device-icon-24-bit.png](upload/03-device-icon-24-bit.png) | 128×128 | 26,793 |
| [03-device-icon-64-color.png](upload/03-device-icon-64-color.png) | 128×128 | 3,098 |

上次页面最多接收五张功能图。01–05可用作基础组合；若重点介绍最新暂停页与日夜模式，可选择01、02、03、07、08，或按用途替换。06点击切换图可备用。图片数量上限以当前上传页面为准。

新增07展示AVG HR、Avg PWR、NP、DIST、ASC、Avg CAD与Avg SPD，以及数字后的小字单位、顶右时钟。08展示最新夜间界面。Z2示例固定FTP250W、180W；阈值示例为245W与恢复交替，第三个20分钟段进行中。图中数据均为合成，独立色条和训练块为编辑示意。

## 使用与再生成

直接打开[index.html](index.html)预览和复制文案，所有上传文件在`upload/`。本轮交付为本地素材与安装包，未更新或提交商店页面。

在仓库根目录执行`python3 store/campaign/v0.4.13/render.py`，需要Node+sharp及本机Edge840设备包；可设置NODE、NODE_PATH、CIQ_DEVICE_HOME。`prepare-snapshots.py`为当前源码准备隔离的Z2、阈值、点击切换示例，用官方monkeyc编译后通过模拟器File → Save Screen Capture导出到source/。生产源码与安装包不包含这些示例输入。

[assets.json](assets.json)记录尺寸、大小和SHA256；[source/captures.json](source/captures.json)记录原生截图哈希。当前版重用的骑手、封面和背景来源见[PROMPTS.json](PROMPTS.json)，提示词与原图哈希保留。最终界面未被AI重画，机身来自官方SDK皮肤，未将皮肤作为独立资源复制进仓库。Garmin保留设备外观与商标权。
