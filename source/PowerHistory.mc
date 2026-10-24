import Toybox.Lang;

// Five minutes of elapsed activity time, including blank pause/sensor gaps.
class PowerHistory {
    const WINDOW_MS = 300000;
    const BUCKET_MS = 3000;
    const MAX_POINTS = 160;
    const MAX_LAPS = 100;
    // [first timestamp, last timestamp, sum watts, sample count, segment]
    var points as Lang.Array<Lang.Array<Lang.Numeric>> = [];
    var boundaries as Lang.Array<Lang.Numeric> = [];
    var endTime = null;
    var lapStart = null;
    var lastSample = null;
    var segment = 0;
    var needsBreak = true;

    function initialize() { reset(); }
    function reset() {
        points = []; boundaries = []; endTime = null; lapStart = null;
        segment = 0; breakSample();
    }
    function breakSample() { needsBreak = true; lastSample = null; }
    function started(t) {
        // Loading a data page during an activity is not a native lap start.
        if (t != null && t == 0 && lapStart == null) { beginLap(t); }
    }
    function beginLap(t) {
        if (t == null || t < 0) { return; }
        if (lapStart != null && t <= lapStart) { return; }
        lapStart = t;
        boundaries.add(t);
        if (endTime == null || t > endTime) { endTime = t; }
        breakSample(); prune();
    }
    function update(t, watts, running) {
        if (t == null || t < 0) { breakSample(); return; }
        if (endTime != null && t < endTime) { reset(); }
        endTime = t; prune();
        if (t == 0 && lapStart == null) { beginLap(0); }
        if (!running || watts == null || watts < 0) { breakSample(); return; }
        if (lastSample != null && t == lastSample) { return; }
        if (lastSample != null && t-lastSample > 2500) { breakSample(); }
        if (needsBreak) { segment += 1; needsBreak = false; }
        var bucket = (t/BUCKET_MS).toNumber();
        var last = points.size() > 0 ? points[points.size()-1] : null;
        if (last != null && last[4] == segment && (last[0]/BUCKET_MS).toNumber() == bucket) {
            last[1] = t; last[2] += watts; last[3] += 1;
        } else { points.add([t, t, watts, 1, segment]); }
        lastSample = t;
        while (points.size() > MAX_POINTS) { points.remove(points[0]); }
    }
    function prune() {
        if (endTime == null) { return; }
        var first = endTime-WINDOW_MS;
        while (points.size() > 0 && points[0][1] < first) { points.remove(points[0]); }
        while (boundaries.size() > 0 && boundaries[0] < first) { boundaries.remove(boundaries[0]); }
        while (boundaries.size() > MAX_LAPS) { boundaries.remove(boundaries[0]); }
    }
    function ceiling(ftp) {
        var top = ftp*1.5;
        for (var i = 0; i < points.size(); i += 1) {
            var watts = points[i][2]/points[i][3].toFloat();
            while (top < watts) { top += ftp*0.5; }
        }
        return top;
    }
    function startLabel() {
        if (lapStart == null || endTime == null) { return "LAP SYNC"; }
        var age = endTime-lapStart;
        if (age > WINDOW_MS) { return "LAP START <-5m"; }
        var sec = (age/1000).toNumber();
        return "LAP START -"+(sec/60).toNumber().format("%d")+":"+(sec%60).format("%02d");
    }
}
