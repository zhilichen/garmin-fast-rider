import Toybox.Graphics;
import Toybox.Test;

(:test)
function inlineRideTimeTest(logger) {
    var dc = TestPlatform.dc(16,16);var v = new FastRiderView();v.loadFonts();
    var titles = ["All","Lap 3","Lap 99","Lap 999"];
    var times = ["05:12","1:23:08","12:23:08","100:00:00","--:--"];
    for (var i = 0; i < titles.size(); i += 1) {
        for (var j = 0; j < times.size(); j += 1) {
            var p = RideStatistics.timeParts(v,dc,titles[i],times[j]);
            Test.assert(v.textWidth(dc,titles[i],p[4])+Layout.STATS_GAP+p[5] <= Layout.RIGHT_WIDTH);
            if (j == 0 || j == 4) { Test.assert(p[1] == null); }
            else {
                Test.assert(p[1].equals(j == 3 ? "00" : "08"));
                // Cap-height rounding and the AA raster can each shift an edge by one pixel.
                var expected = FontInk.TOP[p[2]]*2.0/3;
                Test.assert(FontInk.TOP[p[3]] >= expected-1.5 && FontInk.TOP[p[3]] <= expected+1.5);
            }
            Test.assert(Layout.STATS_TIME_BASELINE-FontInk.TOP[p[2]] > Layout.MIDDLE_TOP);
        }
    }
    Test.assertEqual(Layout.STATS_TITLE_BASELINE,Layout.STATS_TIME_BASELINE);
    return true;
}

(:test)
function raisedZoneAndDistanceTest(logger) {
    var dc = TestPlatform.dc(16,16);var v = new FastRiderView();v.loadFonts();
    var powers = ["77","303","999","1234","9999","65535"];
    for (var i = 0; i < powers.size(); i += 1) {
        var f = v.primaryFont(dc,powers[i]);
        var w = f == 0 ? v.numberWidth(dc,powers[i],f,0) : v.packedWidth(powers[i],f);
        Test.assert(w <= v.powerValueWidth());
        Test.assert(v.primaryBaseline(f)-FontInk.TOP[f] >= 0);
    }
    var hearts = ["158","188","199","240"];
    for (var i = 0; i < hearts.size(); i += 1) {
        var f = v.heartFont(dc,hearts[i]);
        var w = v.numberWidth(dc,hearts[i],f,Layout.HEART_TRACKING);
        Test.assert(w+Layout.PRIMARY_ZONE_GAP+Layout.ZONE_BADGE_WIDTH <= Layout.LEFT_WIDTH);
    }
    var d = v.distanceParts(dc,10.4*1609.344,12.4*1609.344,true);
    Test.assert(d[0].equals("10.4") && d[1].equals("(-12.4)"));
    Test.assert(FontInk.TOP[d[2]] > FontInk.TOP[5]);
    Test.assert(FontInk.TOP[d[3]] > FontInk.TOP[13]);
    Test.assert(v.distanceRowWidth(d) <= Layout.RIGHT_WIDTH);
    return true;
}

(:test)
function lazyFontLoadingTest(logger) {
    var dc = TestPlatform.dc(16,16);var v = new FastRiderView();v.loadFonts();
    for (var i = 0; i < v.fonts.size(); i += 1) { Test.assert(v.fonts[i] == null); }
    v.drawPrimary(dc);
    Test.assert(v.fonts[0] != null && v.fonts[1] != null && v.fonts[3] != null);
    Test.assert(v.fonts[8] == null && v.fonts[9] == null && v.fonts[10] == null);
    var cached = v.font(0);Test.assert(v.font(0) == cached);
    for (var i = 0; i < v.fonts.size(); i += 1) { v.font(i); }
    var loaded = 0;
    for (var i = 0; i < v.fonts.size(); i += 1) { if (v.fonts[i] != null) { loaded += 1; } }
    Test.assertEqual(loaded,v.fontCacheLimit);Test.assertEqual(v.fontOrder.size(),v.fontCacheLimit);
    v.drawPrimary(dc);Test.assert(v.fonts[0] != null && v.fonts[1] != null);
    return true;
}
