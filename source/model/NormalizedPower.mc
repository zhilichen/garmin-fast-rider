import Toybox.Math;
import Toybox.Lang;

// Local NP estimate: complete 30 s rolling means, fourth-power mean, fourth root.
// Resample observed power to 1 s of active timer time with sample-and-hold.
// Pauses add no zeros; missing data is not zero and invalidates the rolling window.
class NormalizedPower {
    var window as Lang.Array<Lang.Float> = [];
    var cursor = 0;
    var sum = 0.0;
    var fourthSum = 0.0;
    var count = 0;
    var bucketMs = 0;
    var bucketWattMs = 0.0;
    var lastTimer = null;
    var lastPower = null;
    var observedTimer = null;
    var estimated = false;

    function initialize() { reset(); }
    function reset() {
        clearWindow(); fourthSum = 0.0; count = 0;
        lastTimer = null; lastPower = null; observedTimer = null; estimated = false;
    }
    function clearWindow() { window = []; cursor = 0; sum = 0.0; bucketMs = 0; bucketWattMs = 0.0; }
    function breakSample() { lastTimer = null; lastPower = null; }
    function started(timer) {
        if (timer == 0) { reset(); observedTimer = 0; }
        else { breakSample(); }
    }
    function addSecond(watts) {
        if (window.size() == 30) { sum -= window[cursor]; window[cursor] = watts; }
        else { window.add(watts); }
        sum += watts; cursor = (cursor+1)%30;
        if (window.size() == 30) {
            // Scale before raising to the fourth power to limit floating error.
            var mean = sum/30000.0;
            var square = mean*mean;
            fourthSum += square*square; count += 1;
        }
    }
    function update(timer, watts, running) {
        if (timer == null || timer < 0) { breakSample(); return; }
        if (observedTimer != null && timer < observedTimer) { reset(); }
        if (running && lastTimer == null && timer > (observedTimer == null ? 0 : observedTimer)) { estimated = true; }
        observedTimer = timer;
        if (!running) { breakSample(); return; }
        if (watts == null || watts < 0) {
            estimated = true; clearWindow(); breakSample(); return;
        }
        if (lastTimer != null) {
            var dt = timer-lastTimer;
            if (dt == 0) { return; }
            if (dt > 2500) { estimated = true; clearWindow(); }
            else {
                while (dt > 0) {
                    var step = dt < 1000-bucketMs ? dt : 1000-bucketMs;
                    bucketWattMs += lastPower*step; bucketMs += step; dt -= step;
                    if (bucketMs == 1000) {
                        addSecond(bucketWattMs/1000.0); bucketMs = 0; bucketWattMs = 0.0;
                    }
                }
            }
        }
        lastTimer = timer; lastPower = watts;
    }
    function value() { return count == 0 ? null : 1000.0*Math.sqrt(Math.sqrt(fourthSum/count)); }
}
