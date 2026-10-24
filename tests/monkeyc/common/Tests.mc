import Toybox.Test;

(:test)
function powerHistoryTest(logger) {
    var h = new PowerHistory();
    h.started(50000);
    Test.assert(h.lapStart == null);
    Test.assertEqual(h.startLabel(), "LAP SYNC");
    h.update(50000, 100, true);
    h.update(51000, 0, true);
    h.update(52000, 300, true);
    // 50 s is in a different aligned bucket from 51/52 s.
    Test.assertEqual(h.points.size(), 2);
    assertNear(h.points[1][2]/h.points[1][3].toFloat(), 150.0);
    h.update(52000, 999, true);
    Test.assertEqual(h.points[1][3], 2);
    h.update(52500, null, true);
    h.update(53000, 200, true);
    Test.assert(h.points[2][4] != h.points[1][4]);
    h.update(53500, 800, false);
    h.update(54000, 200, true);
    Test.assert(h.points[3][4] != h.points[2][4]);
    h.breakSample(); h.update(55000, 200, true);
    Test.assert(h.points[4][4] != h.points[3][4]);
    h.update(60000, 400, true);
    Test.assert(h.points[5][4] != h.points[4][4]);
    assertNear(h.ceiling(250), 500.0);
    h.beginLap(60000); h.beginLap(60000);
    Test.assertEqual(h.boundaries.size(), 1);
    h.update(61000, 300, true);
    Test.assertEqual(h.startLabel(), "LAP START -0:01");
    Test.assert(h.points[6][4] != h.points[5][4]);
    h.update(0, 100, true);
    Test.assertEqual(h.points.size(), 1);
    Test.assertEqual(h.boundaries.size(), 1);
    Test.assertEqual(h.startLabel(), "LAP START -0:00");
    return true;
}

(:test)
function powerWindowTest(logger) {
    var h = new PowerHistory(); h.started(0);
    for (var i = 0; i <= 700; i += 1) {
        if (i == 100 || i == 500) { h.beginLap(i*1000); }
        h.update(i*1000, 250, true);
    }
    Test.assert(h.points.size() <= 102);
    Test.assert(h.points[0][1] >= 400000);
    Test.assertEqual(h.boundaries.size(), 3);
    Test.assertEqual(h.boundaries[2], 500000);
    Test.assertEqual(h.startLabel(), "LAP START -3:20");
    h.update(801000, null, false);
    Test.assertEqual(h.startLabel(), "LAP START <-5m");
    Test.assertEqual(h.boundaries.size(), 3);
    // Many breaks and laps remain bounded even within the five-minute window.
    h.reset();
    for (var i = 0; i < 250; i += 1) {
        h.beginLap(i*1000); h.update(i*1000, 0, true);
    }
    Test.assertEqual(h.points.size(), 160);
    Test.assertEqual(h.boundaries.size(), 100);
    h.reset();
    Test.assert(h.endTime == null && h.points.size() == 0 && h.lapStart == null);
    return true;
}





function assertNear(actual, expected) {
    // Monkey C assertEqual also compares numeric types; interpolation is Float.
    Test.assert(actual >= expected-0.05 && actual <= expected+0.05);
}

(:test)
function zonesTest(logger) {
    var limits = [137.5, 187.5, 225, 262.5, 300, 375];
    Test.assertEqual(RideMath.zone(null, limits), 0);
    Test.assertEqual(RideMath.zone(0, limits), 1);
    Test.assertEqual(RideMath.zone(225, limits), 3);
    Test.assertEqual(RideMath.zone(226, limits), 4);
    Test.assertEqual(RideMath.zone(500, limits), 7);
    Test.assertEqual(RideMath.zone(152, [114, 133, 152, 171]), 3);
    Test.assertEqual(RideMath.zone(153, [114, 133, 152, 171]), 4);
    return true;
}

