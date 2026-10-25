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
python3 scripts/check-generated-fonts.py
python3 -m unittest discover -s tests/python -v
```

VS Code任务的设备选择来自同一个设备目录。调试配置默认840，也可在Monkey C扩展中选择其他受支持设备。

修改布局/设备目录后运行`python3 scripts/generate-project.py`。修改字体定义、显示档字号策略或新增分辨率时，依次运行`python3 scripts/generate-fonts.py`、`python3 scripts/generate-project.py`并提交生成结果；布局生成器会使用新字形边界平衡统计行。源字体随仓库提供，生成不依赖SDK字体目录或宿主系统字体。CI会核对目录、布局、字库、长里程宽度和已记录的840图像回归。

`check-generated-fonts.py`在临时目录重建字库，逐像素比较PNG、逐字节比较FNT及度量文件。生成器显式使用BASIC单字形布局，不依赖宿主是否安装RAQM/HarfBuzz。不同平台的PNG压缩字节可能不同，校验不比较压缩流，也不改写已提交的840原始资源。

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

snapshot固定合成指标、骑行时长和时钟，绘图仍使用正式渲染代码。日夜验收使用模拟器 Data Fields → Background Color → White / Black；主题来自原生背景接口，每次重绘跟随改变。修改配色后，至少重新导出四种分辨率的日夜截图，并检查一次 White → Black → White 往返和日间像素回归。通过模拟器File→Save Screen Capture导出原生截图。840的12种组合基准位于`tests/fixtures/edge840-v0315`；重构后的对照位于`docs/validation/edge840`。

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
# 发布到 Git 并自动更新 README 的逐机型 PRG / ZIP 下载表：
python3 scripts/package.py --publish
python3 scripts/check-downloads.py
```

ZIP仅包含目标设备的真实live程序、说明、项目许可及字体许可，不包含测试/演示程序、签名密钥、活动文件或SDK。普通打包输出位于忽略的`dist/`。

`--publish`将已经核对构建指纹和SHA256的程序写入`releases/v<version>/`，生成各型号ZIP、完整ZIP、校验值，以及`README.md`和`README.zh-CN.md`中的下载表与画廊。设备列表直接来自同一配置目录，两个语言版本都由CI检查。将版本目录与两份README一起提交，其他用户便可直接从GitHub下载。此命令不推送Git，也不提交Connect IQ审核。

已发布版本目录不能被不同内容覆盖；应用变化后应先更新`manifest.xml`版本并重新构建、验收。`check-downloads.py`无需SDK，CI会验证已提交的程序、ZIP内容、许可证、SHA256及README链接。
