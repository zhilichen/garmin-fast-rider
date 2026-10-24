# Edge 840 本地验证

验证日期：2026-10-24。工具链为 macOS、Corretto Java 17、Connect IQ SDK 9.3.0、Edge 840 官方设备包；模拟器报告设备 API 6.0.0。

- demo 和 live 均针对 `edge840` 构建。
- 动态 demo 已在模拟器单字段全屏（246 × 322）运行：功率、心率、Zone 标签与颜色更新；距离、骑行计时更新；全程海拔曲线显示已完成路段、当前位置、剩余距离与累计爬升。
- 实际运行截图：[summit-edge840-demo.png](summit-edge840-demo.png)。模拟器运行时显示约 27 KB 内存使用，低于设备数据字段上限。
- Garmin VM 单元测试：`zonesTest`、`timeTest`、`courseTest`，3/3 通过。[原始输出](simulator-tests.txt)。覆盖区间边界、零功率/缺失传感器、时间格式、剖面插值、GPS 路线匹配和偏航。
- Python GPX 导入测试：3/3 通过，覆盖采样上限与端点、缺失海拔、多个不连续段/路线、重复坐标。

复现命令（在项目根目录）：

```bash
./scripts/build.sh live
./scripts/run.sh test
python3 -m unittest discover -s tests -v
./scripts/run.sh demo
```

运行脚本通过被动检查模拟器监听端口判断启动就绪，不用空 TCP 连接探测 Garmin Shell。SDK 9.3 的 Monkey Do 在 VM 输出 PASSED 时也可能返回 1；测试脚本以 VM 的明确成功汇总判定结果，失败或缺失汇总均返回失败。

为兼容设备 API 6.0.0，边界比较使用普通条件表达式，不调用 API 6.0.3 才增加的 `Math.min/max/abs`。演示计时先转整数再取模。

内置 GPX 是约 44 km 的合成演示数据，界面明确标记 SAMPLE/DEMO。真实路线需预先导入自己的带海拔 GPX；公开 Course API 不提供当前导航路线的完整海拔点列。尚未进行 Edge 840 实机骑行验证。