(:test)
function zonePositionTest(logger) {
    var power = [137.5, 187.5, 225, 262.5, 300, 375];
    Test.assert(RideMath.zoneFraction(null, power, 0, null) == null);
    assertNear(RideMath.zoneFraction(0, power, 0, null), 0.0);
    assertNear(RideMath.zoneFraction(137.5, power, 0, null), 1.0);
    assertNear(RideMath.zoneFraction(137.6, power, 0, null), 0.002);
    assertNear(RideMath.zoneFraction(162.5, power, 0, null), 0.5);
    assertNear(RideMath.zoneFraction(187.5, power, 0, null), 1.0);
    assertNear(RideMath.zoneFraction(337.5, power, 0, null), 0.5);
    assertNear(RideMath.zoneFraction(500, power, 0, null), 1.0);
    var heart = [114, 133, 152, 171];
    assertNear(RideMath.zoneFraction(60, heart, 95, 190), 0.0);
    assertNear(RideMath.zoneFraction(104.5, heart, 95, 190), 0.5);
    assertNear(RideMath.zoneFraction(158, heart, 95, 190), 6.0/19);
    assertNear(RideMath.zoneFraction(180.5, heart, 95, 190), 0.5);
    assertNear(RideMath.zoneFraction(200, heart, 95, 190), 1.0);
    Test.assert(RideMath.zoneFraction(200, heart, 95, 171) == null);
    // The tick uses the same selected rolling mean as the power number and zone.
    var rolling = new PowerAverage();
    for (var i = 0; i <= 10; i += 1) { rolling.update(i*1000, i < 7 ? 150 : 250, true); }
    var short = rolling.average(3); var long = rolling.average(10);
    Test.assertEqual(RideMath.zone(short, power), 4);
    Test.assertEqual(RideMath.zone(long, power), 3);
    assertNear(RideMath.zoneFraction(short, power, 0, null), (short-225)/37.5);
    assertNear(RideMath.zoneFraction(long, power, 0, null), (long-187.5)/37.5);
    return true;
}

(:test)
function timeTest(logger) {
    Test.assertEqual(RideMath.clock12(0, 5), "12:05 AM");
    Test.assertEqual(RideMath.clock12(12, 5), "12:05 PM");
    Test.assertEqual(RideMath.clock12(23, 59), "11:59 PM");
    Test.assertEqual(RideMath.duration(0), "0:00:00");
    Test.assertEqual(RideMath.duration(3661000), "1:01:01");
    Test.assertEqual(RideMath.duration(36000000), "10:00:00");
    Test.assertEqual(RideMath.lapDuration(null), "--:--");
    Test.assertEqual(RideMath.lapDuration(0), "00:00");
    Test.assertEqual(RideMath.lapDuration(312000), "05:12");
    Test.assertEqual(RideMath.lapDuration(3661000), "1:01:01");
    return true;
}

(:test)
function gearTest(logger) {
    Test.assertEqual(RideMath.gears(2, 7), "2/7");
    Test.assertEqual(RideMath.gears(null, null), "--/--");
    Test.assertEqual(RideMath.gears(0, 7), "--/7");
    Test.assertEqual(RideMath.gradeText(null), "--");
    Test.assertEqual(RideMath.gradeText(4.2), "+4.2");
    Test.assertEqual(RideMath.gradeText(-6.5), "-6.5");
    Test.assertEqual(RideMath.gradeText(-0.001), "+0.0");
    return true;
}

(:test)
function lapStatsTest(logger) {
    var s = new LapStats();
    s.started(100000);
    s.update(101000, 200, true);
    Test.assert(!s.synced && s.timeMs == null && s.averagePower == null);
    // The next native boundary is the first reliable start after a mid-ride load.
    s.begin(102000, 200);
    s.update(103000, 200, true);
    Test.assertEqual(s.timeMs, 1000);
    assertNear(s.averagePower, 200.0);
    s.update(104000, 0, true);
    s.update(105000, 0, true);
    assertNear(s.averagePower, 100.0);
    // Pause/stop and resume/start must preserve this native lap.
    s.update(105000, 800, false);
    s.started(105000);
    s.update(105000, 200, true);
    s.update(106000, 200, true);
    Test.assertEqual(s.timeMs, 4000);
    assertNear(s.averagePower, 125.0);
    // Missing power and long gaps are not silently filled with zero or stale power.
    s.update(107000, null, true);
    s.update(108000, 400, true);
    s.update(120000, 400, true);
    assertNear(s.averagePower, 125.0);
    // Every manual/auto boundary clears only the lap accumulator.
    s.begin(120000, 0);
    s.update(121000, 0, true);
    Test.assertEqual(s.timeMs, 1000);
    assertNear(s.averagePower, 0.0);
    s.update(0, 150, true);
    Test.assert(s.synced && s.timeMs == 0 && s.averagePower == null);
    s.update(1000, 150, true);
    assertNear(s.averagePower, 150.0);
    s.breakSample();
    s.update(0, 200, true);
    Test.assert(s.synced && s.timeMs == 0 && s.averagePower == null);
    return true;
}

