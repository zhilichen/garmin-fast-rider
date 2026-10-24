# Edge 840 本地验证

验证日期：2026-10-24。工具链为 macOS、Corretto Java 17、Connect IQ SDK 9.3.0、Edge 840 官方设备包；模拟器报告设备 API 6.0.0。

- 新版 demo 和 live 均针对 `edge840` 构建。
- 新版布局为上方心率/功率（Zone 编号与颜色）、中央踏频/较小的前后档位、底部路线横幅（全程海拔、位置、估算坡度、路线进度/总距离、已耗时）。
- [原生尺寸矢量稿](design/summit-v2.svg)及[设计预览 PNG](design/summit-v2-preview.png)为设计资产，**不是模拟器截图**。本次新画面的截图验收因 Mac 锁屏尚未完成。
- [首版模拟器截图](summit-edge840-demo.png)为历史参考；其约 27 KB 内存读数不代表新版测量结果。
- Garmin VM 单元测试：`zonesTest`、`timeTest`、`gearTest`、`gradeTest`、`courseTest`，5/5 通过。[原始输出](simulator-tests.txt)。覆盖区间边界、零功率/缺失传感器、时间格式、档位缺失、坡度升降/预热/停止过期/重置/海拔跳变、剖面插值、GPS 路线匹配和偏航。
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
