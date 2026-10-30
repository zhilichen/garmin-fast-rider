# v0.4.13 顶右时钟与宣传材料刷新

2026-10-29，macOS / JDK17 / Connect IQ SDK9.3.0，合成数据。

停止页时钟以Layout.RIGHT_EDGE为右边界，840对应x244，即右侧2px内边距。时钟数字与总时长保留同一基线，数字顶部约2px；AM/PM保留原小字。其余统计内容、单位、分隔线、图表和骑行页保持原样。

12款机型共558次原生测试、11项Python检查通过；12次test、12次live和1次840 snapshot构建无警告。四种分辨率的停止页日夜均已检查，100:00:00与12:59 AM边界值完整可见。与0.4.12相比，840骑行整页、停止页左侧时长及正文/图表的6项日夜像素对比均为0差异。

| 设备 | 停止日间 | 停止夜间 |
| --- | --- | --- |
| Edge 840 | [日间](edge840-stopped-day.png) | [夜间](edge840-stopped-night.png) |
| Edge 1040 | [日间](edge1040-stopped-day.png) | [夜间](edge1040-stopped-night.png) |
| Edge 850 | [日间](edge850-stopped-day.png) | [夜间](edge850-stopped-night.png) |
| Edge 1050 | [日间](edge1050-stopped-day.png) | [夜间](edge1050-stopped-night.png) |

[840长时长](edge840-stopped-stress-day.png) · [VM矩阵](vm-matrix.json) · [Python检查](python-tests.txt) · [像素比较](pixel-checks.json) · [时钟字形边距](clock-margins.json) · [签名包记录](store-package.json)。

## 宣传材料

[新版完整素材](../../../../store/campaign/v0.4.13/README.md)沿用男性公路骑手、骑行太阳镜和铺装公路背景；Hero和功能图中的设备均使用当前原生界面及真实840外观。更新Z2、3×20分钟阈值与触控示例，增加暂停统计和日夜模式两张图；介绍文字同步当前Zone进度、NP和单位设计。

[尺寸与文件校验](../../../../store/campaign/v0.4.13/assets.json)包含12张图片。所有源界面截图由File → Save Screen Capture导出，未用AI重绘。素材包和IQ均仅准备在本地，本轮未提交商店。