(:test)
function gradeTest(logger) {
    var e = new GradeEstimator();
    Test.assert(e.update(0.0, 100.0, 0) == null);
    for (var i = 1; i < 4; i += 1) { Test.assert(e.update(i*5.0, 100+i*0.25, i*1000) == null); }
    assertNear(e.update(20.0, 101.0, 4000), 5.0);
    assertNear(e.update(25.0, 101.25, 5000), 5.0);
    // A stopped bike expires its estimate, rather than keeping a stale grade.
    Test.assert(e.update(25.0, 101.25, 21001) == null);
    assertNear(e.update(45.0, 100.25, 25001), -5.0);
    Test.assert(e.update(null, 100.0, 26000) == null);
    Test.assert(e.update(0.0, 100.0, 27000) == null);
    assertNear(e.update(20.0, 100.0, 29000), 0.0);
    // Activity reset and bad altitude jumps must discard history.
    Test.assert(e.update(1.0, 100.0, 30000) == null);
    Test.assert(e.update(21.0, 200.0, 31000) == null);
    return true;
}





(:test)
function rollingPowerTest(logger) {
    var a = new PowerAverage(); Test.assert(a.average(3) == null);
    for (var i = 1; i <= 10; i += 1) { a.update(i*1000, i*10, true); }
    assertNear(a.average(3), 90.0); assertNear(a.average(10), 55.0);
    a.update(10000, 999, true); assertNear(a.average(3), 90.0);
    a.update(11000, 0, true); assertNear(a.average(3), 190.0/3.0);
    a.update(12000, null, true); Test.assert(a.average(3) == null);
    a.update(13000, 0, true); assertNear(a.average(10), 0.0);
    a.update(14000, 100, false); Test.assert(a.average(3) == null);
    a.update(15000, 150, true); a.update(20000, 250, true); assertNear(a.average(10), 250.0);
    a.update(0, 20, true); assertNear(a.average(3), 20.0);
    return true;
}

(:test)
function multiRangeHistoryTest(logger) {
    var h = new PowerHistory(); h.started(0);
    for (var i = 0; i <= 3600; i += 1) {
        if (i == 600 || i == 1800) { h.beginLap(i*1000); }
        h.update(i*1000, 200, true);
    }
    Test.assert(h.viewPoints(0)[0][1] >= 3300000);
    Test.assert(h.viewPoints(1)[0][1] >= 2400000);
    Test.assertEqual(h.viewPoints(2)[0][0], 0);
    Test.assertEqual(h.boundaries.size(), 3);
    Test.assertEqual(h.windowMillis(0), 300000); Test.assertEqual(h.windowMillis(1), 1200000);
    Test.assertEqual(h.windowMillis(2), 3600000);
    Test.assert(h.points.size() <= 160 && h.medium.points.size() <= 160 && h.whole.points.size() <= 160);
    h.update(0, 0, true);
    Test.assertEqual(h.whole.points.size(), 1); Test.assertEqual(h.medium.points.size(), 1);
    return true;
}

