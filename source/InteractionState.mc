// Manual selections are independent; native lap boundaries select latest stats.
class InteractionState {
    var powerSeconds = 3;
    var allStats = true;
    var range = 0;
    function initialize() { reset(); }
    function reset() { powerSeconds = 3; allStats = true; range = 0; }
    // Activity start is already native Lap 1. An explicit native lap boundary
    // ends that lap and selects the newly started lap without changing graphs.
    function beganLap() { allStats = false; }
    function rangeLabel() { return range == 0 ? "5m" : (range == 1 ? "20m" : "All"); }
    function tap(x, y) {
        if (x < 0 || x >= 246 || y < 0 || y >= 322) { return false; }
        if (x >= 124 && y < 98) { powerSeconds = powerSeconds == 3 ? 10 : 3; return true; }
        if (x >= 128 && y >= 102 && y < 214) { allStats = !allStats; return true; }
        if (y >= 220 && y < 298) { range = (range+1)%3; return true; }
        return false;
    }
}
