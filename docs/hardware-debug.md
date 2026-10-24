# Edge 840 真机调试

本页记录真机部署流程；模拟器通过不代表真机通过。当前硬件连接状态以实际 USB 枚举、安装回读和设备日志为准。

## 构建

```bash
./scripts/build.sh hardware
```

`bin/FastRider-hardware.prg` 使用真实 Activity.Info，**不使用 demo 合成指标**，额外记录本地诊断信息。普通 live 构建关闭这些诊断输出。

- 启动及首次绘制的内存占用。
- 点击区域与切换后的 3s/10s、All/Lap、图范围。
- 原生开始、暂停、恢复、停止、重置和分圈事件。
- 传感器数据的可用性位标记：功率1、心率2、踏频4、后拨8、速度16。
- 不输出功率/心率读数、GPS 坐标或活动记录。日志仅保留在本地，不自动上传。

## USB 与 MTP

Edge 840 使用 MTP，正常也可能不作为 Finder 磁盘出现。首先确认 USB 总线识别到 Garmin（Vendor 0x091e），再用 MTP 文件传输工具访问内部存储。不要把“Finder 无磁盘”单独视为未连接。

若 USB 总线没有 Garmin，先检查数据线、直连 Mac 接口、配件连接提示和码表的 USB/电脑连接状态。Garmin 官方还给出了关机后按住 LAP/RESET 再插线的连接排查步骤；只在普通数据连接无法建立时使用，不执行恢复出厂设置或固件升级。

官方说明：[Mac 与 Edge 的 MTP](https://support.garmin.com/zh-CN/?faq=Cu7Aa5tExP4beYisOekd7A)、[USB 连接排查](https://support.garmin.com/en-SG/?faq=Wkf9e0fPST0gP0KoM63DK9)。

## 安装与日志

1. 读取设备的 GarminDevice.xml，核对机型及软件版本；不要把设备标识或完整 XML 提交到 Git。
2. 若 `GARMIN/APPS/SUMMIT.PRG` 已存在，先备份到项目 `.local/device-debug/`。
3. 将硬件调试构建复制为 `GARMIN/APPS/SUMMIT.PRG`，回读核对 SHA-256。仅操作本应用文件，不删除活动、路线或其他应用。
4. 为 `System.println` 创建 `GARMIN/APPS/LOGS/SUMMIT.TXT`（大小写与 PRG 对应）。已存在的日志先回读备份，不截断。
5. 安全断开 USB，在骑行配置里选择单字段 Connect IQ → FastRider。
6. 核对初始 `3s / All / 5m`；开始活动仍显示 All；首次 Lap 后显示 LAP 2。检查三处点击、暂停恢复及新活动重置。
7. 若出现 IQ!、闪退或无点击响应，重新 USB 连接，回读 `SUMMIT.TXT`、`SUMMIT.BAK`、`CIQ_LOG.YAML`（较旧固件可能是 CIQ_LOG.TXT）。发生整个设备重启时还可读取 `GARMIN/ERR_LOG.TXT`。所有真实设备日志保存在 `.local/`，不提交仓库。

Garmin SDK 的本地 `doc/docs/Core_Topics/Debugging.html` 明确说明：单步调试/断点仅适用于模拟器；真机通过文件日志和运行观察排查。本流程不声称可以通过 USB 远程点击码表或实时设置断点。

## 恢复正常版本

调试后将 `bin/FastRider-live.prg` 复制到相同 `GARMIN/APPS/SUMMIT.PRG` 位置，使用同一签名密钥和 App ID。保留日志备份；不清除用户应用设置。

## 2026-10-24 部署记录

- Mac USB 初始未识别设备；按官方关机后按住 LAP/RESET 插线的流程后识别为 Edge 840。
- USB VID/PID：091e:4fde；设备 XML 确认为 006-B4062-00，固件 31.33。
- 使用项目 `.local/` 下构建的 libusb/libmtp 工具读取 MTP，不安装全局软件。
- 已上传硬件调试构建至 `GARMIN/APPS/SUMMIT.PRG`，149,020 bytes；回读 SHA-256 与本地完全一致。
- 已创建 `GARMIN/APPS/LOGS/SUMMIT.TXT`；未修改活动或路线文件。
- 硬件构建通过，诊断代码的 22 项 VM 回归通过；用户已确认真机正常显示 `3s / All / 5m`；触控和活动测试仍待实机确认。该安装包早于本轮 Zone 位置竖线更新。

## v0.2.2 更新

- 已回读旧版设备日志，确认正常加载、三处原生触控切换；设备堆 37,888 / 127,592 bytes。原始日志不入库。
- 新增 Zone 位置竖线的 hardware 包已上传并回读比对完全一致，149,980 bytes，SHA-256 `48bb02d90c3a686d46079acc34d7b4af177d318a56fedf02f5745bf87177a91e`。
- 保留原日志和设置，不改活动/路线；新版运行待断开 USB。后续日志继续写入原 SUMMIT.TXT。

## v0.2.3 改名

应用显示名、源码类名、构建产物和 VS Code 任务统一为 FastRider。App ID 和签名密钥保持原值；已有设备通过同一应用更新保留身份。当前 USB 调试沿用 `SUMMIT.PRG` 和对应 `SUMMIT.TXT` 文件名以保留现有日志；这只是兼容文件名，码表显示 FastRider。新本地构建产物为 `bin/FastRider-{live,demo,hardware,test}.prg`。

FastRider v0.2.3 硬件包已替换待加载的 v0.2.2 包，150,012 bytes，回读逐字节相同；旧包已保存在本地备份。拔掉 USB 后加载改名版本。

## v0.3.0 真机反馈修复

放大数值并预留右上雷达位置的153,004 bytes硬件包已上传且回读完全一致；使用同一App ID、密钥和日志文件。真机加载与雷达实际覆盖待拔掉USB后观察。用户解锁后已补完模拟器目视和三处完整点击循环，证据见validation.md；真实雷达图层仍需真机观察。

## v0.3.2 候选包

中间v0.3.1已写入设备并回读一致（153,788 bytes）；用户随后要求移除图中总时长及底栏，形成最终v0.3.2（151,740 bytes）。最终版已通过构建、VM和原生模拟器点击/目视验收，但设备当前断开USB，因此尚未安装。重新连接后需用最终硬件包更新，保留日志和设置。

## v0.3.3 抗锯齿候选包

原生图形AA、灰度字体AA和白底混合已通过模拟器像素对比与23项VM回归。硬件包156,476 bytes已构建，设备未连接USB，尚未安装；此前v0.3.1的实际写入记录不能当作本版部署。