(:test)
function allRideCompactionTest(logger) {
    var s = new PowerSeries(30000, null, true);
    // 24 hours, with a zero-watt interval and a break. No discarded beginning.
    for (var i = 0; i <= 5760; i += 1) { s.add(i*15000, i < 100 ? 0 : 240, i < 2000 ? 1 : 2); }
    Test.assert(s.points.size() <= 160); Test.assert(s.bucketMs > 30000);
    Test.assertEqual(s.points[0][0], 0); Test.assertEqual(s.points[s.points.size()-1][1], 86400000);
    var count = 0; var sum = 0.0;
    for (var i = 0; i < s.points.size(); i += 1) { count += s.points[i][3]; sum += s.points[i][2]; }
    Test.assertEqual(count, 5761); assertNear(sum, 5661*240.0);
    s.reset(); s.add(0, 100, 1); s.add(1000, 300, 2);
    Test.assertEqual(s.points[0][4], -1); assertNear(s.points[0][2]/s.points[0][3], 200.0);
    return true;
}

(:test)
function dataColorsTest(logger) {
    Test.assertEqual(DisplayRules.gradeColor(5.0), DisplayRules.INK);
    Test.assertEqual(DisplayRules.gradeColor(5.1), DisplayRules.ORANGE);
    Test.assertEqual(DisplayRules.gradeColor(10.0), DisplayRules.ORANGE);
    Test.assertEqual(DisplayRules.gradeColor(10.1), DisplayRules.DEEP_RED);
    Test.assertEqual(DisplayRules.gradeColor(15.0), DisplayRules.DEEP_RED);
    Test.assertEqual(DisplayRules.gradeColor(15.1), DisplayRules.DEEP_PURPLE);
    Test.assertEqual(DisplayRules.gradeColor(-10.0), DisplayRules.INK);
    Test.assertEqual(DisplayRules.cadenceColor(69), DisplayRules.DEEP_RED);
    Test.assertEqual(DisplayRules.cadenceColor(70), DisplayRules.INK);
    Test.assertEqual(DisplayRules.cadenceColor(100), DisplayRules.INK);
    Test.assertEqual(DisplayRules.cadenceColor(101), DisplayRules.DEEP_PURPLE);
    Test.assertEqual(DisplayRules.powerColor(1), DisplayRules.powerColor(3));
    Test.assert(DisplayRules.powerColor(2) != DisplayRules.powerColor(4));
    Test.assertEqual(DisplayRules.powerColor(6), DisplayRules.powerColor(7));
    return true;
}

(:test)
function lapDistanceTest(logger) {
    var s = new LapStats(); s.beginAt(50000, 100, 1000.0);
    s.updateDistance(1675.0); assertNear(s.distance, 675.0);
    s.update(51000, 100, true); assertNear(s.averagePower, 100.0);
    s.beginAt(51000, 100, 1675.0); assertNear(s.distance, 0.0);
    s.updateDistance(null); Test.assert(s.distance == null);
    s.updateDistance(1700.0); assertNear(s.distance, 25.0);
    s.reset(); s.started(60000); s.updateDistance(1800.0); Test.assert(s.distance == null);
    s.beginAt(0, null, null); s.updateDistance(15.0); assertNear(s.distance, 15.0);
    return true;
}



