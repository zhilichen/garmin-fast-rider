# 双击两秒三击铃声

- 响应区：左侧心率及实时数据，原生坐标`0 ≤ x < 107`、`0 ≤ y < 214`。单击不修改数据，400ms/24px范围内双击响一组；右侧与图表立即切换。
- 不再使用原生响亮蜂鸣或高/低提示预设。一次`Attention.playTone({:toneProfile=>...})`提交44个ToneProfile，所有音符与静音合计**2000ms**，不设置repeatCount。无Timer、sleep、忙等待或compute推进。
- 三次敲击在0/600/1200ms开始；前两击各600ms，末击800ms。5600Hz短起音，2800/4400Hz两种共振音高交替；尾部使用短音符和逐渐拉开的静音，近似金属余响。API不能控制音量包络或叠加多个频率，属于单音蜂鸣器的铃感近似。
- 音符和静音均为25ms的整数倍。0Hz静音沿用Garmin SDK 9.3.0官方`Attention/resources-jsondata/jsondata.xml`生日歌样例的做法；末尾是可听音符，其结束点为2000ms，未用尾部静音凑时长。总计1275ms有声、725ms静音。
- 代码在提交前校验总时长；无法使用ToneProfile或时长不符时返回失败，不用未知时长的系统预设兜底。2100ms输入冷却包含2000ms声音及100ms防重触发余量，冷却不发声。
- 完整序列一次交给原生音调引擎，不再有切页后待compute触发的后续请求；也没有公开停止播放接口。系统通知、固件实现和硬件起停延迟仍可能影响实际声学输出，2000ms指提交的音符/静音时长，并非麦克风实测的硬实时保证。音色需在Edge840试听。

`BellTests.mc`覆盖双击/冷却/路由、2000ms总和、三次敲击的精确位置、静音与末尾音符，以及2秒后再次触发。模型测试不播放声音。

官方依据：[ToneProfile频率/时长与顺序播放](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/ToneProfile.html)、[playTone](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#playTone-instance_function)。
