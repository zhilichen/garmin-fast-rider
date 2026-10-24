# 开发与测试

## 环境

- 官方Connect IQ SDK与目标Edge设备包；本次使用SDK9.3.0。
- JDK17、Bash、Python3.10+。普通构建只使用Python标准库。
- 修改字体或执行图像回归时：`python3 -m pip install -r requirements-dev.txt`。

`CIQ_SDK_PATH`可显式指定SDK目录。Mac默认读取`~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`，Linux默认使用`~/.Garmin/ConnectIQ`；自定义目录使用`CIQ_HOME`。Mac已完成构建和模拟器验收，其他主机需按官方SDK配置运行环境。

## 常用命令

```bash
./scripts/build.sh live edge840
./scripts/build.sh test all
./scripts/run.sh demo edge1050
./scripts/run.sh test edge530
python3 scripts/generate-project.py --check
python3 -m unittest discover -s tests/python -v
```

VS Code任务的设备选择来自同一个设备目录。调试配置默认840，也可在Monkey C扩展中选择其他受支持设备。

修改布局/设备目录后运行`python3 scripts/generate-project.py`。修改统一字体定义后运行`python3 scripts/generate-fonts.py`并提交生成结果。源字体随仓库提供，生成不依赖SDK字体目录或宿主系统字体。CI会核对目录、布局、字库、长里程宽度和已记录的840图像回归。

## 原生测试矩阵

Mac上先关闭其他Connect IQ模拟器，再运行：

```bash
source scripts/env.sh
python3 scripts/test-matrix.py
# 已构建过时可跳过编译：
python3 scripts/test-matrix.py --no-build edge530 edge840 edge1050
```

测试驱动通过LaunchServices启动并跟踪自己创建的模拟器，只关闭这些实例。日志位于忽略的`.local/test-results`。SDK可能在VM输出PASSED后返回非零退出码，因此以完整VM测试汇总判定，而不是单独依赖进程码。不要把测试VM的大堆大小当成真实数据字段的可用内存。

## 确定性画面回归

```bash
./scripts/build.sh snapshot edge840
source scripts/env.sh
monkeydo bin/edge840/FastRider-snapshot.prg edge840
# 更多边界值，仅写入隔离的.local副本：
SNAPSHOT_CASE=stress ./scripts/build.sh snapshot edge1050
SNAPSHOT_CASE=missing ./scripts/build.sh snapshot edge530
```

snapshot固定合成指标、骑行时长和时钟，绘图仍使用正式渲染代码。通过模拟器File→Save Screen Capture导出原生截图。840的12种组合基准位于`tests/fixtures/edge840-v0315`；重构后的对照位于`docs/validation/edge840`。

840的UI应在246×322原生像素下比较，不以设备外框截图或被缩放的预览判定。当前12组回归零像素差异。以后若有意更改840设计，应在评审时明确更新基准，不能通过放宽图像相等检查掩盖变化。

字体裁剪探针仍可使用：

```bash
./scripts/build-font-probe.sh
source scripts/env.sh
monkeydo .local/FastRider-font-probe.prg edge840
python3 scripts/check-font-probe.py <原生246x322截图.png>
```

## 发布包

```bash
./scripts/build.sh live all
python3 scripts/package.py
```

ZIP仅包含目标设备的真实live程序、说明、项目许可及字体许可，不包含测试/演示程序、签名密钥、活动文件或SDK。输出位于忽略的`dist/`，并包含每个程序的SHA256。