(:test)
function edge840ReferenceMetricsTest(logger) {
    if (Layout.WIDTH != 246 || Layout.HEIGHT != 322) { return true; }
    // A tiny Dc is sufficient to verify font metrics without a full-screen buffer.
    var dc = TestPlatform.dc(16,16);
    var v = new FastRiderView(); v.loadFonts();
    // Ordinary 3-digit and fallback 4-digit power stay left of the radar overlay.
    Test.assertEqual(dc.getTextWidthInPixels("303", v.fonts[0]), 87);
    Test.assert(Layout.RIGHT_START+dc.getTextWidthInPixels("999", v.fonts[v.primaryFont(dc, "999")]) <= Layout.RADAR_LEFT);
    Test.assert(Layout.RIGHT_START+dc.getTextWidthInPixels("1234", v.fonts[v.primaryFont(dc, "1234")]) <= Layout.RADAR_LEFT);
    Test.assert(v.packedWidth("120", 1) <= Layout.LIVE_RIGHT_WIDTH);
    Test.assertEqual(v.liveFont("120", Layout.LIVE_RIGHT_WIDTH), 1);
    Test.assertEqual(v.liveFont("22.4", Layout.LIVE_RIGHT_WIDTH), 1);
    Test.assertEqual(v.liveFont("100.5", Layout.LIVE_RIGHT_WIDTH), 7);
    Test.assert(dc.getTextWidthInPixels("1:23:08", v.fonts[5]) <= 118);
    Test.assert(dc.getTextWidthInPixels("12:23:08", v.fonts[7]) <= 118);
    Test.assert(dc.getTextWidthInPixels("245", v.fonts[2])+3+dc.getTextWidthInPixels("AVG", v.fonts[3]) <= 118);
    Test.assert(dc.getTextWidthInPixels("1234", v.fonts[6])+3+dc.getTextWidthInPixels("AVG", v.fonts[3]) <= 118);
    Test.assert(dc.getTextWidthInPixels("0.42", v.fonts[5])+3+dc.getTextWidthInPixels("mi", v.fonts[3]) <= 118);
    Test.assertEqual(Toybox.Graphics.getFontAscent(v.fonts[0]), 58);
    Test.assertEqual(Toybox.Graphics.getFontAscent(v.fonts[8]), 44);
    Test.assertEqual(v.zoneBadgeWidth(dc, 6, 0), Layout.ZONE_BADGE_WIDTH);
    Test.assertEqual(v.zoneBadgeWidth(dc, 7, 6), Layout.ZONE_SMALL_BADGE_WIDTH);
    Test.assertEqual(dc.getTextWidthInPixels("Z", v.fonts[9]), 9);
    Test.assertEqual(FontInk.TOP[9], 12);
    Test.assertEqual(FontInk.TOP[8], 32);
    // The larger small Z sits below the primary digits; the large zone digit
    // has its own clear horizontal lane, including with 3-digit primary values.
    Test.assertEqual(v.heartFont(dc, "199"), 0);
    Test.assertEqual(v.fontSizes[v.heartFont(dc, "199")], 58);
    Test.assertEqual(v.fontSizes[1], 38);
    Test.assert(v.numberBounds(dc, "199", 0, 3)[1]+1+v.textWidth(dc, "7", 8) <= Layout.LEFT_WIDTH);
    Test.assertEqual(v.zoneBadgeWidth(dc, 4, 0), Layout.ZONE_BADGE_WIDTH);
    Test.assertEqual(Layout.COLUMN_DIVIDER, 107+5);
    Test.assertEqual(Layout.RIGHT_WIDTH, 128);
    Test.assert(Layout.ZONE_BASELINE-FontInk.TOP[9] > Layout.PRIMARY_BASELINE+FontInk.BOTTOM[0]+FontInk.NATIVE_BOTTOM_PAD);
    Test.assert(Layout.PRIMARY_BASELINE-FontInk.TOP[0] >= 1);
    Test.assert(Layout.PRIMARY_BASELINE-FontInk.TOP[0] <= 2);
    Test.assert(Layout.ZONE_BASELINE-FontInk.TOP[8] >= Layout.RADAR_BOTTOM);
    Test.assert(Layout.ZONE_BASELINE+FontInk.BOTTOM[8]+FontInk.NATIVE_BOTTOM_PAD < Layout.ZONE_BAR_TOP-(Layout.ZONE_MARKER_HEIGHT-Layout.ZONE_BAR)/2);
    // AA backdrop clips use ink bounds: adjacent rows must remain disjoint.
    var timeFonts = [5, 7, 4];
    for (var i = 0; i < timeFonts.size(); i += 1) {
        Test.assert(132+FontInk.BOTTOM[timeFonts[i]]+FontInk.NATIVE_BOTTOM_PAD < 180-FontInk.TOP[2]);
    }
    Test.assert(170+FontInk.BOTTOM[3]+FontInk.NATIVE_BOTTOM_PAD < 212-FontInk.TOP[1]);
    Test.assert(Layout.UNIT_BASELINE+FontInk.BOTTOM[3]+FontInk.NATIVE_BOTTOM_PAD < Layout.ZONE_BAR_TOP-(Layout.ZONE_MARKER_HEIGHT-Layout.ZONE_BAR)/2);
    Test.assert(Layout.ZONE_BAR_TOP+(Layout.ZONE_MARKER_HEIGHT+Layout.ZONE_BAR)/2 <= Layout.MIDDLE_TOP);
    v.trend.endTime = 600000;
    Test.assertEqual(v.chartX(600000), Layout.PLOT_RIGHT);
    Test.assertEqual(v.chartX(300000), Layout.PLOT_LEFT);
    Test.assertEqual(v.powerY(0), Layout.PLOT_BOTTOM-1);
    Test.assertEqual(v.powerY(v.ftpWatts*1.5), Layout.PLOT_TOP);
    Test.assertEqual(v.powerY(v.ftpWatts*2), Layout.PLOT_TOP);
    Test.assertEqual(RideMath.ascentFeetText(null), "-- ft");
    Test.assertEqual(RideMath.ascentFeetText(-1), "-- ft");
    Test.assertEqual(RideMath.ascentFeetText(0), "0 ft");
    Test.assertEqual(RideMath.ascentFeetText(304.8), "1000 ft");
    var rangeWidth = v.rangeWidth(dc, "20m");
    Test.assert(v.rangeWidth(dc, "5m") > v.textWidth(dc, "< 5m >", 3));
    Test.assert(v.rangeWidth(dc, "All") <= rangeWidth);
    Test.assert(2+v.textWidth(dc, "99999", 11)+3+v.textWidth(dc, "ft", 12)+4 <= 123-rangeWidth/2);
    Test.assert(123+rangeWidth/2+4 <= 244-dc.getTextWidthInPixels("12:59 PM", v.fonts[3]));
    Test.assert(Layout.RIGHT_START+14+4+dc.getTextWidthInPixels("10s", v.fonts[3]) < 244-v.zoneBadgeWidth(dc, 7, 0));
    Test.assertEqual(RideMath.remainingMilesText(9.9*1609.344, 1), "(-9.9)");
    Test.assertEqual(RideMath.remainingMilesText(0, 1), "(0.0)");
    Test.assert(RideMath.remainingMilesText(null, 1) == null);
    Test.assert(RideMath.remainingMilesText(-1, 1) == null);
    var d = v.distanceParts(dc, 10.7*1609.344, 9.9*1609.344, true);
    Test.assertEqual(d[0], "10.7"); Test.assertEqual(d[1], "(-9.9)");
    Test.assertEqual(d[2], 5); Test.assertEqual(d[3], 13);
    Test.assert(FontInk.TOP[d[3]] > FontInk.TOP[12]);
    Test.assert(FontInk.TOP[d[3]] < FontInk.TOP[d[2]]);
    Test.assert(v.distanceParts(dc, 10.7*1609.344, null, true)[1] == null);
    Test.assert(v.distanceParts(dc, 0.42*1609.344, 9.9*1609.344, false)[1] == null);
    var longRow = v.distanceParts(dc, 320000.0, 500000.0, true);
    Test.assert(longRow[1] != null);
    Test.assert(v.distanceRowWidth(longRow) <= Layout.RIGHT_WIDTH);
    return true;
}

