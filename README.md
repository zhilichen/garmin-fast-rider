# FastRider

Garmin Edge 全屏 Connect IQ 数据字段：大号心率/功率、实时骑行数据、Lap/All 统计及带分圈标记的功率趋势。

![Edge 840 原生模拟器](docs/validation/screens/edge840.png)

## 下载与支持设备

<!-- downloads:start -->
当前版本 **v0.4.0**，下载后即可安装，无需 SDK 或 Java。PRG 可直接复制到设备；ZIP 包含同一程序、安装说明和许可证。

| 设备 | 原生分辨率 | 操作 | PRG 直接下载 | ZIP 下载 |
| --- | --- | --- | --- | --- |
| Edge 530 | 246×322 | 默认视图 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge530/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge530/FastRider-0.4.0-edge530.zip) |
| Edge 540 | 246×322 | 默认视图 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge540/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge540/FastRider-0.4.0-edge540.zip) |
| Edge 550 | 420×600 | 默认视图 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge550/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge550/FastRider-0.4.0-edge550.zip) |
| Edge 830 | 246×322 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge830/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge830/FastRider-0.4.0-edge830.zip) |
| Edge 840 | 246×322 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge840/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge840/FastRider-0.4.0-edge840.zip) |
| Edge 850 | 420×600 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge850/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge850/FastRider-0.4.0-edge850.zip) |
| Edge 1030 | 282×470 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1030/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1030/FastRider-0.4.0-edge1030.zip) |
| Edge 1030 Bontrager | 282×470 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1030bontrager/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1030bontrager/FastRider-0.4.0-edge1030bontrager.zip) |
| Edge 1030 Plus | 282×470 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1030plus/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1030plus/FastRider-0.4.0-edge1030plus.zip) |
| Edge 1040 | 282×470 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1040/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1040/FastRider-0.4.0-edge1040.zip) |
| Edge 1050 | 480×800 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1050/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1050/FastRider-0.4.0-edge1050.zip) |
| Edge 1060 | 480×800 | 触控切换与车铃 | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1060/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/edge1060/FastRider-0.4.0-edge1060.zip) |

[全部型号 ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.0/FastRider-0.4.0.zip) · [SHA256 校验值](releases/v0.4.0/SHA256SUMS) · [版本清单](releases/v0.4.0/manifest.json)
<!-- downloads:end -->

Solar 版本随 Garmin 对应设备包支持。所有型号使用**单字段全屏布局**。[各机型原生截图](docs/screenshots.md) · [验收记录](docs/validation.md)

## 显示与操作

默认 **3s / All / 5m**。触屏机型支持：

| 区域 | 操作 | 结果 |
| --- | --- | --- |
| 右上实时功率 | 点击 | 3s ↔ 10s 平均功率 |
| 右中统计 | 点击 | All ↔ 当前 Lap |
| 功率图标题或曲线 | 点击 | 5m → 20m → All |
| 左侧心率及实时信息 | 双击 | 2秒三击车铃 |

触屏机型在原生手动/自动分圈后自动显示最新 Lap。Garmin 从活动开始便进入第1圈，第一次分圈开始第2圈；本页初始显示 All。**无触屏机型始终保留默认视图**，分圈仅更新历史标记与内部圈数据，不切换统计模式，也不包含触控委托或车铃代码。

- 心率、功率采用 Zone 配色，色条上的黑白标记指示当前编号 Zone 内的位置。
- 实时四格：左列 gear / 坡度，右列 rpm / mph。速度一位小数，坡度取整；踏频和坡度另有阈值配色。
- All/Lap 统计：时长、平均功率、距离。All 在有有效命名导航目的地时显示剩余距离，如 `300.5mi(-200.5)`。
- 图头：累计爬升 ft、功率窗口和本地 AM/PM 时钟。图中含 FTP、Z2上限及原生 Lap 标记。
- 功率配色：Z1/Z3灰、Z2蓝、Z4橘、Z5紫、Z6/Z7红；心率独立采用灰/蓝/绿/橘/红五区。

## 安装

1. 在上表下载**对应型号**的 PRG；下载 ZIP 时先解压，使用型号目录内的 `FastRider.prg`。
2. 将 Edge 以 USB/电脑模式连接，复制 PRG 到设备内部存储的 `GARMIN/APPS/`。Mac 需要通过支持 MTP 的文件传输工具访问 Edge。
3. 断开 USB，在骑行配置的数据屏幕选择 Connect IQ → FastRider，并设为**单字段全屏布局**。

更新已有安装时沿用原 PRG 文件名；早期安装可能名为 `SUMMIT.PRG`，将下载文件改为这个名字再覆盖。首次安装使用 `FastRider.prg`。

## 从源码构建

安装官方 [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/)、JDK 17，以及需要的 **Edge 设备包**。不需要安装全部 Garmin 设备。

```bash
./scripts/build.sh live edge840
./scripts/build.sh live edge1050
./scripts/build.sh live all
```

输出为 `bin/<device>/FastRider-live.prg`。将**对应设备**的文件复制到 USB 连接设备的 `GARMIN/APPS/`，断开 USB 后在骑行配置中选择 Connect IQ → FastRider，设为单字段全屏。

```bash
./scripts/run.sh demo edge850       # 合成演示数据
./scripts/run.sh live edge840       # 真实 Activity.Info
./scripts/run.sh test edge530       # 原生 VM 测试
```

脚本优先读取 SDK Manager 的当前 SDK 设置，也可设置 `CIQ_SDK_PATH`、`CIQ_HOME`、`JAVA_HOME`。开发签名默认保存在忽略的 `.local/developer_key.der`；可用 `CIQ_DEVELOPER_KEY` 指定已有密钥。保留同一签名用于更新同一应用。普通构建使用已提交资源，无需 Python 图形依赖或下载字体。

[开发与测试](docs/development.md) · [共享架构与扩展方式](docs/architecture.md) · [贡献说明](CONTRIBUTING.md)

## 数据口径

- FTP 优先使用原生骑行 FTP，否则使用应用设置；缺省250 W。心率区优先使用原生骑行区间，否则由最大心率设置计算。
- 功率平均包含有效0 W；缺失、暂停和断流不会沿用旧平均值。图表保留实际采集的历史，不补造加载前的数据。
- All 均功率优先使用 Garmin 的整次活动统计；Lap 均功率按有效采样时间加权估算，可能与 Garmin 原生圈均功率的零值/丢包处理不同。
- 圈统计时间不含暂停，图表时间轴使用含暂停的 elapsed time。中途加载无法恢复完整原生圈号和圈起点，不编造圈号。
- 坡度来自实测海拔与里程估算；剩余距离来自导航目的地信息。没有未来路线海拔读取或 GPX 绑定功能。
- gear 读取电子变速传感器的后拨档位，不推测档位。距离/速度/爬升使用 mi / mph / ft。

截图均为固定合成指标；正式 live 包读取真实数据。模拟器验收不代表各机型的实体屏幕、传感器和雷达叠层均已真机验证。

## 许可证

项目代码为 [MIT](LICENSE)。字库分别遵循 Apache-2.0、Bitstream Vera/Arev 许可，原文件、许可和生成来源见 [第三方说明](THIRD_PARTY_NOTICES.md)。数据处理方式见[隐私说明](PRIVACY.md)。与 Garmin 无隶属关系。
