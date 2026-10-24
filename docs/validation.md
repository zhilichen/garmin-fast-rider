# Edge 840 本地验证

验证日期：2026-10-24。工具链为 macOS、Corretto Java 17、Connect IQ SDK 9.3.0、Edge 840 官方设备包；模拟器报告设备 API 6.0.0。

- 新版 demo 和 live 均针对 `edge840` 构建。右上角已移除 DEMO 文案，两种构建均通过 System.getClockTime 显示设备本地时钟（24 小时制 HH:mm），每次重绘更新。
- 新版布局为上方心率/功率（Zone 编号与颜色）、中央左侧踏频/前后档位、右侧独立 Lap 区、底部实测历史横幅（已采集海拔、当前位置、估算坡度、已骑距离、已耗时）。
- [原生尺寸矢量稿](design/summit-history.svg)及[设计预览 PNG](design/summit-history-preview.png)为设计资产，**不是模拟器截图**。本次新画面的截图验收及原生 Lap 按键/自动圈联调因 Mac 锁屏尚未完成。
- [首版模拟器截图](summit-edge840-demo.png)为历史参考；其约 27 KB 内存读数不代表新版测量结果。
- Garmin VM 单元测试：`zonesTest`、`timeTest`、`gearTest`、`lapStatsTest`、`gradeTest`、`courseTest`、`measuredHistoryTest`、`boundedHistoryTest`，8/8 通过。[原始输出](simulator-tests.txt)。Lap 测试覆盖中途加载、原生边界对应的统计重置、暂停后继续、零功率、缺失/长采样间隙与时钟重置；测试不等同于已在设备上收到原生 Lap 事件。
- Lap 时间使用 timerTime 排除暂停，活动总耗时使用 elapsedTime 含暂停。圈均功率是以原生边界对齐的采样估计，并非 Garmin 原生均功率字段；界面用 `~AVG W` 明示。
- 新增历史测试覆盖实测海拔插值、禁止向未来外推、缺失数据/暂停/长断流分段、活动距离重置、最小轴跨度及 160 点压缩上限与原始测量值保留。预览检查图形右侧 9 列为空白；不是原生绘图验收。
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

当前界面不使用内置 GPX；演示以独立合成海拔序列模拟实测历史。真实版从数据页加载后记录 Activity.Info.altitude / elapsedDistance，没有未来曲线或路线总距。未来路线等待原生接口方案。尚未进行 Edge 840 实机骑行验证。
