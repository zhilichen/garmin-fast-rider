import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Test;

(:test)
function normalizedPowerConstantTest(logger) {
    var n = new NormalizedPower();
    for (var i = 0; i < 30; i += 1) { n.update(i*1000, 200, true); }
    Test.assert(n.value() == null);
    n.update(30000, 200, true); assertNear(n.value(),200.0);
    Test.assert(!n.estimated); Test.assertEqual(n.count,1);
    n.update(30000,999,true); Test.assertEqual(n.count,1);
    for (var i = 31; i <= 3600; i += 1) { n.update(i*1000,200,true); }
    assertNear(n.value(),200.0); Test.assertEqual(n.window.size(),30);
    n.reset(); Test.assert(n.value() == null && !n.estimated);
    for (var i = 0; i <= 30; i += 1) { n.update(i*1000,0,true); }
    assertNear(n.value(),0.0);
    return true;
}

(:test)
function normalizedPowerIntervalsTest(logger) {
    var n = new NormalizedPower();
    for (var i = 0; i <= 60; i += 1) { n.update(i*1000,i < 30 ? 200 : 0,true); }
    // Independent 30 s sliding-window fourth-power reference, including zeros.
    assertNear(n.value(),135.3952);
    n.reset();
    for (var i = 0; i <= 60; i += 1) { n.update(i*500,200,true); }
    assertNear(n.value(),200.0);
    var count = n.count;
    n.update(30000,900,false); n.breakSample();
    n.update(30000,200,true); n.update(31000,200,true);
    assertNear(n.value(),200.0); Test.assertEqual(n.count,count+1);
    n.update(0,100,true); Test.assert(n.value() == null);
    return true;
}

(:test)
function normalizedPowerMissingTest(logger) {
    var n = new NormalizedPower();
    n.update(50000,200,true); Test.assert(n.estimated);
    for (var i = 51; i <= 80; i += 1) { n.update(i*1000,200,true); }
    assertNear(n.value(),200.0);
    var count = n.count;
    n.update(81000,null,true); n.update(82000,300,true); n.update(83000,300,true);
    Test.assertEqual(n.count,count); Test.assert(n.estimated);
    n.update(90000,300,true); Test.assertEqual(n.window.size(),0);
    n.started(0); Test.assert(n.value() == null && !n.estimated);
    return true;
}

(:test)
function summaryStateTransitionsTest(logger) {
    var s = new RideScreenState(); Test.assert(!s.summary());
    s.update(Activity.TIMER_STATE_ON); Test.assert(!s.summary());
    s.update(Activity.TIMER_STATE_PAUSED); Test.assert(s.summary());
    s.update(null); Test.assert(s.summary());
    s.update(Activity.TIMER_STATE_STOPPED); Test.assert(s.summary());
    s.update(Activity.TIMER_STATE_ON); Test.assert(!s.summary());
    s.reset(); Test.assert(!s.summary());
    var v = new FastRiderView(); v.computeDemo();
    var selected = v.ui.powerSeconds;
    v.onTimerPause(); Test.assert(v.screen.summary());
    Test.assert(!v.handleTap(Layout.RIGHT_EDGE,Layout.u(40)));
    Test.assertEqual(v.ui.powerSeconds,selected);
    v.onTimerResume(); Test.assert(!v.screen.summary());
    v.onTimerStop(); Test.assert(v.screen.summary());
    v.onTimerStart(); Test.assert(!v.screen.summary());
    v.onTimerReset(); Test.assert(!v.screen.summary());
    return true;
}

(:test)
function summaryRenderBoundariesTest(logger) {
    var dc = TestPlatform.dc(Layout.WIDTH,Layout.HEIGHT);
    var v = new FastRiderView(); v.loadFonts(); v.computeDemo(); v.onTimerStop();
    for (var mode = 0; mode < 2; mode += 1) {
        v.theme.setBackground(mode == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
        SummaryRenderer.draw(v,dc); v.drawChartHeader(dc); v.drawPowerTrend(dc);
        v.millis = 360000000; v.meters = 300.5*1609.344; v.remainingDistance = 200.5*1609.344;
        v.ridePower = 1234; v.ascent = 30479.6952;
        var p = v.distancePartsWithin(dc,v.meters,v.remainingDistance,true,Layout.RULE_WIDTH,
            SummaryRenderer.room(SummaryLayout.DISTANCE_LABEL,SummaryLayout.DISTANCE_VALUE));
        Test.assertEqual(p[0],"300.5"); Test.assertEqual(p[1],"(-200.5)");
        Test.assert(v.distanceRowWidth(p) <= Layout.RULE_WIDTH);
        SummaryRenderer.draw(v,dc); v.drawChartHeader(dc); v.drawPowerTrend(dc);
        v.hr = null; v.averageHr = null; v.meters = null; v.millis = null;
        v.remainingDistance = null; v.ridePower = null; v.normalized.reset();
        SummaryRenderer.draw(v,dc); v.drawChartHeader(dc); v.drawPowerTrend(dc);
    }
    for (var range = 0; range < 3; range += 1) {
        v.ui.range = range;
        var half = DisplayRules.pixel(v.rangeWidth(dc,v.ui.rangeLabel())/2.0);
        var left = Layout.LEFT_EDGE+v.textWidth(dc,"99999",4)+Layout.STATS_GAP+v.textWidth(dc,"ft",12);
        var right = Layout.RIGHT_EDGE-v.textWidth(dc,"AM",3)-Layout.PACKED_GAP-v.textWidth(dc,"12:59",4);
        Test.assert(left+Layout.u(2) <= Layout.WIDTH/2-half);
        Test.assert(Layout.WIDTH/2-half+v.rangeWidth(dc,v.ui.rangeLabel())+Layout.u(2) <= right);
    }
    Test.assert(v.plotTop() > Layout.PLOT_TOP && v.plotTop() < Layout.PLOT_BOTTOM);
    v.onTimerResume(); Test.assertEqual(v.plotTop(),Layout.PLOT_TOP);
    return true;
}
