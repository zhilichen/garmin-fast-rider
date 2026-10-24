// Manual selections are independent; native lap boundaries select latest stats.
class InteractionState {
    var powerSeconds = 3;
    var allStats = true;
    var range = 0;
    function initialize() { reset(); }
    function reset() { powerSeconds = 3; allStats = true; range = 0; }
    // Activity start is already native Lap 1. An explicit native lap boundary
    // ends that lap and selects the newly started lap without changing graphs.
    function beganLap() { if (InputSupport.ENABLED) { allStats = false; } }
    function rangeLabel() { return range == 0 ? "5m" : (range == 1 ? "20m" : "All"); }
    function tap(x, y) {
        if (!InputSupport.ENABLED || x < 0 || x >= Layout.WIDTH || y < 0 || y >= Layout.HEIGHT) { return false; }
        if (x >= Layout.RIGHT_TAP_LEFT && y < Layout.PRIMARY_BOTTOM) { powerSeconds = powerSeconds == 3 ? 10 : 3; return true; }
        if (x >= Layout.RIGHT_TAP_LEFT && y >= Layout.MIDDLE_TOP && y < Layout.STATS_BOTTOM) { allStats = !allStats; return true; }
        if (y >= Layout.BANNER_TOP && y < Layout.PLOT_BOTTOM+1) { range = (range+1)%3; return true; }
        return false;
    }
}
