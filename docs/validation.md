# Edge 840 本地验证

验证日期：2026-10-24。工具链为 macOS、Corretto Java 17、Connect IQ SDK 9.3.0、Edge 840 官方设备包；模拟器报告设备 API 6.0.0。

- 新版 demo 和 live 均针对 `edge840` 构建。右上角已移除 DEMO 文案，两种构建均通过 System.getClockTime 显示设备本地时钟（24 小时制 HH:mm），每次重绘更新。
- 新版布局为上方心率/功率（Zone 编号与颜色）、中央左侧踏频/前后档位、右侧独立 Lap 区、底部功率趋势横幅（5 分钟功率、Lap 起止、FTP 参考线、累计爬升、估算坡度、已骑距离、已耗时）。
- [原生尺寸矢量稿](design/summit-power.svg)及[设计预览 PNG](design/summit-power-preview.png)为设计资产，**不是模拟器截图**。新增[原生 246 × 322 模拟器截图](summit-edge840-power-demo.png)，已在设备壳窗口与原生导出图上确认布局和图形。
- [首版模拟器截图](summit-edge840-demo.png)为历史参考；其约 27 KB 内存读数不代表新版测量结果。新版 demo 运行时窗口观察到约 30.5 KB / 124.4 KB，属于单个演示时刻，未做长时间内存压力测量。
- Garmin VM 单元测试：`zonesTest`、`timeTest`、`gearTest`、`lapStatsTest`、`gradeTest`、`courseTest`、`measuredHistoryTest`、`boundedHistoryTest`、`powerHistoryTest`、`powerWindowTest`，10/10 通过。[原始输出](simulator-tests.txt)。Lap 测试覆盖中途加载、原生边界对应的统计重置、暂停后继续、零功率、缺失/长采样间隙与时钟重置；模型测试之外，已在 live 模拟器中启动活动、点击原生 Lap，并观察到当前圈计时重置及新增图上边界；截图时活动总耗时约 10 秒、当前圈约 3 秒。
- Lap 时间使用 timerTime 排除暂停，活动总耗时使用 elapsedTime 含暂停。圈均功率是以原生边界对齐的采样估计，并非 Garmin 原生均功率字段；界面用 `~AVG W` 明示。
- 新功率测试覆盖 3 秒均值（包括 0 W）、重复时间戳、缺失/暂停/长断流分段、原生 Lap 边界去重与分桶、晚加载不伪造圈起点、窗口裁剪、圈起点在图外、时钟回退重置、160 桶/100 边界内存上限以及高功率轴扩展。旧海拔模型测试保留为历史原型回归。
- 246 × 322 离线预览使用同样的演示功率公式、3 秒桶、FTP 与边界位置。字体估算检查三列图标题与最长圈起点文本不重叠，图右侧有留白；不是原生绘图验收。
- Python GPX 导入测试（保留的旧原型工具）：3/3 通过，覆盖采样上限与端点、缺失海拔、多个不连续段/路线、重复坐标。

复现命令（在项目根目录）：

```bash
./scripts/build.sh live
./scripts/run.sh test
python3 -m unittest discover -s tests -v
./scripts/run.sh demo
```

运行脚本通过被动检查模拟器监听端口判断启动就绪，不用空 TCP 连接探测 Garmin Shell。SDK 9.3 的 Monkey Do 在 VM 输出 PASSED 时也可能返回 1；测试脚本以 VM 的明确成功汇总判定结果，失败或缺失汇总均返回失败。

为兼容设备 API 6.0.0，边界比较使用普通条件表达式，不调用 API 6.0.3 才增加的 `Math.min/max/abs`。演示计时先转整数再取模。

当前界面不使用内置 GPX 或海拔历史模型。真实版从数据页加载后记录 Activity.Info.currentPower / elapsedTime，原生 Lap 回调通过同一 elapsedTime 轴标注边界；计时暂停在图中占据空白。手动圈已在模拟器验证；自动圈和实机传感器仍待验证。VM 模型测试不替代设备事件验证。尚未进行 Edge 840 实机骑行验证。
