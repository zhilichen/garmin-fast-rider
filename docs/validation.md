# FastRider v0.3.11：分隔左移15 px、重排横向分布与范围闪电

- 上下竖分隔从x122统一移至x107，均宽2 px；左内容宽103 px，右内容宽133 px（增加15 px），功率起点x111。心率Zone右沿x105，两条色条分别宽103/133 px，位置标记按各自条宽重新映射。
- 字号和全部字体资源均不变。心率三位数字仅收紧3 px字间距，实时四格仅收紧2 px；采用原字库逐字绘制及实际ink边界裁剪，避免Garmin导入缩小xadvance的字库时裁掉单字右沿。该修正已验证完整边缘，未压缩字形。
- 实时列中心改为x27/x79，保留2×2布局。右侧均功率+AVG/W、距离+mi+剩余距离整组居中，单位两侧3 px间距。时长仍右对齐244；沿用原118 px字形回退条件，同一值不会因面板变宽而换成更大字号。
- 范围改为`< ⚡ 5m >`/`< ⚡ 20m >`/`< ⚡ All >`；蓝色闪电是14×14 px原生抗锯齿矢量图形，与功率单位图标共用函数。整组居中x123；文字仍18 px，最大20m组合宽80 px，与长爬升/完整AMPM时钟保持间距。
- 点击边界跟随移动：右侧从x109开始，分隔x107…108忽略；车铃仅x<107/y<214。新划入右侧的15 px不再被车铃消费。
- live / hardware / demo / test构建成功，无告警；Garmin VM **29/29**，[输出](simulator-tests.txt)。覆盖新边界、51 px窄格内三位踏频、HR/Zone及雷达避让、完整字高、最大范围标签宽度；12种模式、长计时、缺失信号、四位数均通过原生绘制。
- [原生默认截图](fastrider-edge840-v0311-default.png)、[Lap/20m截图](fastrider-edge840-v0311-lap.png)，File→Save Screen Capture导出246×322、demo合成值。[像素记录](layout-v0311-pixels.json)：两条分隔的全部像素都位于x107/108；心率末位8、踏频6/4、均功率212与旧截图平移后逐像素一致，所有字库资源逐字节未变。5m/20m标题闪电与功率闪电图形逐像素一致，顶部留白、雷达区及黑白marker完整。
- [实际点击日志](interaction-v0311.txt)：在新增右侧区域[110,50]/[110,160]切换功率/统计，并完整循环5m/20m/All；未触发车铃。真实demo字段堆63,704 /127,424 bytes。默认已恢复3s/All/5m。
- hardware包**171,292 bytes**已写入USB连接的Edge840 `GARMIN/APPS/SUMMIT.PRG`并回读逐字节一致，沿用原App ID、签名、设置与活动数据。上传前设备无pending同名文件；断开USB后加载，实际雷达覆盖和户外可读性仍待真机观察。

以下保留旧版验收记录。

# FastRider v0.3.10：以loud beep为主的组合铃声

