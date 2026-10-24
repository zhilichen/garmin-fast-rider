# Edge 840 v0.2.1 验证记录

日期：2026-10-24。本轮更新为默认 All、分圈自动显示最新圈、统计功率加粗。macOS、Corretto Java 17、Connect IQ SDK 9.3.0、Edge 840 官方设备包，设备 API 6.0.0。仅安装所需 Edge 设备。

## 自动验证

- demo / live 均针对 `edge840` 构建，无编译告警。
- Garmin VM：**22/22**，详见 [原始输出](simulator-tests.txt)。
- Python：GPX 原型工具回归 **3/3**。
- `nativeRenderStatesTest` 在 Garmin 原生 Dc 上绘制全部 **2×2×3 = 12** 个模式组合，并绘制缺失信号、负坡度、三位速度、四位均功率、12 小时计时和较长总计的回退布局；没有运行异常。测试模式内存不等于真实数据字段堆，因此不以测试 VM 的 freeMemory 作为字段容量证明。
- `bitmapFontMetricsTest` 使用设备 Dc 验证主功率字宽、完整速度、All+长计时、均功率+AVG、圈距离的宽度，以及位图字体 baseline。
- 功率历史覆盖 3s/12s 桶、0 W、重复时间戳、断流/暂停、不跨段连接、原生 Lap 边界、活动重置、20m 窗口及 **24 小时 All 历史压缩**；压缩不丢失活动起点、有效样本总和和数量，每层 ≤160 桶。
- 3s/10s 覆盖两个窗口不同均值、零功率、缺失、重复、暂停、长间隙与时钟回退。
- 交互覆盖三项独立循环、真实输入委托转发、忽略非 TAP/非点击区、切换不重置数据、新 Lap 自动选中最新圈、保持功率与图范围选择、活动重置恢复默认。
- 坡度/踏频颜色覆盖所有精确边界；导航剩余距离覆盖无目的地、空名称、缺失、负数与到达目的地零值。

## 真实模拟器验收

不是浏览器交互稿，也不是在测试里直接调用切换函数。运行 `Summit-demo.prg`，通过模拟器屏幕单击，实际 `InputDelegate.onTap` 收到原生坐标，并核对下一绘制帧的标签和曲线。

[触控原始日志](interaction-acceptance.txt) 为 v0.2.1，新默认是 **3s / All / 5m**：

1. 统计区：All → LAP → All。
2. 功率区：3s → 10s → 3s，统计和图范围保持不变。
3. 功率图区：5m → 20m → All → 5m。

本轮另在 live 模拟器确认：开始活动后的第1圈仍显示 All；首次原生 Lap 后自动显示 **LAP 2**，默认功率3s和图5m保持不变。圈与整次骑行均功率均加粗，四位数回退字体也加粗；原生截图见下文。自动圈使用相同的回调路径，距离触发枚举已在 VM 回归覆盖。

v0.2.0 已验收心率区和底栏不切换模式；本轮保留该路径及回归断言。模式更新随原生字段重绘生效（通常1 Hz），验收等待下一帧，避免连续点击把尚未重绘误判成无响应。

真实 demo 运行时日志为 **53,536 / 127,424 bytes**，相应窗口约 51.4 / 124.4 KB；这是该演示时刻的实际字段堆，不是 8 MB 单元测试堆，也不是长时间最大值。24 小时数据边界使用模型测试验证，不宣称实机长骑内存已验证。

## Live 数据与原生事件

运行 `Summit-live.prg`，Simulation → Activity Data → Start；数据源选 Data Simulation，并点击底部播放按钮。Start 只启动原生计时，播放按钮才开始输出模拟传感器数据。

已观察到 live 读取功率、HR、踏频、速度、距离、海拔、累计爬升；未配对电子变速时 gear 显示 `--`，未提供导航目的地时剩余括号不显示。live 没有使用 demo 的合成指标。

- 原生 Lap 从1递增至2，并重置圈计时/距离，图增加边界。
- v0.2.1 收到新原生 Lap 后自动选中最新圈；手选 All 后再次分圈也切回最新圈，其他两项选择保留（VM 回归）。
- 暂停后功率均值为 `--`，All 活动计时停止；全局 elapsedTime 继续，曲线断开。
- 恢复后显示选择不变，切回 LAP 可看到新圈与从暂停后继续的圈计时。
- Stop → Discard 重置测试活动后，界面恢复 W 3s / All / < 5m >（v0.2.1 默认及重置回归），历史清空；不保留上一活动的选择。
- 首圈起点若 timerTime=0 而首包距离尚空，使用确定的活动原点0；后续有效距离可正常累计，已加入回归。

原生回调通过 `onTimerLap2` 返回 true，避免 SDK 回退 `onTimerLap` 造成重复增圈。中途加载无法读取 native 圈号，显示 LAP ?，不能用本地计数猜测已发生的圈。

## 图像证据

由模拟器 **File → Save Screen Capture** 直接导出，尺寸均为 **246 × 322**：

- [默认 3s / All / 5m，加粗功率 demo](summit-edge840-v021-default.png)
- [首次原生分圈后自动显示 LAP 2](summit-edge840-v021-lap.png)
- [10s / All 统计 / All 历史 demo](summit-edge840-v02-all.png)
- [live 数据源、原生 LAP 3、10s / 20m](summit-edge840-v02-live.png)

以上均为原生绘图截图。默认图和 v0.2.0 的 All 历史图为 demo 合成值；LAP 2 和 live 图使用模拟器原生 Data Simulation，并非真实骑行传感器。v0.2.0 图片保留作历史参考。旧版 `summit-edge840-power-demo.png` 等图片只作历史参考。`docs/design/summit-interactive*.svg` 是设计源文件，不是模拟器截图。

## 已知边界

- 尚无 Edge 840 硬件骑行/触控验收。太阳光、眼镜下可读性、自动圈、真实电子变速及功率计丢包仍待实机。
- 当前圈均功率是按原生分圈边界同步的采样估计，公开 API 未提供原生圈均功率；All 优先使用原生 averagePower。
- Grade 为实测海拔/距离估计，有采样和平滑滞后。
- 剩余路线爬升没有原生公开数据源，live 不显示；导航剩余距离仅在有有效命名目的地和有效距离时显示，不声称已取得 active course ID。
- 长时间 All 图会聚合桶，不能分辨每个短暂断流。最多保留100个原生 Lap 标记；页面重载不恢复此前没有采集或未持久化的历史。
- 点击蓝色反馈在下一次绘制时消退；DataField 默认1 Hz，实际视觉持续时间可能约1秒。

## 复现

```bash
./scripts/build.sh live
./scripts/run.sh test
python3 -m unittest discover -s tests -v
./scripts/run.sh demo
./scripts/run.sh live
```

模拟器：Data Fields → Layout → 1 Field。运行脚本以 VM 的明确 `PASSED (passed=…, failed=0, errors=0)` 判断成功，因为 SDK Monkey Do 在测试通过时也可能返回1。