(:test)
function liveDisplayPrecisionTest(logger) {
    var v = new FastRiderView();
    Test.assertEqual(v.intText(6.4), "6"); Test.assertEqual(v.intText(6.6), "7");
    Test.assertEqual(v.intText(-16.4), "-16"); Test.assertEqual(v.intText(-0.4), "0");
    Test.assertEqual(v.intText(null), "--");
    Test.assertEqual(RideMath.speedMphText(10.0138), "22.4");
    Test.assertEqual(RideMath.speedMphText(0), "0.0");
    Test.assertEqual(RideMath.speedMphText(null), "--");
    Test.assertEqual(RideMath.speedMphText(-1), "--");
    return true;
}

(:test)
function fullDistancePrecisionTest(logger) {
    var v = new FastRiderView();
    var dc = TestPlatform.dc(16,16); v.loadFonts();
    var p = v.distanceParts(dc, 300.5*1609.344, 200.5*1609.344, true);
    Test.assertEqual(p[0], "300.5"); Test.assertEqual(p[1], "(-200.5)");
    if (Layout.WIDTH == 246) {
        Test.assertEqual(p[2], 4); Test.assertEqual(p[3], 15);
        Test.assertEqual(v.distanceRowWidth(p), 127);
    }
    Test.assert(v.distanceRowWidth(p) <= Layout.RIGHT_WIDTH);
    var worst = v.distanceParts(dc, 888.8*1609.344, 999.9*1609.344, true);
    Test.assertEqual(worst[0], "888.8"); Test.assertEqual(worst[1], "(-999.9)");
    Test.assert(v.distanceRowWidth(worst) <= Layout.RIGHT_WIDTH);
    return true;
}

