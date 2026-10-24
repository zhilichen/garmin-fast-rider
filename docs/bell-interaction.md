# 双击电子铃声

- 响应区：左侧心率及实时数据，原生坐标 `0 ≤ x < 122`、`0 ≤ y < 214`。中央分隔、右侧统计和功率图不属于响铃区域。
- 单击不修改数据；两次点击间隔不超过400ms、落点相距不超过24px时响一次。跨区域、长按或时钟回退会清理待配对点击。
- 使用Garmin原生`Attention.TONE_LOUD_BEEP`响亮蜂鸣预设，一次`playTone`调用。公开API没有音量/振幅参数，不能设置“100%音量”或保证声压高于其他所有预设；该预设是官方明确标为响亮的蜂鸣。响度与时长由设备原生实现决定，不再使用此前1500ms自定义音调序列。
- 触发后1600ms内忽略左侧新点击，防止连点反复触发；这是输入冷却时间，不代表铃声时长。没有sleep或定时轮询，其他区域切换立即响应。
- 沿用App ID和界面；实际硬件响度仍需Edge840试听。

`BellTests.mc`覆盖双击时间/距离边界、冷却精确到期、跨区、长按/时钟重置、路由和非全屏禁用；模型测试不播放真实声音。

API参考：[Attention.playTone与TONE_LOUD_BEEP](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#playTone-instance_function)。
