# 双击组合电子铃声

- 响应区：左侧心率及实时数据，原生坐标 `0 ≤ x < 122`、`0 ≤ y < 214`。中央分隔、右侧统计和功率图不属于响铃区域。
- 单击不修改数据；两次点击间隔不超过400ms、落点相距不超过24px时响一组。跨区域、长按或时钟回退会清理待配对点击。
- 三种原生声音按五段组合：`LOUD_BEEP → ALERT_HI → LOUD_BEEP → ALERT_LO → LOUD_BEEP`，三次响亮主击中穿插高/低音提示各一次。第一击立即调用，后续由`DataField.compute()`的每秒更新推进，通常约4–5秒完成请求；每段实际音色、响度、时长及连续请求的处理由Edge固件决定，未测量真实声压或声音持续时间。
- DataField不在Timer模块支持的上下文中，且自定义ToneProfile数组只能接受频率/时长，不能直接混入原生预设。因此采用非阻塞状态机，不使用Timer、sleep、忙等待或连续调用挤掉前一个预设。
- 后续请求间隔至少800ms，每次compute最多一个声音；迟到超过1500ms、整体超过5秒或系统时钟回退时取消余下部分，避免延迟后突发补响。切页(onHide)、活动重置或应用停止也取消后续音符；已发出的原生预设可能继续结束。
- 双击触发后5500ms内忽略左侧新点击，防止反复重启整组；右侧和图表的切换仍立即处理。该冷却独立于原生声音时长。
- 沿用App ID和界面；仍支持活动未开始和暂停时响铃。真实硬件铃感需Edge840试听。

`BellTests.mc`覆盖双击边界、冷却精确到期、路由、非全屏禁用、1Hz逐步推进、重复tick、延迟不补响、时钟回退及切页/重置/停止取消；模型测试不播放真实声音。

官方依据：[原生声音及ToneProfile参数](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#playTone-instance_function)、[Timer支持的应用类型](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer.html)、[DataField每秒compute](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/DataField.html)。