- 三种原生预设组成五段：`LOUD_BEEP → ALERT_HI → LOUD_BEEP → ALERT_LO → LOUD_BEEP`，响亮主击三次，高/低提示各一次。首击在双击时立即触发，后续由字段每秒compute推进，目标约4–5秒完成请求。原生预设的实际波形、音量、持续时间和连续请求处理仍由Edge固件决定，没有实测声压或现场铃感。
- [官方Timer模块](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer.html)不支持DataField上下文；[Attention](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#playTone-instance_function)的自定义数组只接受ToneProfile。因此使用非阻塞状态机，未使用Timer、sleep、忙等待或快速连续调用。compute每次最多发一段，最小请求间隔800ms；过分迟到、超过5秒或时钟回退时取消，避免补响突发。切页、活动重置及应用停止取消后续请求。
- 左侧重触发冷却改为5.5秒，其余点击立即响应。活动未开始/暂停也可响铃。UI、配色和默认3s/All/5m不变。
- live / hardware / demo / test构建成功，无告警；Garmin VM **29/29**，[输出](simulator-tests.txt)。新增真实1Hz推进、重复tick、超时不补响、时钟回退及切页/重置/停止取消的模型测试。原有全套数据/布局/交互回归通过。
- [原生点击日志](bell-simulator-v0310.txt)记录五段实际请求：0/945/1946/2945/3945ms，顺序正确；连续双击未重启，右侧功率点击在第二段之前即处理。没有API异常。模拟器原生demo字段堆61,664 /127,424 bytes。以上是调用时序验收，不等于音色、完整声学时长或响度测量。SDK测试后的空白transport通过重启本任务模拟器恢复后完成验收。
- hardware包**168,364 bytes**已更新至USB连接的Edge840 `GARMIN/APPS/SUMMIT.PRG`并回读逐字节一致，保留原App ID、签名、设置和活动数据；替换前已回读验证并备份旧pending包。断开USB后双击左侧心率/实时区试听。

以下保留旧版验收记录。

# FastRider v0.3.9：加厚小Z与更清楚的剩余里程

- 小Z从14 px字体增至16 px（原字形高11→12 px，宽8→9 px），字形内增加0.25 px加厚笔画，以4倍采样保留抗锯齿；原生截图可见字高10→11 px，约+10%。区号44 px及baseline66保持不变，组合总宽31 px；四位主功率回退时使用10 px小Z+26 px区号，总宽20 px。Z位于主数字下方，不会与主数字争用同一行。
- All剩余距离改为24 px粗体数字/负号，括号单独用Regular字形并对齐高度，mi维持18 px常规。长值成对回退32/24、30/22、26/21 px，后缀和mi收紧字间距，保持原字形比例。正常示例`10.7mi(-9.9)`使用32/24 px，原生Dc宽115 px；demo的`10.5mi(-12.4)`使用30/22 px，宽118 px。
- live / hardware / demo / test构建成功，无告警；Garmin VM **27/27**，[输出](simulator-tests.txt)。原生Dc字宽测试覆盖大小关系、Z与主数字上下避让、单位/图标间距、雷达留白、长距离回退；全部12种模式及缺失、四位数、长计时仍正常绘制。
- [原生246×322截图](fastrider-edge840-v039-default.png)，File→Save Screen Capture输出，demo合成数据。真实demo字段堆60,448 /127,424 bytes。[像素与字体记录](type-v039-pixels.json)：截图中已骑行/剩余/mi的字形高分别21/16/13 px，右侧1px边距、雷达区、顶部留白及黑白marker通过检查。
- SDK模拟器首次启动停在空白transport会话，重启本任务模拟器/MonkeyDo后成功加载，没有改动程序绕过该问题。
- hardware包**166,396 bytes**已写入USB连接中的Edge840 `GARMIN/APPS/SUMMIT.PRG`，回读逐字节一致。沿用App ID与签名；替换前已备份并验证旧pending包。断开USB后才加载新版，实际屏幕可读性仍待实测。

以下保留旧版验收记录。

# FastRider v0.3.8：车铃改用原生响亮蜂鸣

- `Attention.playTone(Attention.TONE_LOUD_BEEP)`替换1500ms自定义音调序列。该预设由Garmin文档明确称为响亮蜂鸣；公开API没有音量/振幅控制，未测量其声压，也不声称超过其他所有原生声音。响度及实际时长由Edge固件决定。
- 保留左区双击和1600ms输入冷却；将冷却常量与声音时长解耦，避免把系统预设误称为1500ms。未新增sleep/定时轮询，右侧切换立即处理。
- live / hardware / demo / test构建成功，无告警；Garmin VM **27/27**，包括冷却精确到期及期间点击不能累计成下一双击。[测试输出](simulator-tests.txt)。移除无效的自定义序列时长测试，改为实际冷却边界回归。
- [原生双击日志](bell-simulator-v038.txt)：连续双击两组仅触发一次`TONE_LOUD_BEEP`请求，随后右侧功率立即切换10s，无API异常。真实demo字段堆60,480 /127,424 bytes。这验证API调用，不等同于实机音量或时长试听。
- hardware包**166,156 bytes**已更新到连接中的Edge840 `GARMIN/APPS/SUMMIT.PRG`，回读逐字节一致。保留原App ID、签名、设置与活动数据；旧pending包已回读校验并备份。断开USB后加载，双击左侧心率/实时区即可试听。

[官方API依据](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#playTone-instance_function) · [车铃说明](bell-interaction.md)

以下保留旧版验收记录。

# FastRider v0.3.7：高饱和、统一色相的状态配色

- 彩色锚点统一为蓝`#004CFF`、绿`#008A20`、橘`#D05A00`、红`#D00020`、紫`#8000D8`，均为100% HSV饱和度；中性灰`#555555`。主数字、Zone、色条及功率曲线共享色值，心率Z4由棕黄改为橘色。坡度和踏频沿用既有阈值，分别使用同一橘/红/紫。红心与警示红一致，蓝色图标/剩余里程使用新蓝。
- 图表填充由80%增至90%不透明度，曲线实色；辅助线原有白色留边保持完整。没有更改字号、布局、Zone分组、阈值或交互。
- live / hardware / demo / test构建成功，无告警；现有Garmin VM **27/27**，[原始输出](simulator-tests.txt)。真实demo字段堆60,784 /127,424 bytes。
- [原生246×322截图](fastrider-edge840-v037-default.png)由File→Save Screen Capture导出，demo合成数据。[原生像素对比](color-v037-pixels.json)：低踏频前景RGB从(156,24,24)变为(213,0,32)，HSV饱和度84.6%→100%；HR Z4从(139,89,0)变为(213,89,0)，与红色拉开色相；坡度橘色不再含灰分量。雷达留白、顶部2px和marker黑白三段与v0.3.6逐像素一致。设备导出色值经过屏幕量化，不能以源RGB代替实际显示像素。
- hardware包**166,620 bytes**已写入USB连接的Edge840 `GARMIN/APPS/SUMMIT.PRG`，回读逐字节校验一致。原pending包已备份并校验，其他设备数据保留。断开USB后才加载新版；物理屏幕在不同背光/日照下的可读性仍待用户实测。

以下保留旧版验收记录。

# FastRider v0.3.6：加粗实时数值、小Z大区号、All导航剩余距离

- rpm / rear gear / grade / mph数值统一38 px加粗，标签不变。Zone改为14 px小Z和44 px区号：字形可见高约11/32 px，总宽30 px保持原宽；baseline66避开雷达保留区。四位实时功率回退时使用9/26 px，总宽19 px。
- 图头爬升数值18 px加粗，ft18 px常规。All有有效导航剩余距离时显示`10.7mi(-9.9)`，括号为蓝色、常规字重，21 px后缀数字可见高15 px，对比32 px主数字22 px，约2/3。保留白底灰度抗锯齿。
- 公开API没有可靠active course ID；实际使用有效命名目的地+非负distanceToDestination判据。无有效导航数据、缺失或负数不显示后缀；Lap始终只显示本圈距离。零剩余显示`(0.0)`。长值先成对缩小字号，再取整；极端无法容纳时隐藏后缀。
- live / hardware / demo / test均构建通过，无告警。Garmin VM **27/27**，[原始输出](simulator-tests.txt)。原生Dc断言覆盖固定徽标总宽、雷达与marker边界、`10.7mi(-9.9)`完整精度、后缀字高、无导航/Lap隐藏、长距离窄列回退；12种模式与长计时/缺失/4位数均正常绘制。测试VM usedMemory=81,768 bytes（不是实际字段可用堆证明）。
- [All原生截图](fastrider-edge840-v036-default.png)、[Lap原生截图](fastrider-edge840-v036-lap.png)，均由File→Save Screen Capture输出246×322，使用demo合成值。真实demo字段堆60,840 /127,424 bytes。[像素检查](layout-v036-pixels.json)确认雷达区空白、顶部2px及黑8/白6/黑8 marker保持完整。模拟器实际点击All↔Lap、3s↔10s及5m/20m/All，后缀随All/Lap显示/隐藏，独立切换正常。
- hardware包**166,796 bytes**沿用同一App ID和开发密钥，已更新到USB连接的Edge840 `GARMIN/APPS/SUMMIT.PRG`并回读逐字节一致。替换前已回读验证并保留旧包。尚待断开USB后设备加载；真实导航剩余距离、雷达覆盖和户外可读性仍需真机观察。

以下保留旧版验收记录。

# FastRider v0.3.5：顶部2px、更大标记、更疏中区与完整图头；合并车铃

主数字上提，可见顶部留白2px。Zone29px仍留在雷达下方，避免其被系统图层盖住；单位行移到baseline62，图标紧邻文字，避免与Zone重叠。位置标记由3×16扩大为4×22px，8px黑色/6px白色/8px黑色；色条上移到y76。

中间区从y91开始；左侧标签106/170、数字149/212。统计标题105、计时132、均功率180、距离212，计时与均功率、均功率与距离的实际字形空白均约9px。图头左侧累计爬升`1000 ft`，中心范围，右侧完整`h:mm AM/PM`，保持18px与77px高功率图。

按用户侧聊交接，仅复制车铃的5个文件到当前隔离工作树，与新布局共同验收。左侧x<122/y<214双击播放1500ms电子铃声，单击不改数据；重复触发冷却1600ms，其他区仍立即切换。侧聊已归档关闭；原检出目录的未提交文件没有被重置或覆盖。

- live / hardware / demo / test均构建通过，无告警。使用原有开发密钥和App ID。
- Garmin VM **27/27**：原有23项与车铃4项一起执行。[原始输出](simulator-tests.txt)。更新主数字顶部、标记与单位/中区间距、新点击边界、三列图头字宽；新增格式断言覆盖午夜/正午AMPM、爬升米到ft、0、缺失和负值。
- [原生246×322截图](fastrider-edge840-v035-default.png)使用demo合成值。[像素证据](layout-v035-pixels.json)确认两侧主数字第一行可见像素均y2、标记黑8/白6/黑8及雷达区全白；浮动值的字形顶边可能有正常字体的单像素差异，固定基线避免抖动。
- [七次实际点击日志](interaction-v035.txt)：新统计上边界原生[200,94]正确切换统计，不再误切功率；功率3s/10s与居中范围5m/20m/All均完整循环。
- [车铃原生日志](bell-simulator-v035.txt)：单击不触发；连续双击两组仅提交一次1500ms播放请求，随后功率点击立即处理，无API异常。这是API/触控验收，不将其等同于真机音色/响度试听。
- 真实demo字段heap读数57,016 /127,424 bytes。硬件调试包161,020 bytes已写入已连接的Edge840并回读逐字节一致，等待断开USB后加载及真机试听。设备活动、路线、原日志与设置均保留。

以下保留旧版验收记录。

# FastRider v0.3.4：数字旁Zone、单位行图标与反色标记

心率和功率均把Zone放到主数字右侧，共用baseline56：主数字58 px、Zone29 px；四位功率回退36 px时Zone同步为18 px。两侧都保留右上雷达空间。红心与闪电移到单位行，底端对齐bpm/W的baseline76。

位置标记由3×10增为3×16 px：y83…87黑色、y88…93白色、y94…98黑色；计算仍是当前编号Zone内的位置，功率标记仍跟随3s/10s均值。单位行与加长标记之间保留空隙，缺失信号隐藏标记。

另外修复上一版字体AA白底逻辑行框会遮住邻行的问题：字体生成器输出FontInk.mc真实字形边界，drawText只在该边界内绘制。计时、AVG、距离及mph下沿均完整，继续保留灰度抗锯齿。生成器自动维护字号和边界；去掉26 px计时回退字库中不用的括号，避免无关下降部扩大背景裁剪。

- live / hardware / demo / test构建通过，无编译告警；Garmin VM **23/23**。[原始输出](simulator-tests.txt)。
- 真实Dc字宽验证数字加半高Zone仍在单格内、雷达不遮挡、单位与标记分离；检查三种计时字号和均功率行的真实字形边界不重叠。12种模式组合、四位实时功率、12h/100h计时等回退均经过原生绘制。
- [原生246×322截图](fastrider-edge840-v034-default.png)来自File→Save Screen Capture，数据为demo合成值。模拟器实际点击3s→10s及All→LAP，确认Zone/均值与标记更新；回切后保持3s/All/5m。
- [像素验收](zone-marker-v034-pixels.json)：固定HR158标记上/下各5px均为纯黑，中段6px为纯白；雷达保留区保持全白。目视确认Zone对齐、图标同单位行，计时和字母没有被相邻行白底擦除。
- 真机尚未更新到本版：设备当前未USB连接。候选包157004 bytes已备好，沿用App ID/签名/设置；真实雷达图层和骑行可读性待Edge840确认。

以下保留旧版本记录。

# FastRider v0.3.3：图形与文字抗锯齿

修复三层渲染设置：原先显式关闭的图形AA改为开启；字体资源明确antialias=true；字库由白RGB/透明alpha改为黑底灰度覆盖率PNG，文字使用实际白色页面背景混合。字体尺寸、字宽、布局、训练区间及点击规则不变。

- 按[Garmin图形文档](https://developer.garmin.com/connect-iq/articles/core-topics/Graphics.html#anti-aliasing)开启原生多边形/线条AA；按[字体资源文档](https://developer.garmin.com/connect-iq/articles/core-topics/Resources.html#fonts)保留自定义字体的抗锯齿信息。灰度字库和白底绘制的组合已经用原生输出像素验证有效。
- **不是只检查开关**：比较未经处理的246×322截图，固定demo HR158区域由2种颜色增至4种、cadence64与Z4编号也由2增至4、红心由2增至12；图形和文字均实际产生过渡色。见[像素证据](antialias-pixels.json)、[原生AA截图](fastrider-edge840-v033-aa.png)及此前v0.3.2截图。
- 同一HR色条（含黑色位置标记）与中央竖分隔的裁剪区域，前后逐字节相同；整数坐标的色条/分隔没有因开启AA变模糊；右上雷达保留区及顶部/底部2px边距也经像素检查保持全白。
- 初次只开启图形/字体资源开关时，图标已平滑但HR仍只有2色；该诊断截图保存在本地。最终灰度字体输出才记为完成。
- live / hardware / demo / test构建均通过，无编译告警；Garmin VM **23/23**，包括9套字体字宽、12种原生绘制模式和24h历史压缩。[原始输出](simulator-tests.txt)。新字体资源通过完整回归，未添加镜像开关的测试。
- 当时检查确认边缘平滑，但漏掉了文字白底逻辑行框擦除邻行的问题；v0.3.4已追加修复和行间边界验收。真实demo字段heap读数54,704 /127,424 bytes；这是字段heap，不代表字体/图形资源额外开销为零。字体全部加载及12种状态绘制未出现内存错误。
- v0.3.3硬件候选包156,476 bytes；设备当前未USB连接，最终AA版本尚未写入真机。

以下保留旧版本记录。

# FastRider v0.3.2：大号Zone、2px外边距与简化图表

整合两轮界面要求：Zone从18增至28 px；内容外扩至2 px边距，曲线及Lap顶帽在边缘仍保留1–2 px。主数字x2/x126、baseline44；红心16×14、闪电14×16，底端均y52。中间分隔对齐x122，统计区扩至x126…244，均功率54 px；右上雷达保留区不变。

图头删除总时长；范围和时钟统一18 px，范围在左、时钟在右。移除整排底部距离/爬升文字和无用字体；绘图区从47 px增高至77 px（x4…242、y243…319），底部留下2 px。图表点击范围随之延长至y319。

- live / hardware / demo / test均构建通过，无编译告警。
- Garmin VM **23/23**。[原始输出](simulator-tests.txt)。真实Dc字宽覆盖大号Zone和W10s间距、三位/四位功率雷达边界、均功率与AVG、统计计时/距离；绘图覆盖12个模式组合及缺失/长值。新增映射断言检查扩展后的左右/上下边界、低/超高功率夹取；交互断言覆盖新统计左边界与图表底部，y320留白不响应。
- 模拟器实际点击[七次日志](interaction-v032.txt)：3s↔10s、All↔LAP、5m→20m→All→5m。图表点击来自原生坐标 **[4,316]**，确认新增的底部区域也可切换。
- 目视检查默认、LAP/20m及All图：无总时长和底栏残留；时钟/范围同字体，数字/单位未重叠，曲线和圈边界延伸到底部。
- File→Save Screen Capture导出[默认3s/All/5m](fastrider-edge840-v032-default.png)、[10s/LAP/20m](fastrider-edge840-v032-lap.png)，均246×322；数据为demo合成值。真实demo字段堆54,696 / 127,424 bytes。
- 硬件候选包151,740 bytes已备好；本轮中间v0.3.1已上传并回读验证，但**最终v0.3.2尚未安装：设备已断开USB**。待重新连接后更新，不能把中间包当作本轮最终部署。
- 真实雷达覆盖、实际骑行、太阳光/眼镜可读性仍需Edge840观察；模拟器没有复现系统雷达图层。

以下保留此前版本记录，描述的是当时的布局。

# FastRider v0.3.0 真机反馈：雷达避让与数值放大

根据用户的 Edge 840 照片调整：心率/功率数字左对齐，图标改在右侧；右上保留 x218…245 / y0…33 空白，功率闪电位于安全区下方。三位功率58 px、四位功率36 px，均留在 x218 左侧。

主要数字58/38/50/32 px，图中时间26 px、底栏24 px；labels和单位18 px。统计标题单独置于计时上方；圈距离的数字与mi单位拆开绘制。图顶部向下4 px，为大计时留出间隙。窄格优先完整大字整数（22.4 mph→22、-16.4%→-16），能容纳的6.4%仍保留小数；长统计时间回退30/26 px。底栏延续宽度不足时减少距离小数、最后隐藏剩余括号的策略。

- live / hardware / demo / test 构建通过，无编译告警。
- Garmin VM **23/23**，原生 Dc 12种模式及缺失/长数据绘制通过；字宽验收覆盖三位/四位功率不进入雷达保留区、120 rpm、负坡度、三位mph、12小时计时、四位均功率和圈距离。
- [原始测试输出](simulator-tests.txt)。本轮没有添加镜像实现的测试；更新原生字体宽度和边界断言。
- 真实demo字段堆55,512 / 127,424 bytes。硬件包153,004 bytes已上传并回读逐字节相同，待断开USB加载。
- 用户解锁后，已完成原生模拟器目视检查：3s / All / 5m、10s / LAP / 20m、3s / All / All；放大的数字、统计标题/计时/均功率/距离没有相互遮挡，竖线保持对齐。
- 实际屏幕点击完成3s↔10s、All↔LAP、5m→20m→All→5m完整循环，[七次原生点击日志](interaction-v030.txt)；等待下一绘制帧核对画面，未以旧帧误判点击结果。
- 通过 File → Save Screen Capture 导出[默认界面](fastrider-edge840-v030-default.png)和[10s / LAP / 20m](fastrider-edge840-v030-lap.png)，均为246×322；数据是demo合成值，非真实骑行。没有修改代码或重复已通过的23项测试。
- 模拟器没有复现真实雷达系统图层；本轮检查确认保留区域和数字宽度，真实雷达覆盖与骑行可读性仍需用户在Edge840观察。[含雷达位置的布局示意](design/fastrider-v030-layout-preview.png)仍保留，明确不是原生截图。

# FastRider v0.2.4 分隔线对齐

中间竖向分隔线原先比上方右偏 4 px（x=126 与 x=122）。现在两段统一使用 `DisplayRules.COLUMN_DIVIDER=122`，宽度均为 2 px；矢量稿同步修正。字号、内容位置与触控范围保持原值。

live / hardware / demo 构建通过，无编译告警；模拟器目视确认上下对齐，[246×322 原生截图](fastrider-edge840-v024-aligned.png)。这次仅调整绘制坐标，没有新增或重复模型测试。真机更新包已上传并回读校验一致，待断开 USB 后加载。

# FastRider v0.2.3 改名验证

应用显示名、入口类及相关源码类、构建文件、VS Code 任务和当前矢量稿标题已改为 FastRider。保留 App ID 与签名密钥。live / hardware 构建通过，改名后的 Garmin VM 回归 **23/23**，无编译告警；输入事件测试夹具继承并初始化原生 ClickEvent，避免重命名改变编译顺序后暴露的类型不匹配。

已更新当前连接的 Edge 840 安装包并回读比对一致，待断开 USB 后加载改名版本。历史截图、日志及其文件名保留原记录。

# Edge 840 v0.2.2 验证记录

日期：2026-10-24。新增实时心率/功率 Zone 位置竖线，原生 3×10 px，色条仍为 108×6 px。按当前编号 Zone 线性定位，不按合并颜色组定位；端点留在色条内，缺失时隐藏。Z7 没有有限上界，固定在右端。

- live / demo / hardware / test 均构建通过，无编译告警。
- Garmin VM **23/23**，新增首区、末区、精确阈值、跨区、区间中点、越界、缺失、无效边界及 3s/10s 不同均值对应的定位测试；[原始输出](simulator-tests.txt)。
- 模拟器实际绘制并确认两条黑色竖线。原生点击功率区收到 `Tap [200,50] -> 10s, All, 5m`，下一帧功率数值、Zone 和竖线同步更新。
- [246×322 原生模拟器截图](summit-edge840-v022-zone-marker.png)由 File → Save Screen Capture 导出，传感器值为 demo 合成数据。该时刻 demo 字段堆为 54,520 / 127,424 bytes。
- 真机 Edge 840 固件 31.33：用户确认此前硬件版正常显示 `3s / All / 5m`；回读日志还确认真实触控的 3s↔10s、All↔LAP、5m→20m→All，实际字段堆为 37,888 / 127,592 bytes。原始设备日志仅保存在 `.local/`。
- v0.2.2 hardware 包已上传 `GARMIN/APPS/SUMMIT.PRG` 并回读逐字节验证，149,980 bytes。**新竖线的真机运行仍待断开 USB 后观察**；尚无骑行传感器或长骑验收。

以下保留 v0.2.1 的详细验收记录。

## Edge 840 v0.2.1 验证记录

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

- 已有真机加载与三处触控日志；太阳光、眼镜下可读性、自动圈、真实电子变速及功率计丢包、实际骑行仍待实机。
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