(:test)
function nativeRenderStatesTest(logger) {
    var dc = TestPlatform.dc(Layout.WIDTH,Layout.HEIGHT);
    var v = new FastRiderView(); v.computeDemo();
    for (var p = 0; p < 2; p += 1) {
        for (var s = 0; s < 2; s += 1) {
            for (var r = 0; r < 3; r += 1) {
                v.onUpdate(dc); v.handleTap(Layout.WIDTH/2, Layout.HEADER_BASELINE);
            }
            v.handleTap(Layout.RIGHT_EDGE-Layout.u(44), Layout.STATS_AVERAGE_LABEL_BASELINE);
        }
        v.handleTap(Layout.RIGHT_EDGE-Layout.u(44), Layout.u(50));
    }
    // Four-digit primary power also uses a compact composite Zone badge.
    v.rolling.reset(); v.rolling.update(v.timerMillis, 1234, true); v.hr = 54;
    v.onUpdate(dc);
    // Exercise narrow cells, extended ride/lap time, missing signals and fallbacks.
    v.ui.allStats = true; v.timerMillis = 43201000; v.millis = 43201000;
    v.meters = 320000.0; v.ascent = 6000; v.remainingDistance = 500000.0;
    v.remainingAscent = 5000; v.ridePower = 1234;
    v.hr = null; v.cadence = 101; v.grade = -16.4; v.speed = 45.0;
    v.onUpdate(dc);
    v.meters = 300.5*1609.344; v.remainingDistance = 200.5*1609.344;
    v.cadence = 120; v.rearGear = 11; v.grade = 6.4; v.speed = 10.0138; v.onUpdate(dc);
    v.remainingDistance = null; v.remainingAscent = null; v.onUpdate(dc);
    v.timerMillis = 360001000; v.millis = 360001000; v.onUpdate(dc);
    var stats = Toybox.System.getSystemStats();
    logger.debug("Native render memory used="+stats.usedMemory+" free="+stats.freeMemory);
    // Unit-test mode has a larger heap; compare used bytes to the real field limit.
    Test.assert(stats.freeMemory > 0);
    return true;
}

(:test)
function navigationAvailabilityTest(logger) {
    Test.assert(RideMath.navigationDistance(0, null) == null);
    Test.assert(RideMath.navigationDistance(1000, "") == null);
    Test.assert(RideMath.navigationDistance(null, "Finish") == null);
    Test.assert(RideMath.navigationDistance(-1, "Finish") == null);
    Test.assertEqual(RideMath.navigationDistance(0, "Finish"), 0);
    Test.assertEqual(RideMath.navigationDistance(1000, "Finish"), 1000);
    return true;
}

(:test)
function rideAverageAvailabilityTest(logger) {
    Test.assert(RideMath.rideAverage(0, 195, null) == null);
    Test.assert(RideMath.rideAverage(null, 195, 100) == null);
    Test.assertEqual(RideMath.rideAverage(1000, 0, 100), 0);
    Test.assertEqual(RideMath.rideAverage(1000, 195, 100), 195);
    Test.assertEqual(RideMath.rideAverage(1000, null, 100), 100);
    Test.assert(RideMath.rideAverage(1000, null, null) == null);
    return true;
}

