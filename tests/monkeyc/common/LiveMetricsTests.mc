import Toybox.Graphics;
import Toybox.Test;

(:test)
function liveMetricFitAndGrowthTest(logger) {
    var dc = TestPlatform.dc(16,16); var v = new FastRiderView(); v.loadFonts();
    var samples = [["5","GEAR",Layout.LIVE_LEFT_WIDTH,48],["12","GEAR",Layout.LIVE_LEFT_WIDTH,48],
        ["64","RPM",Layout.LIVE_RIGHT_WIDTH,58],["120","RPM",Layout.LIVE_RIGHT_WIDTH,58],
        ["6","%",Layout.LIVE_LEFT_WIDTH,48],["-16","%",Layout.LIVE_LEFT_WIDTH,48],
        ["22.4","MPH",Layout.LIVE_RIGHT_WIDTH,58],["100.5","MPH",Layout.LIVE_RIGHT_WIDTH,58]];
    for (var i = 0; i < samples.size(); i += 1) {
        var sample = samples[i];
        var f = LiveMetrics.face(v,dc,sample[0],sample[1],sample[2]);
        var previous = v.liveFont(sample[0],Layout.u(sample[3]));
        Test.assert(v.packedWidth(sample[0],f)+LiveMetrics.labelWidth(v,dc,sample[1])+Layout.LIVE_SIDE_GAP <= sample[2]);
        // Actual visible height must increase, not just the font's nominal size.
        Test.assert(FontInk.TOP[f] > FontInk.TOP[previous]);
    }
    var extremes = [["99","GEAR",Layout.LIVE_LEFT_WIDTH],["999","RPM",Layout.LIVE_RIGHT_WIDTH],
        ["-60","%",Layout.LIVE_LEFT_WIDTH],["60","%",Layout.LIVE_LEFT_WIDTH],["999.9","MPH",Layout.LIVE_RIGHT_WIDTH]];
    for (var i = 0; i < extremes.size(); i += 1) {
        var sample = extremes[i];var f = LiveMetrics.face(v,dc,sample[0],sample[1],sample[2]);
        Test.assert(v.packedWidth(sample[0],f)+LiveMetrics.labelWidth(v,dc,sample[1])+Layout.LIVE_SIDE_GAP <= sample[2]);
    }
    Test.assert(FontInk.TOP[FontInk.LIVE_SIDE_PERCENT] > FontInk.TOP[3]);
    var f = FontInk.LIVE_SIDE_FACES[0];
    Test.assert(LiveMetrics.baseline(Layout.LIVE_CENTER_TOP,f)-FontInk.TOP[f] > Layout.MIDDLE_TOP);
    Test.assert(LiveMetrics.baseline(Layout.LIVE_CENTER_BOTTOM,f)+FontInk.BOTTOM[f]+FontInk.NATIVE_BOTTOM_PAD < Layout.STATS_BOTTOM);
    return true;
}

(:test)
function liveMetricRenderStatesTest(logger) {
    var dc = TestPlatform.dc(Layout.WIDTH,Layout.HEIGHT);
    var v = new FastRiderView();v.loadFonts();v.computeDemo();
    for (var mode = 0; mode < 2; mode += 1) {
        v.theme.setBackground(mode == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
        dc.setColor(v.theme.ink,v.theme.background);dc.clear();
        LiveMetrics.draw(v,dc);
        v.rearGear = 12;v.cadence = 120;v.grade = -16;v.speed = 44.927;
        LiveMetrics.draw(v,dc);
        v.rearGear = null;v.cadence = null;v.grade = null;v.speed = null;
        LiveMetrics.draw(v,dc);
    }
    return true;
}
