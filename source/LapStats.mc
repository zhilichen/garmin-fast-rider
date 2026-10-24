// Garmin supplies lap boundary callbacks, not the native lap average power.
// Synchronize those boundaries and integrate observed power over timerTime.
class LapStats {
    var synced = false;
    var startTimer = null;
    var lastTimer = null;
    var lastPower = null;
    var observedTimer = null;
    var timeMs = null;
    var averagePower = null;
    var wattMillis = 0.0;
    var validMillis = 0;

    function initialize() { reset(); }
    function reset() {
        synced = false; startTimer = null; timeMs = null;
        observedTimer = null;
        wattMillis = 0.0; validMillis = 0; averagePower = null;
        breakSample();
    }

    function breakSample() { lastTimer = null; lastPower = null; }

    function begin(timer, power) {
        reset();
        if (timer == null) { return; }
        synced = true; startTimer = timer; timeMs = 0;
        observedTimer = timer;
        lastTimer = timer;
        lastPower = power != null && power >= 0 ? power : null;
    }

    function started(timer) {
        // onTimerStart is also sent when a running activity loads this field.
        // A nonzero timer does not reveal the current native lap's start.
        breakSample();
        if (timer != null && timer == 0) { begin(0, null); }
    }

    function update(timer, power, running) {
        if (timer == null) { timeMs = null; breakSample(); return; }
        if (observedTimer != null && timer < observedTimer) { reset(); }
        if (synced && timer < startTimer) { reset(); }
        if (!synced && timer == 0) { begin(0, null); }
        observedTimer = timer;
        timeMs = synced ? timer-startTimer : null;
        if (!running || !synced) { breakSample(); return; }
        var validPower = power != null && power >= 0 ? power : null;
        if (lastTimer != null) {
            var dt = timer-lastTimer;
            // Include valid zero watts. Do not bridge sensor gaps or pauses.
            if (dt > 0 && dt <= 2500 && lastPower != null && validPower != null) {
                wattMillis += (lastPower+validPower)*0.5*dt;
                validMillis += dt;
                averagePower = wattMillis/validMillis;
            }
        }
        lastTimer = timer; lastPower = validPower;
    }
}