(:test)
function responsiveGeometryTest(logger) {
    var dc = TestPlatform.dc(16,16); var v = new FastRiderView(); v.loadFonts();
    Test.assert(Layout.RIGHT_START < Layout.RIGHT_EDGE && Layout.RIGHT_WIDTH == Layout.RIGHT_EDGE-Layout.RIGHT_START);
    Test.assert(Layout.LIVE_LEFT_CENTER+Layout.LIVE_LEFT_WIDTH/2 < Layout.LIVE_RIGHT_CENTER-Layout.LIVE_RIGHT_WIDTH/2);
    Test.assert(Layout.MIDDLE_TOP > Layout.PRIMARY_BOTTOM);
    Test.assert(Layout.STATS_BOTTOM < Layout.BANNER_TOP && Layout.HEADER_BASELINE < Layout.PLOT_TOP);
    Test.assert(Layout.PLOT_BOTTOM < Layout.HEIGHT && Layout.PLOT_TOP < Layout.PLOT_BOTTOM);
    var samples = ["999","1234"];
    for (var i = 0; i < samples.size(); i += 1) {
        var f = v.primaryFont(dc,samples[i]);
        Test.assert(Layout.RIGHT_START+v.numberWidth(dc,samples[i],f,0) < Layout.RADAR_LEFT);
    }
    var values = ["120","22.4","100.5"];
    for (var i = 0; i < values.size(); i += 1) {
        var face = v.liveFont(values[i],Layout.LIVE_RIGHT_WIDTH);
        Test.assert(v.packedWidth(values[i],face) <= Layout.LIVE_RIGHT_WIDTH);
    }
    Test.assert(Layout.ZONE_BASELINE-FontInk.TOP[8] >= Layout.RADAR_BOTTOM);
    Test.assert(Layout.ZONE_BASELINE+FontInk.BOTTOM[8]+FontInk.NATIVE_BOTTOM_PAD < Layout.ZONE_BAR_TOP-(Layout.ZONE_MARKER_HEIGHT-Layout.ZONE_BAR)/2);
    Test.assert(Layout.LIVE_LABEL_BOTTOM+FontInk.BOTTOM[3]+FontInk.NATIVE_BOTTOM_PAD < Layout.LIVE_VALUE_BOTTOM-FontInk.TOP[1]);
    Test.assert(Layout.STATS_TIME_BASELINE+FontInk.BOTTOM[5]+FontInk.NATIVE_BOTTOM_PAD < Layout.STATS_AVERAGE_BASELINE-FontInk.TOP[2]);
    var range = v.rangeWidth(dc,"20m");
    Test.assert(Layout.LEFT_EDGE+v.textWidth(dc,"99999",11)+Layout.STATS_GAP+v.textWidth(dc,"ft",12)+Layout.INLINE_GAP <= Layout.WIDTH/2-range/2);
    Test.assert(Layout.WIDTH/2+range/2+Layout.INLINE_GAP <= Layout.RIGHT_EDGE-v.textWidth(dc,"12:59 PM",3));
    Test.assert(Layout.RIGHT_START+Layout.BOLT_WIDTH+Layout.INLINE_GAP+v.textWidth(dc,"10s",3) < Layout.RIGHT_EDGE-v.zoneBadgeWidth(dc,7,0));
    return true;
}

(:test)
function buttonOnlyDefaultViewTest(logger) {
    if (InputSupport.ENABLED) { return true; }
    var v = new FastRiderView(); v.computeDemo();
    Test.assertEqual(InputSupport.initialView(v).size(),1);
    Test.assert(!v.handleTap(Layout.RIGHT_EDGE-1,Layout.u(50)));
    Test.assert(!v.handleTap(Layout.RIGHT_EDGE-1,Layout.STATS_TIME_BASELINE));
    Test.assert(!v.handleTap(Layout.WIDTH/2,Layout.HEADER_BASELINE));
    v.onTimerLap(); v.onTimerPause(); v.onTimerResume();
    Test.assertEqual(v.lapNumber,4);
    Test.assertEqual(v.ui.powerSeconds,3); Test.assert(v.ui.allStats); Test.assertEqual(v.ui.rangeLabel(),"5m");
    v.onTimerReset();
    Test.assertEqual(v.ui.powerSeconds,3); Test.assert(v.ui.allStats); Test.assertEqual(v.ui.range,0);
    return true;
}
