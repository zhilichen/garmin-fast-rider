# FastRider 商店发布素材 · v0.4.1

英文标题、介绍和更新说明均可直接复制；视频不需要填写。所有上传图片位于 `upload/`，已按本次实际网页表单的尺寸与文件上限导出。素材采用轻快卡通骑手、gravel bike、蓝色闪电和奶油白背景；设备展示为真实 Edge 840 外观与未经重画的原生界面截图。

## 表单填写对照

| 网页字段 | 填写内容／选择 | 文件或说明 |
| --- | --- | --- |
| App File | FastRider-0.4.1.iq | 本地 `~/Downloads/FastRider-0.4.1.iq`；不是 PRG 或 ZIP |
| Language | English | 当前网页已经添加英文 |
| Title，最多50字 | FastRider – Ride in Color | [独立文本](copy/title-en.txt)，25字符 |
| Description，最多4000字 | 使用完整英文介绍 | [独立文本](copy/description-en.txt)，包含一屏信息、车铃、Z2／阈值训练、Zone、操作及数据说明 |
| What’s New，最多4000字 | First public release — v0.4.1 | [独立文本](copy/whats-new-en.txt) |
| Hero Image | `01-hero-en.png` | 1440×720 PNG，小于2048KB |
| Category | Cycling | 已在当前表单确认该选项 |
| Subcategory | 留空 | 选择Cycling后，此表单的子分类仍不可选 |
| Collect user data? | No | 本地读取活动／资料数据，不向开发者收集或上传 |
| Privacy URL（若需要） | `https://github.com/zhilichen/garmin-fast-rider/blob/main/PRIVACY.md` | 已公开；即便选No也可在介绍中保留链接 |
| Decode/encode ANT+ profiles? | No | 应用读取Garmin管理的数据，不直接实现ANT+配置文件 |
| Regional limits? | No | 无应用层面的地区限制 |
| Cover Image | `02-cover-500.png` | 500×500、不透明sRGB PNG，小于300KB |
| Add Icons for App Store on Device? | Yes | 两个128×128文件 |
| Device 64 Color | `03-device-icon-64-color.png` | 固定Garmin RGB立方体色板，每个通道仅0/85/170/255，最多64色 |
| Device 24 bit Color | `03-device-icon-24-bit.png` | 128×128、24位sRGB PNG |
| Screen Images | `04-screen-01…06` | 六张1000×1000 JPG，每张小于150KB；按文件编号选择 |
| Preview Video | 留空 | 本轮不制作视频 |
| Activity Types | Cycling | 可同时选择全部骑行子类，包括Gravel/Unpaved、Road、Indoor、Virtual、MTB等；不选非骑行大类 |
| Email Address | **由你填入愿意公开的支持邮箱** | 网页会公开展示；素材包不代填个人邮箱 |
| Source Code URL | `https://github.com/zhilichen/garmin-fast-rider` | 源码与issue支持入口 |
| Review Notification | 建议Yes | 可按你的通知偏好修改 |
| App Migration | 建议No | 当前仅发布已适配／验收的12个目标；新增型号后明确验证再扩展 |
| Monetization | No | 免费，无解锁收费、订阅或捐赠入口 |
| iOS / Android Companion App URL | 留空 | 不需要配套手机应用 |
| Additional Hardware Product URL | 留空 | 不限定某款额外硬件；功率／心率／电子档位等按对应兼容数据源显示 |

## 图片顺序与卖点

| 文件 | 用途与主标题 |
| --- | --- |
| 01-hero-en.png | Your ride. One screen. / Color-coded effort / Touch bell / Z2 + threshold |
| 02-cover-500.png | 列表封面：无文字的卡通骑手头像 |
| 03-device-icon-64-color.png | 低色数设备商店图标 |
| 03-device-icon-24-bit.png | 全彩设备商店图标 |
| 04-screen-01-one-screen.jpg | Your key numbers. One screen. |
| 04-screen-02-touch-bell.jpg | No native bell? Double-tap. Ding! |
| 04-screen-03-z2-training.jpg | Ride blue. Hold your Z2. |
| 04-screen-04-threshold-intervals.jpg | Long intervals. Clear targets. / 3 × 20 minutes |
| 04-screen-05-color-coded.jpg | Less decoding. More riding. |
| 04-screen-06-tap-controls.jpg | Tap. Switch. Keep rolling. |

首批发布优先展示一屏信息、车铃、Z2与阈值训练，后两张补充完整配色和点击交互。Z2与阈值卡已使用专用合成输入在原生840模拟器重新导出：180W/FTP250W稳态Z2，以及245W阈值段与恢复段交替的3×20分钟示例（第三段进行中）。实际渲染代码未改动，仅隔离的示例数据不同。右侧训练条为独立编辑示意。六张均为功能介绍图；若网页的图片数量上限不足，可省去后两张，核心功能已经覆盖。可另外从 `docs/validation/screens/` 选取原生尺寸的纯截图；本素材中的设备展示已经包含840实机外形。

英文文案没有将所有数字都宣称为按Zone变色：实际支持功率、心率、踏频和坡度配色。车铃明确为触屏机型上的两秒电子提示音组合，非Garmin原生车铃，音色与响度取决于硬件。Z2蓝色、Z4橘色与生产代码一致。训练内容是示例，不将字段描述为训练计划执行器。

## 可选中文

[中文介绍](copy/description-zh-CN.txt)作为本地参考或新增简体中文语言时的正文。主Hero及功能图为英文。若只上传本包主图，可先仅发布英文语言；无需添加空白的中文语言页。

## IQ签名状态

本包引用的IQ为735,207 bytes，SHA256：
`b24cf77ca6a3afd8615c5541ffd9b853dbd2d7810c5e3bf996230c6a74c57ced`。

本地已使用IQ内的`dev_key.pub`对原始`manifest.xml`与`manifest.sig2`执行OpenSSL SHA256签名验证，结果为`Verified OK`。当前网页却仍显示`Signature check failed.`。这两个结果均如实记录；本地验证不能证明Garmin服务端已接受签名，也没有通过重签／替换密钥来绕过错误。提交前请在网页重新选择Downloads内同名IQ并确认状态；若错误仍存在，需要继续检查Garmin的上传校验，不要将“Status: Verified”单独理解为签名通过。

你自行上传并提交。本轮不提交审核、不接受开发者协议，也不填入公开联系邮箱。

## 再生成与来源

在仓库根目录运行 `python3 store/campaign/v0.4.1/render.py`。需要Node.js、sharp及本机Edge840设备包；可通过`NODE`、`NODE_PATH`、`CIQ_DEVICE_HOME`指定安装位置。脚本只负责SVG文字／版式排版和最终尺寸、色板、压缩导出，不修改应用或原生截图。`prepare-snapshots.py`可重新准备两种训练示例的隔离源码，按其输出jungle文件用官方monkeyc编译并在840模拟器导出即可；示例程序不进入IQ或安装包。

骑手和封面图由内置imagegen生成；提示词见[PROMPTS.json](PROMPTS.json)。所有正文、图形文案均可在render.py或copy/中修改。封面／图标不含Garmin商标；设备外形来自本机官方SDK模拟器皮肤，原生截图来自仓库验收资料。Garmin设备外观与商标权归Garmin所有，代码MIT许可不授予其商标权。硬件皮肤没有作为独立资源复制进仓库。

尺寸和品牌依据：[Garmin官方Connect IQ设计指南](https://developer.garmin.com/brand-guidelines/connect-iq/)。文件大小及Screen Images上限来自2026-10-24实际上传表单。
