// Last 3/10 seconds of 1 Hz observations. Missing power is not zero.
// Strict lower window boundary gives exactly 3 / 10 samples at 1 Hz.
import Toybox.Lang;
class PowerAverage {
    var samples as Lang.Array<Lang.Array<Lang.Numeric>> = [];
    var lastTime = null;
    function initialize() { reset(); }
    function reset() { samples = []; lastTime = null; }
    function update(t, watts, running) {
        if (t == null || !running || watts == null || watts < 0) { reset(); return; }
        if (lastTime != null) {
            if (t == lastTime) { return; }
            if (t < lastTime || t-lastTime > 2500) { reset(); }
        }
        lastTime = t;
        samples.add([t, watts]);
        while (samples.size() > 0 && samples[0][0] <= t-10000) { samples.remove(samples[0]); }
        while (samples.size() > 20) { samples.remove(samples[0]); }
    }
    function average(seconds) {
        if (lastTime == null) { return null; }
        var sum = 0.0; var count = 0;
        for (var i = 0; i < samples.size(); i += 1) {
            if (samples[i][0] > lastTime-seconds*1000) { sum += samples[i][1]; count += 1; }
        }
        return count == 0 ? null : sum/count;
    }
}
