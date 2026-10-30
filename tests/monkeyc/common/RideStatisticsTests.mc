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
    var powers = ["77","100","303","444","888","999","1000","1234","4444","8888","9999","65535"];
    for (var i = 0; i < powers.size(); i += 1) {
        var f = v.primaryFont(dc,powers[i]);
        var w = f == 0 ? v.numberWidth(dc,powers[i],f,0) : v.packedWidth(powers[i],f);
        Test.assert(w <= v.powerValueWidth());
        Test.assert(Layout.RIGHT_START+w+Layout.POWER_ZONE_GAP <= v.powerBadgeRight()-Layout.ZONE_BADGE_WIDTH);
        if (powers[i].length() == 3) { Test.assertEqual(f,0); }
        if (powers[i].length() == 4) { Test.assert(FontInk.TOP[f] < FontInk.TOP[0]); }
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

(:test)
function stackedRideDistanceTest(logger) {
    var v = new FastRiderView();v.loadFonts();var dc = TestPlatform.dc(Layout.WIDTH,Layout.HEIGHT);
    var cases = [[10.4,12.4,true],[300.5,200.5,true],[888.8,999.9,true],[10.4,null,true],[0.42,12.4,false],[null,null,true]];
    for (var i = 0; i < cases.size(); i += 1) {
        var c = cases[i] as Toybox.Lang.Array;
        var meters = c[0] == null ? null : c[0]*1609.344;
        var remaining = c[1] == null ? null : c[1]*1609.344;
        var p = RideDistance.parts(v,meters,remaining,c[2]);var pos = RideDistance.positions(v,p);
        Test.assert(p[4] <= Layout.RIGHT_WIDTH && p[5] <= RideDistance.maxHeight());
        Test.assert(pos[0] >= Layout.RIGHT_START && pos[0]+p[4] <= Layout.RIGHT_EDGE);
        Test.assertEqual(pos[2],pos[0]+v.packedWidth(p[0],p[2])+Layout.STATS_GAP);
        Test.assertEqual(pos[3]-FontInk.TOP[12],pos[5]);
        Test.assert(pos[1]-FontInk.TOP[p[2]] >= pos[5]);
        Test.assert(pos[1]+FontInk.BOTTOM[p[2]]+FontInk.NATIVE_BOTTOM_PAD <= pos[6]);
        Test.assert(pos[6] <= Layout.STATS_BOTTOM);
        if (i < 3) {
            Test.assertEqual(p[0],c[0].format("%.1f"));
            Test.assertEqual(p[1],RideMath.remainingMilesText(remaining,1));
            Test.assert(pos[3]+FontInk.BOTTOM[12]+FontInk.NATIVE_BOTTOM_PAD+Layout.DISTANCE_STACK_GAP <= pos[4]-FontInk.TOP[p[3]]);
            Test.assert(FontInk.TOP[p[2]] > FontInk.TOP[p[3]]);
        } else { Test.assert(p[1] == null); }
        if (i == 0 && Layout.WIDTH == 246) { Test.assert(FontInk.TOP[p[2]] > 34); }
        if (i == 4) { Test.assertEqual(p[0],"0.42"); }
        for (var mode = 0; mode < 2; mode += 1) {
            v.theme.setBackground(mode == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
            dc.setColor(v.theme.ink,v.theme.background);dc.clear();
            RideDistance.draw(v,dc,meters,remaining,c[2]);
        }
    }
    return true;
}
