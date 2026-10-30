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
        v.averageCadence = 123; v.averageSpeed = 44.927;
        var p = SummaryRenderer.distanceParts(v,dc);
        Test.assertEqual(p[0],"300.5"); Test.assertEqual(p[1],"(-200.5)");
        Test.assert(v.distanceRowWidthFor(p,false) <= SummaryLayout.RIGHT_WIDTH);
        SummaryRenderer.draw(v,dc); v.drawChartHeader(dc); v.drawPowerTrend(dc);
        v.hr = null; v.averageHr = null; v.meters = null; v.millis = null;
        v.remainingDistance = null; v.ridePower = null; v.normalized.reset();
        v.averageCadence = null; v.averageSpeed = null;
        SummaryRenderer.draw(v,dc); v.drawChartHeader(dc); v.drawPowerTrend(dc);
    }
    for (var range = 0; range < 3; range += 1) {
        v.ui.range = range;
        Test.assert(v.rangeWidth(dc,v.ui.rangeLabel()) < Layout.RULE_WIDTH);
    }
    Test.assert(SummaryLayout.COLUMN_DIVIDER < Layout.COLUMN_DIVIDER);
    Test.assert(SummaryLayout.RIGHT_WIDTH > Layout.RIGHT_WIDTH);
    var normal = SummaryRenderer.face(v,dc,"158",FontInk.SUMMARY_VALUE_FACES,SummaryLayout.LEFT_WIDTH,
        SummaryRenderer.room(SummaryLayout.ROW_LABEL_1,SummaryLayout.ROW_VALUE_1));
    if (Layout.WIDTH == 246) { Test.assert(FontInk.TOP[normal] > FontInk.TOP[6]); }
    var decimal = SummaryRenderer.face(v,dc,"100.5",FontInk.SUMMARY_VALUE_FACES,SummaryLayout.RIGHT_WIDTH,
        SummaryRenderer.room(SummaryLayout.ROW_LABEL_4,SummaryLayout.ROW_VALUE_4));
    Test.assert(v.packedWidth("100.5",decimal) <= SummaryLayout.RIGHT_WIDTH);
    Test.assert(FontInk.NUMERIC_RIGHT[decimal][10] > FontInk.NUMERIC_LEFT[decimal][10]);
    var clockRoom = Layout.RADAR_LEFT-Layout.u(2)-Layout.RIGHT_START-v.textWidth(dc,"AM",3)-Layout.STATS_GAP;
    var cf = SummaryRenderer.face(v,dc,"12:59",FontInk.STATS_FACES,clockRoom,
        SummaryRenderer.room(SummaryLayout.HEADER_LABEL,SummaryLayout.HEADER_VALUE));
    Test.assert(v.packedWidth("12:59",cf) <= clockRoom);
    var tf = SummaryRenderer.face(v,dc,"100:00:00",FontInk.STATS_FACES,Layout.LEFT_WIDTH,
        SummaryRenderer.room(SummaryLayout.HEADER_LABEL,SummaryLayout.HEADER_VALUE));
    Test.assert(v.packedWidth("100:00:00",tf) <= Layout.LEFT_WIDTH);
    Test.assert(v.chartTop() > Layout.BANNER_TOP);
    Test.assert(SummaryLayout.HEADER_BASELINE < v.plotTop());
    Test.assert(SummaryLayout.ROW_VALUE_4+FontInk.BOTTOM[1]+FontInk.NATIVE_BOTTOM_PAD < v.chartTop());
    Test.assert(v.plotTop() > Layout.PLOT_TOP && v.plotTop() < Layout.PLOT_BOTTOM);
    v.onTimerResume(); Test.assertEqual(v.plotTop(),Layout.PLOT_TOP);
    return true;
}

(:test)
function nativeSummaryAveragesTest(logger) {
    Test.assert(RideMath.recordedAverage(null,80) == null);
    Test.assert(RideMath.recordedAverage(0,80) == null);
    Test.assert(RideMath.recordedAverage(1000,null) == null);
    Test.assert(RideMath.recordedAverage(1000,-1) == null);
    Test.assertEqual(RideMath.recordedAverage(1000,0),0);
    Test.assertEqual(RideMath.recordedAverage(1000,86),86);
    assertNear(RideMath.recordedAverage(1000,8.9408),8.9408);
    var v = new FastRiderView();v.computeDemo();v.onTimerStop();
    Test.assertEqual(v.averageCadence,86);
    Test.assertEqual(RideMath.speedMphText(v.averageSpeed),"20.0");
    var before = v.ui.range;
    Test.assert(!v.handleTap(Layout.RIGHT_EDGE,SummaryLayout.ROW_VALUE_4));
    Test.assertEqual(v.ui.range,before);
    if (InputSupport.ENABLED) {
        Test.assert(v.handleTap(Layout.WIDTH/2,SummaryLayout.HEADER_BASELINE));
        Test.assertEqual(v.ui.range,(before+1)%3);
    }
    v.onTimerReset();Test.assert(v.averageCadence == null && v.averageSpeed == null);
    return true;
}
