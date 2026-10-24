import Toybox.Test;

(:test)
function interactionCyclesTest(logger) {
    var ui = new InteractionState();
    Test.assertEqual(ui.powerSeconds, 3); Test.assert(ui.allStats); Test.assertEqual(ui.range, 0);
    Test.assert(!ui.tap(Layout.RIGHT_TAP_LEFT-1, Layout.u(52))); Test.assert(!ui.tap(Layout.RIGHT_EDGE-Layout.u(94), Layout.PRIMARY_BOTTOM));
    Test.assert(!ui.tap(Layout.u(20), Layout.PLOT_BOTTOM+1)); Test.assert(!ui.tap(Layout.WIDTH, Layout.u(30))); Test.assert(!ui.tap(-1, Layout.u(30)));
    for (var p = 0; p < 2; p += 1) {
        for (var s = 0; s < 2; s += 1) {
            for (var r = 0; r < 3; r += 1) {
                Test.assertEqual(ui.powerSeconds, p == 0 ? 3 : 10);
                Test.assertEqual(ui.allStats, s == 0); Test.assertEqual(ui.range, r);
                Test.assert(ui.tap(Layout.WIDTH/2, Layout.HEADER_BASELINE));
            }
            Test.assert(ui.tap(Layout.RIGHT_EDGE-Layout.u(44), Layout.STATS_TIME_BASELINE));
        }
        Test.assert(ui.tap(Layout.RIGHT_EDGE-Layout.u(44), Layout.u(50)));
    }
    Test.assertEqual(ui.rangeLabel(), "5m");
    ui.tap(Layout.RIGHT_TAP_LEFT, Layout.PRIMARY_BOTTOM-1); Test.assertEqual(ui.powerSeconds, 10);
    Test.assert(!ui.tap(Layout.RIGHT_TAP_LEFT, Layout.PRIMARY_BOTTOM));
    Test.assert(!ui.tap(Layout.RIGHT_TAP_LEFT-1, Layout.STATS_TIME_BASELINE));
    Test.assert(ui.tap(Layout.RIGHT_TAP_LEFT, Layout.MIDDLE_TOP)); Test.assert(!ui.allStats);
    Test.assert(ui.tap(Layout.RIGHT_TAP_LEFT, Layout.MIDDLE_TOP)); Test.assert(ui.allStats);
    Test.assert(ui.tap(Layout.RIGHT_TAP_LEFT, Layout.STATS_TIME_BASELINE)); Test.assert(!ui.allStats);
    Test.assert(ui.tap(Layout.RIGHT_EDGE, Layout.STATS_TIME_BASELINE)); Test.assert(ui.allStats);
    Test.assert(ui.tap(Layout.PLOT_LEFT, Layout.PLOT_BOTTOM)); Test.assertEqual(ui.range, 1);
    ui.reset(); Test.assertEqual(ui.powerSeconds, 3); Test.assert(ui.allStats);
    return true;
}

(:test)
function viewInteractionPreservesDataTest(logger) {
    var v = new FastRiderView();
    v.computeDemo();
    var time = v.lap.timeMs; var distance = v.lap.distance;
    var laps = v.trend.boundaries.size(); var points = v.trend.points.size();
    Test.assert(v.handleTap(Layout.RIGHT_EDGE-Layout.u(44), Layout.u(40))); Test.assert(v.handleTap(Layout.RIGHT_EDGE-Layout.u(44), Layout.STATS_TIME_BASELINE)); Test.assert(v.handleTap(Layout.WIDTH/2, Layout.HEADER_BASELINE));
    Test.assertEqual(v.ui.powerSeconds, 10); Test.assert(!v.ui.allStats); Test.assertEqual(v.ui.range, 1);
    Test.assertEqual(v.lap.timeMs, time); Test.assertEqual(v.lap.distance, distance);
    Test.assertEqual(v.trend.boundaries.size(), laps); Test.assertEqual(v.trend.points.size(), points);
    // A manually selected All is superseded by the next native lap boundary.
    v.handleTap(Layout.RIGHT_EDGE-Layout.u(44), Layout.STATS_TIME_BASELINE); Test.assert(v.ui.allStats);
    v.onTimerLap();
    Test.assertEqual(v.lapNumber, 4); Test.assertEqual(v.lap.timeMs, 0);
    Test.assert(!v.ui.allStats); Test.assertEqual(v.ui.powerSeconds, 10); Test.assertEqual(v.ui.range, 1);
    v.handleTap(Layout.RIGHT_EDGE-Layout.u(44), Layout.STATS_TIME_BASELINE); Test.assert(v.ui.allStats);
    v.onTimerPause(); v.onTimerResume(); Test.assert(v.ui.allStats);
    Test.assert(TestPlatform.lap(v));
    Test.assertEqual(v.lapNumber, 5); Test.assert(!v.ui.allStats);
    Test.assertEqual(v.ui.powerSeconds, 10); Test.assertEqual(v.ui.range, 1);
    v.onTimerReset();
    Test.assertEqual(v.ui.powerSeconds, 3); Test.assert(v.ui.allStats); Test.assertEqual(v.ui.range, 0);
    Test.assertEqual(v.trend.whole.points.size(), 0); Test.assert(v.lap.timeMs == null);
    return true;
}

class TapStub extends Toybox.WatchUi.ClickEvent {
    var xy;
    var type = 0;
    function initialize(x, y) { ClickEvent.initialize(x, y, Toybox.WatchUi.CLICK_TYPE_TAP); xy = [x, y]; }
    function getCoordinates() { return xy; }
    function getType() { return type; }
}
class TapTarget {
    var ui;
    function initialize() { ui = new InteractionState(); }
    function handleTap(x, y) { return ui.tap(x, y); }
}
(:test)
function inputDelegateTest(logger) {
    var target = new TapTarget(); var input = new FastRiderInputDelegate(target);
    Test.assert(input.onTap(new TapStub(Layout.RIGHT_EDGE-Layout.u(44), Layout.u(50))));
    Test.assertEqual(target.ui.powerSeconds, 10);
    Test.assert(input.onTap(new TapStub(Layout.RIGHT_EDGE-Layout.u(44), Layout.STATS_TIME_BASELINE))); Test.assert(!target.ui.allStats);
    Test.assert(input.onTap(new TapStub(Layout.WIDTH/2, Layout.PLOT_TOP+Layout.u(17)))); Test.assertEqual(target.ui.range, 1);
    Test.assert(!input.onTap(new TapStub(Layout.u(20), Layout.PLOT_BOTTOM+1)));
    var hold = new TapStub(Layout.RIGHT_EDGE-Layout.u(44), Layout.u(50)); hold.type = 1;
    Test.assert(!input.onTap(hold)); Test.assertEqual(target.ui.powerSeconds, 10);
    return true;
}
