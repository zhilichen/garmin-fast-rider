import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.UserProfile;
import Toybox.WatchUi;

class FastRiderView extends WatchUi.DataField {
    var power = null;
    var hr = null;
    var cadence = null;
    var rearGear = null;
    var speed = null;
    var meters = null;
    var millis = null;
    var timerMillis = null;
    var ascent = null;
    var remainingDistance = null;
    var remainingAscent = null;
    var ridePower = null;
    var lapNumber = null;
    var lap as LapStats;
    var ride as LapStats;
    var grade = null;
    var gradeEstimator;
    var rolling as PowerAverage;
    var ui as InteractionState;
    var powerLimits;
    var hrLimits;
    var hrMinimum = 0;
    var hrMaximum = 190;
    var trend as PowerHistory;
    var ftpWatts = 250;
    var demoSeeded = false;
    var demoDiagnostics = false;
    var start;
    var width = Layout.WIDTH;
    var height = Layout.HEIGHT;
    var fonts as Lang.Array<Graphics.FontType> or Null = null;
    var fontSizes as Lang.Array<Lang.Number> = FontInk.SIZES;
    var flashRegion = 0;
    var flashUntil = 0;
    var sensorMask = -1;

    function initialize() {
        DataField.initialize();
        gradeEstimator = new GradeEstimator();
        lap = new LapStats(); ride = new LapStats();
        rolling = new PowerAverage(); ui = new InteractionState();
        trend = new PowerHistory();
        start = System.getTimer();
        loadSettings();
        hardwareLog("boot: live Activity.Info, defaults=3s/All/5m");
    }
    function hardwareLog(message) {
        if (BuildMode.DIAGNOSTICS) { System.println("FastRider "+message); }
    }
    function loadSettings() {
        var ftp = RideMath.clamp(Application.Properties.getValue("ftp"), 50, 600);
        var maxHr = RideMath.clamp(Application.Properties.getValue("maxHr"), 100, 240);
        hrLimits = [maxHr*0.60, maxHr*0.70, maxHr*0.80, maxHr*0.90];
        hrMinimum = 0; hrMaximum = maxHr;
        if (!BuildMode.DEMO) {
            var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
            if (zones != null && zones.size() == 6 && zones[1] > 0) {
                hrLimits = [zones[1], zones[2], zones[3], zones[4]];
                if (zones[0] >= 0 && zones[0] < zones[1]) { hrMinimum = zones[0]; }
                if (zones[5] > zones[4]) { hrMaximum = zones[5]; }
            }
            if (UserProfile has :getFunctionalThresholdPower) {
                var deviceFtp = UserProfile.getFunctionalThresholdPower(Activity.SPORT_CYCLING);
                if (deviceFtp != null && deviceFtp > 0) { ftp = deviceFtp; }
            }
        }
        ftpWatts = ftp;
        powerLimits = [ftp*0.55, ftp*0.75, ftp*0.90, ftp*1.05, ftp*1.20, ftp*1.50];
    }
    function compute(info) {
        if (BuildMode.DEMO) { computeDemo(); return; }
        if (timerMillis != null && info.timerTime != null && info.timerTime < timerMillis) { onTimerReset(); }
        var running = info.timerState == Activity.TIMER_STATE_ON;
        power = info.currentPower;
        hr = info.currentHeartRate; if (hr != null && hr <= 0) { hr = null; }
        cadence = info.currentCadence; if (cadence != null && cadence < 0) { cadence = null; }
        rearGear = info.rearDerailleurIndex;
        if (rearGear != null && rearGear <= 0) { rearGear = null; }
        speed = info.currentSpeed;
        if (speed != null && speed < 0) { speed = null; }
        meters = info.elapsedDistance; millis = info.elapsedTime; timerMillis = info.timerTime;
        if (timerMillis != null && timerMillis == 0 && !lap.synced) {
            lap.beginAt(0, power, meters); ride.beginAt(0, power, meters); lapNumber = 1;
        }
        lap.update(timerMillis, power, running); lap.updateDistance(meters);
        ride.update(timerMillis, power, running);
        // Prefer Garmin's complete-ride statistic, including after a mid-ride load.
        ridePower = RideMath.rideAverage(timerMillis, info.averagePower, ride.averagePower);
        rolling.update(timerMillis, power, running);
        grade = gradeEstimator.update(meters, info.altitude, System.getTimer());
        ascent = info.totalAscent;
        // This is navigation-to-destination distance, not an inferred course ID.
        remainingDistance = RideMath.navigationDistance(info.distanceToDestination, info.nameOfDestination);
        // Public Activity.Info has no remaining-course-ascent value. Never infer it
        // from destination elevation or the GPX prototype.
        remainingAscent = null;
        trend.update(millis, power, running);
        if (BuildMode.DIAGNOSTICS) {
            // Availability only; do not log health readings or GPS coordinates.
            var mask = (power != null ? 1 : 0)|(hr != null ? 2 : 0)|(cadence != null ? 4 : 0)|(rearGear != null ? 8 : 0)|(speed != null ? 16 : 0);
            if (mask != sensorMask) { hardwareLog("sensor availability P=1 H=2 C=4 G=8 S=16 mask="+mask); sensorMask = mask; }
        }
    }
    function demoMeters(seconds) { return 16737.1776+(seconds-4988)*9.94; }
    function seedDemo() {
        trend.beginLap(0);
        for (var t = 0; t < 4688; t += 30) { trend.whole.add(t*1000, RideMath.demoPower(t), 1); }
        for (var t = 3788; t < 4688; t += 12) { trend.medium.add(t*1000, RideMath.demoPower(t), 1); }
        for (var t = 4688; t <= 4988; t += 1) {
            var watts = RideMath.demoPower(t);
            if (t == 4800 || t == 4920) { trend.beginLap(t*1000); }
            if (t == 4920) { lap.beginAt(t*1000, watts, demoMeters(t)); }
            trend.update(t*1000, watts, true);
            if (t >= 4920) { lap.update(t*1000, watts, true); }
            if (t >= 4978) { rolling.update(t*1000, watts, true); }
        }
        lapNumber = 3; demoSeeded = true;
    }
    function computeDemo() {
        if (!demoSeeded) { seedDemo(); }
        var t = (System.getTimer()-start)/1000.0;
        millis = 4988000+(t*1000).toNumber(); timerMillis = millis;
        power = RideMath.demoPower(millis/1000.0);
        hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;
        meters = demoMeters(millis/1000.0); ascent = 682.0+t/10.0; grade = 6.4;
        remainingDistance = 19955.8656; remainingAscent = 365.76;
        ridePower = 212;
        rolling.update(timerMillis, power, true);
        lap.update(timerMillis, power, true); lap.updateDistance(meters);
        trend.update(millis, power, true);
    }
    function onTimerReset() {
        hardwareLog("timer reset -> defaults=3s/All/5m");
        trend.reset(); rolling.reset(); lap.reset(); ride.reset(); ui.reset();
        gradeEstimator.reset(); grade = null; lapNumber = null;
        demoSeeded = false; demoDiagnostics = false; ascent = null; remainingDistance = null; remainingAscent = null;
        meters = null; millis = null; timerMillis = null; ridePower = null;
        power = null; hr = null; cadence = null; speed = null; rearGear = null;
        flashRegion = 0; start = System.getTimer();
        sensorMask = -1;
    }
    function onTimerStart() {
        hardwareLog("timer start");
        if (BuildMode.DEMO) { return; }
        var info = Activity.getActivityInfo();
        if (info.timerTime != null && info.timerTime == 0) {
            lap.beginAt(0, info.currentPower, info.elapsedDistance);
            ride.beginAt(0, info.currentPower, info.elapsedDistance); lapNumber = 1;
        } else { lap.started(info.timerTime); ride.started(info.timerTime); }
        trend.started(info.elapsedTime); rolling.reset();
    }
    function breakSamples() { lap.breakSample(); ride.breakSample(); trend.breakSample(); rolling.reset(); }
    function onTimerPause() { hardwareLog("timer pause"); breakSamples(); }
    function onTimerResume() { hardwareLog("timer resume"); breakSamples(); }
    function onTimerStop() { hardwareLog("timer stop"); breakSamples(); }
    function onTimerLap() {
        if (BuildMode.DEMO) {
            if (!demoSeeded) { computeDemo(); }
            lap.beginAt(timerMillis, power, meters); trend.beginLap(millis);
        } else {
            var info = Activity.getActivityInfo();
            lap.beginAt(info.timerTime, info.currentPower, info.elapsedDistance);
            trend.beginLap(info.elapsedTime);
        }
        if (lapNumber != null) { lapNumber += 1; }
        ui.beganLap();
        hardwareLog("native lap -> latest lap="+(lapNumber == null ? "?" : lapNumber.format("%d"))+", power="+ui.powerSeconds+"s, graph="+ui.rangeLabel());
        WatchUi.requestUpdate();
    }
    function onTimerLap2(trigger) { onTimerLap(); return true; }
    function handleTap(x, y) {
        if (width != Layout.WIDTH || height != Layout.HEIGHT || !ui.tap(x, y)) { return false; }
        flashRegion = y < Layout.PRIMARY_BOTTOM ? 1 : (y < Layout.STATS_BOTTOM ? 2 : 3);
        flashUntil = System.getTimer()+180;
        if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
            System.println("Tap ["+x+","+y+"] -> "+ui.powerSeconds+"s, "+(ui.allStats ? "All" : "LAP")+", "+ui.rangeLabel());
        }
        WatchUi.requestUpdate();
        return true;
    }
    function loadFonts() {
        if (fonts != null) { return; }
        fonts = [WatchUi.loadResource(Rez.Fonts.Primary58), WatchUi.loadResource(Rez.Fonts.Live38),
                 WatchUi.loadResource(Rez.Fonts.Average54), WatchUi.loadResource(Rez.Fonts.Meta18),
                 WatchUi.loadResource(Rez.Fonts.Chart26), WatchUi.loadResource(Rez.Fonts.Stats32),
                 WatchUi.loadResource(Rez.Fonts.Average36), WatchUi.loadResource(Rez.Fonts.Stats30),
                 WatchUi.loadResource(Rez.Fonts.ZoneDigit44), WatchUi.loadResource(Rez.Fonts.SmallZ16),
                 WatchUi.loadResource(Rez.Fonts.SmallZ10), WatchUi.loadResource(Rez.Fonts.Climb18),
                 WatchUi.loadResource(Rez.Fonts.Units18), WatchUi.loadResource(Rez.Fonts.Remaining24),
                 WatchUi.loadResource(Rez.Fonts.Remaining22), WatchUi.loadResource(Rez.Fonts.Remaining21)];
    }
    function color(dc, c) { dc.setColor(c, Graphics.COLOR_TRANSPARENT); }
    function text(dc, x, baseline, index, value, c, align) {
        // Native BMFont rasterization adds one row below the source ink bounds.
        // Keep it inside the white AA backdrop clip so rounded bottoms survive.
        dc.setColor(c, Graphics.COLOR_WHITE);
        var top = RideMath.clamp(baseline-FontInk.TOP[index], 0, height);
        var bottom = RideMath.clamp(baseline+FontInk.BOTTOM[index]+FontInk.NATIVE_BOTTOM_PAD, 0, height);
        if (bottom <= top) { return; }
        dc.setClip(0, top, width, bottom-top);
        dc.drawText(x, baseline-fontSizes[index], fonts[index], value, align);
        dc.clearClip();
    }
    function textWidth(dc, value, index) { return dc.getTextWidthInPixels(value, fonts[index]); }
    function intText(value) { return value == null ? "--" : Math.round(value).toNumber().format("%d"); }
    function primaryFont(dc, value) { return textWidth(dc, value, 0) <= Layout.RADAR_LEFT-Layout.RIGHT_START ? 0 : 6; }
    function digitIndex(ch) {
        if (ch.equals(".")) { return 10; } if (ch.equals("-")) { return 11; }
        if (ch.equals("(")) { return 12; } if (ch.equals(")")) { return 13; }
        if (ch.equals("m")) { return 14; } if (ch.equals("i")) { return 15; }
        return ch.toNumber();
    }
    function numberBounds(dc, value, index, tracking) as Lang.Array {
        var pen = 0; var left = 10000; var right = -10000;
        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i,i+1); var d = digitIndex(ch);
            var lo = pen+FontInk.NUMERIC_LEFT[index][d]; var hi = pen+FontInk.NUMERIC_RIGHT[index][d];
            if (lo < left) { left = lo; } if (hi > right) { right = hi; }
            pen += textWidth(dc, ch, index)-tracking;
        }
        return [left,right];
    }
    function numberWidth(dc, value, index, tracking) {
        var bounds = numberBounds(dc, value, index, tracking); return bounds[1]-bounds[0];
    }
    function drawDigits(dc, x, baseline, index, value, c, tracking, centered) {
        var bounds = numberBounds(dc, value, index, tracking);
        var origin = centered ? x-DisplayRules.pixel((bounds[0]+bounds[1])/2.0) : x;
        var top = baseline-FontInk.TOP[index]; var h = FontInk.TOP[index]+FontInk.BOTTOM[index]+FontInk.NATIVE_BOTTOM_PAD;
        var pen = 0;
        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i,i+1); var d = digitIndex(ch);
            var lo = origin+pen+FontInk.NUMERIC_LEFT[index][d];
            var hi = origin+pen+FontInk.NUMERIC_RIGHT[index][d];
            // Use the unchanged original glyph with its full advance. Restrict
            // the white AA backdrop so it cannot erase its closer neighbor.
            dc.setClip(lo, top, hi-lo, h); dc.setColor(c, Graphics.COLOR_WHITE);
            dc.drawText(origin+pen, baseline-fontSizes[index], fonts[index], ch, Graphics.TEXT_JUSTIFY_LEFT);
            dc.clearClip(); pen += textWidth(dc, ch, index)-tracking;
        }
    }
    function heartFont(dc, value) {
        var tracking = value.length() > 2 ? Layout.HEART_TRACKING : 0;
        var bounds = numberBounds(dc, value, 0, tracking);
        return bounds[1]+textWidth(dc, "7", 8)+Layout.PACKED_GAP <= Layout.LEFT_WIDTH ? 0 : 6;
    }
    function packedWidth(value, index) {
        var w = 0;
        for (var i = 0; i < value.length(); i += 1) {
            var d = digitIndex(value.substring(i,i+1));
            w += FontInk.NUMERIC_RIGHT[index][d]-FontInk.NUMERIC_LEFT[index][d];
        }
        return w+(value.length()-1)*Layout.PACKED_GAP;
    }
    function drawPacked(dc, x, baseline, index, value, c) {
        var top = baseline-FontInk.TOP[index]; var h = FontInk.TOP[index]+FontInk.BOTTOM[index]+FontInk.NATIVE_BOTTOM_PAD;
        var cursor = x;
        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i,i+1); var d = digitIndex(ch);
            var left = FontInk.NUMERIC_LEFT[index][d];
            var w = FontInk.NUMERIC_RIGHT[index][d]-left;
            dc.setClip(cursor, top, w, h); dc.setColor(c, Graphics.COLOR_WHITE);
            dc.drawText(cursor-left, baseline-fontSizes[index], fonts[index], ch, Graphics.TEXT_JUSTIFY_LEFT);
            dc.clearClip(); cursor += w+Layout.PACKED_GAP;
        }
    }
    function liveFont(value, available) {
        var faces = [1,5,7,4];
        for (var i = 0; i < faces.size(); i += 1) {
            if (packedWidth(value, faces[i]) <= available) { return faces[i]; }
        }
        return 4;
    }
    function drawLive(dc, center, baseline, value, available, c) {
        var face = liveFont(value, available);
        var x = center-DisplayRules.pixel(packedWidth(value, face)/2.0);
        drawPacked(dc, x, baseline, face, value, c);
    }
    function onUpdate(dc) {
        width = dc.getWidth(); height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        // Primitive AA is independent of font resource antialiasing.
        dc.setPenWidth(Layout.STROKE); if (dc has :setAntiAlias) { dc.setAntiAlias(true); }
        loadFonts();
        if (width != Layout.WIDTH || height != Layout.HEIGHT) {
            text(dc, width/2, height/2, 3, "FastRider", DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
            text(dc, width/2, height/2+Layout.u(24), 3, "1 field", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER); return;
        }
        drawPrimary(dc);
        color(dc, DisplayRules.RULE); dc.fillRectangle(Layout.COLUMN_DIVIDER, Layout.MIDDLE_TOP, Layout.STROKE, Layout.STATS_BOTTOM-Layout.MIDDLE_TOP);
        text(dc, Layout.LIVE_LEFT_CENTER, Layout.LIVE_LABEL_TOP, 3, "gear", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, Layout.LIVE_RIGHT_CENTER, Layout.LIVE_LABEL_TOP, 3, "rpm", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        drawLive(dc, Layout.LIVE_LEFT_CENTER, Layout.LIVE_VALUE_TOP, intText(rearGear), Layout.LIVE_LEFT_WIDTH, DisplayRules.INK);
        drawLive(dc, Layout.LIVE_RIGHT_CENTER, Layout.LIVE_VALUE_TOP, intText(cadence), Layout.LIVE_RIGHT_WIDTH, DisplayRules.cadenceColor(cadence));
        text(dc, Layout.LIVE_LEFT_CENTER, Layout.LIVE_LABEL_BOTTOM, 3, "%", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, Layout.LIVE_RIGHT_CENTER, Layout.LIVE_LABEL_BOTTOM, 3, "mph", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        drawLive(dc, Layout.LIVE_LEFT_CENTER, Layout.LIVE_VALUE_BOTTOM, intText(grade), Layout.LIVE_LEFT_WIDTH, DisplayRules.gradeColor(grade));
        drawLive(dc, Layout.LIVE_RIGHT_CENTER, Layout.LIVE_VALUE_BOTTOM, RideMath.speedMphText(speed), Layout.LIVE_RIGHT_WIDTH, DisplayRules.INK);
        drawStats(dc); drawChartHeader(dc); drawPowerTrend(dc);
        if ((BuildMode.DEMO || BuildMode.DIAGNOSTICS) && !demoDiagnostics) {
            var stats = System.getSystemStats();
            System.println((BuildMode.DEMO ? "FastRider demo memory: " : "FastRider device memory: ")+stats.usedMemory+" / "+stats.totalMemory+" bytes");
            demoDiagnostics = true;
        }
        if (flashRegion != 0 && System.getTimer() < flashUntil) {
            color(dc, DisplayRules.BLUE);
            if (flashRegion == 1) { dc.drawRectangle(Layout.RIGHT_TAP_LEFT, Layout.u(1), Layout.RIGHT_EDGE-Layout.RIGHT_TAP_LEFT, Layout.PRIMARY_BOTTOM-Layout.u(2)); }
            else if (flashRegion == 2) { dc.drawRectangle(Layout.RIGHT_TAP_LEFT, Layout.MIDDLE_TOP, Layout.RIGHT_EDGE-Layout.RIGHT_TAP_LEFT, Layout.STATS_BOTTOM-Layout.MIDDLE_TOP-Layout.u(1)); }
            else { dc.drawRectangle(Layout.u(1), Layout.BANNER_TOP, Layout.WIDTH-Layout.u(3), Layout.PLOT_BOTTOM-Layout.BANNER_TOP); }
        }
    }
    function drawPrimary(dc) {
        color(dc, DisplayRules.RULE); dc.fillRectangle(Layout.COLUMN_DIVIDER, Layout.TOP_RULE_Y, Layout.STROKE, Layout.TOP_RULE_HEIGHT);
        // Keep x=218..245 / y=0..33 clear for the native radar overlay.
        var watts = rolling.average(ui.powerSeconds);
        var hz = RideMath.zone(hr, hrLimits); var pz = RideMath.zone(watts, powerLimits);
        var hc = DisplayRules.zoneColor(hz); var pc = DisplayRules.powerColor(pz);
        var h = intText(hr); var p = intText(watts);
        var hf = heartFont(dc, h); var pf = primaryFont(dc, p);
        // Align visible numeral ink with the icon at each panel's left edge.
        var tracking = hf == 0 && h.length() > 2 ? Layout.HEART_TRACKING : 0;
        var hx = Layout.LEFT_EDGE; var bx = Layout.RIGHT_START;
        drawDigits(dc, hx-numberBounds(dc, h, hf, tracking)[0], Layout.PRIMARY_BASELINE, hf, h, hc, tracking, false);
        drawDigits(dc, bx-numberBounds(dc, p, pf, 0)[0], Layout.PRIMARY_BASELINE, pf, p, pc, 0, false);
        drawZoneBadge(dc, Layout.LEFT_RIGHT, hz, hf, hc);
        drawZoneBadge(dc, Layout.RIGHT_EDGE, pz, pf, pc);
        var iy = Layout.UNIT_BASELINE-Layout.BOLT_WIDTH;
        color(dc, DisplayRules.RED);
        dc.fillPolygon([[hx+Layout.u(8),iy+Layout.u(2)],[hx+Layout.u(6),iy],[hx+Layout.u(3),iy],[hx,iy+Layout.u(3)],[hx,iy+Layout.u(6)],[hx+Layout.u(2),iy+Layout.u(9)],[hx+Layout.u(8),iy+Layout.u(14)],[hx+Layout.u(14),iy+Layout.u(9)],[hx+Layout.u(16),iy+Layout.u(6)],[hx+Layout.u(16),iy+Layout.u(3)],[hx+Layout.u(13),iy],[hx+Layout.u(10),iy]]);
        drawBolt(dc, bx, iy);
        text(dc, bx+Layout.BOLT_WIDTH+Layout.INLINE_GAP, Layout.UNIT_BASELINE, 3, ui.powerSeconds+"s", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        color(dc, hc); dc.fillRectangle(Layout.LEFT_EDGE, Layout.ZONE_BAR_TOP, Layout.LEFT_WIDTH, Layout.ZONE_BAR);
        color(dc, pc); dc.fillRectangle(Layout.RIGHT_START, Layout.ZONE_BAR_TOP, Layout.RIGHT_WIDTH, Layout.ZONE_BAR);
        drawZoneMarker(dc, Layout.LEFT_EDGE, Layout.LEFT_WIDTH, RideMath.zoneFraction(hr, hrLimits, hrMinimum, hrMaximum));
        drawZoneMarker(dc, Layout.RIGHT_START, Layout.RIGHT_WIDTH, RideMath.zoneFraction(watts, powerLimits, 0, null));
    }
    function zoneBadgeWidth(dc, zone, mainFont) {
        var zf = mainFont == 6 ? 10 : 9; var nf = mainFont == 6 ? 4 : 8;
        return textWidth(dc, "Z", zf)+textWidth(dc, zone.format("%d"), nf);
    }
    function drawZoneBadge(dc, right, zone, mainFont, c) {
        if (zone == 0) { text(dc, right, Layout.ZONE_BASELINE, 3, "--", c, Graphics.TEXT_JUSTIFY_RIGHT); return; }
        var zf = mainFont == 6 ? 10 : 9; var nf = mainFont == 6 ? 4 : 8;
        var number = zone.format("%d");
        text(dc, right-textWidth(dc, number, nf), Layout.ZONE_BASELINE, zf, "Z", c, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, right, Layout.ZONE_BASELINE, nf, number, c, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    function drawZoneMarker(dc, left, barWidth, fraction) {
        if (fraction == null) { return; }
        var x = left+DisplayRules.pixel(fraction*(barWidth-Layout.ZONE_MARKER_WIDTH));
        var y = Layout.ZONE_BAR_TOP-(Layout.ZONE_MARKER_HEIGHT-Layout.ZONE_BAR)/2;
        color(dc, 0x000000);
        dc.fillRectangle(x, y, Layout.ZONE_MARKER_WIDTH, Layout.ZONE_MARKER_HEIGHT);
        // Invert only the part crossing the colored bar; retain black end caps.
        color(dc, Graphics.COLOR_WHITE);
        dc.fillRectangle(x, Layout.ZONE_BAR_TOP, Layout.ZONE_MARKER_WIDTH, Layout.ZONE_BAR);
    }
    function drawStats(dc) {
        var title = ui.allStats ? "All" : "LAP "+(lapNumber == null ? "?" : lapNumber.format("%d"));
        var time = RideMath.lapDuration(ui.allStats ? timerMillis : lap.timeMs);
        var average = intText(ui.allStats ? ridePower : lap.averagePower);
        var distance = ui.allStats ? meters : lap.distance;
        var parts = distanceParts(dc, distance, ui.allStats ? remainingDistance : null, ui.allStats);
        text(dc, Layout.RIGHT_START, Layout.STATS_TITLE_BASELINE, 3, title, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        var tf = textWidth(dc, time, 5) <= Layout.STATS_VALUE_WIDTH ? 5 : (textWidth(dc, time, 7) <= Layout.STATS_VALUE_WIDTH ? 7 : 4);
        text(dc, Layout.RIGHT_EDGE, Layout.STATS_TIME_BASELINE, tf, time, DisplayRules.INK, Graphics.TEXT_JUSTIFY_RIGHT);
        var af = textWidth(dc, average, 2) <= Layout.AVERAGE_VALUE_WIDTH ? 2 : 6;
        var aw = textWidth(dc, average, af); var uw = textWidth(dc, "AVG", 3);
        var ax = Layout.RIGHT_START+DisplayRules.pixel((Layout.RIGHT_WIDTH-aw-Layout.STATS_GAP-uw)/2.0);
        text(dc, ax, Layout.STATS_AVERAGE_BASELINE, af, average, DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
        var center = ax+aw+Layout.STATS_GAP+uw/2;
        text(dc, center, Layout.STATS_AVERAGE_LABEL_BASELINE, 3, "AVG", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, center, Layout.STATS_AVERAGE_BASELINE, 3, "W", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        var rowWidth = distanceRowWidth(parts);
        var x = Layout.RIGHT_START+DisplayRules.pixel((Layout.RIGHT_WIDTH-rowWidth)/2.0);
        drawPacked(dc, x, Layout.STATS_DISTANCE_BASELINE, parts[2], parts[0], DisplayRules.INK);
        x += packedWidth(parts[0], parts[2])+Layout.PACKED_GAP;
        drawPacked(dc, x, Layout.STATS_DISTANCE_BASELINE, 12, "mi", DisplayRules.LABEL);
        x += packedWidth("mi", 12)+Layout.PACKED_GAP;
        if (parts[1] != null) { drawPacked(dc, x, Layout.STATS_DISTANCE_BASELINE, parts[3], parts[1], DisplayRules.BLUE); }
    }
    function distanceRowWidth(parts as Lang.Array) {
        return packedWidth(parts[0], parts[2])+Layout.PACKED_GAP+packedWidth("mi", 12)+(parts[1] == null ? 0 : Layout.PACKED_GAP+packedWidth(parts[1], parts[3]));
    }
    function distanceParts(dc, distance, remaining, all) as Lang.Array {
        var shown = distance == null ? "--" : (distance/1609.344).format(all ? "%.1f" : "%.2f");
        var rest = all ? RideMath.remainingMilesText(remaining, 1) : null;
        var pairs = [[5,13],[7,14],[4,15]];
        // Fit complete decimal strings before considering extreme-value rounding.
        for (var pass = 0; pass < 3; pass += 1) {
            for (var i = 0; i < pairs.size(); i += 1) {
                var pair = pairs[i]; var parts = [shown,rest,pair[0],pair[1]];
                if (distanceRowWidth(parts) <= Layout.RIGHT_WIDTH) { return parts; }
            }
            if (pass == 0 && rest != null) { rest = RideMath.remainingMilesText(remaining, 0); }
            else if (distance != null) { shown = (distance/1609.344).format("%.0f"); }
        }
        return [shown,null,4,15];
    }
    function drawChartHeader(dc) {
        color(dc, DisplayRules.RULE); dc.fillRectangle(Layout.LEFT_EDGE, Layout.BANNER_TOP, Layout.RULE_WIDTH, Layout.STROKE);
        var climb = RideMath.ascentFeetValue(ascent);
        text(dc, Layout.LEFT_EDGE, Layout.HEADER_BASELINE, 11, climb, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, Layout.LEFT_EDGE+textWidth(dc, climb, 11)+Layout.STATS_GAP, Layout.HEADER_BASELINE, 12, "ft", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        drawRangeLabel(dc, ui.rangeLabel());
        var clock = System.getClockTime();
        text(dc, Layout.RIGHT_EDGE, Layout.HEADER_BASELINE, 3, RideMath.clock12(clock.hour, clock.min), DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    function drawBolt(dc, x, y) {
        color(dc, DisplayRules.BLUE);
        dc.fillPolygon([[x+Layout.u(9),y],[x,y+Layout.u(8)],[x+Layout.u(5),y+Layout.u(8)],[x+Layout.u(2),y+Layout.u(14)],[x+Layout.u(14),y+Layout.u(5)],[x+Layout.u(8),y+Layout.u(5)],[x+Layout.u(12),y]]);
    }
    function rangeWidth(dc, label) { return textWidth(dc, "< ", 3)+Layout.BOLT_WIDTH+textWidth(dc, " "+label+" >", 3); }
    function drawRangeLabel(dc, label) {
        var x = (Layout.WIDTH/2)-DisplayRules.pixel(rangeWidth(dc, label)/2.0);
        var bx = x+textWidth(dc, "< ", 3);
        text(dc, x, Layout.HEADER_BASELINE, 3, "< ", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, bx+Layout.BOLT_WIDTH, Layout.HEADER_BASELINE, 3, " "+label+" >", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        drawBolt(dc, bx, Layout.HEADER_BOLT_TOP);
    }
    function powerY(watts) {
        var lo = ftpWatts*0.55; var hi = ftpWatts*1.5;
        return DisplayRules.pixel(RideMath.clamp(Layout.PLOT_BOTTOM-(watts-lo)*(Layout.PLOT_BOTTOM-Layout.PLOT_TOP)/(hi-lo), Layout.PLOT_TOP, Layout.PLOT_BOTTOM-Layout.u(1)));
    }
    function chartX(t) { return DisplayRules.pixel(Layout.PLOT_RIGHT+(t-trend.endTime)*(Layout.PLOT_RIGHT-Layout.PLOT_LEFT)/trend.windowMillis(ui.range).toFloat()); }
    function drawPowerTrend(dc) {
        if (trend.endTime == null) { return; }
        var points = trend.viewPoints(ui.range);
        var previousX = -1; var previousY = 0; var previousSegment = -1;
        dc.setPenWidth(Layout.STROKE);
        for (var i = 0; i < points.size(); i += 1) {
            var p = points[i]; var px = chartX((p[0]+p[1])/2.0);
            if (px < Layout.PLOT_LEFT || px > Layout.PLOT_RIGHT) { previousX = -1; continue; }
            var watts = p[2]/p[3].toFloat(); var py = powerY(watts);
            var c = DisplayRules.plotColor(RideMath.zone(watts, powerLimits));
            color(dc, DisplayRules.fadeWhite(c)); dc.fillRectangle(px-Layout.u(1), py, Layout.BUCKET_WIDTH, Layout.PLOT_BOTTOM+1-py);
            color(dc, c);
            if (previousX >= Layout.PLOT_LEFT && previousSegment == p[4] && p[4] >= 0) { dc.drawLine(previousX, previousY, px, py); }
            else { dc.fillRectangle(px-Layout.u(1), py, Layout.BUCKET_WIDTH, Layout.STROKE); }
            previousX = px; previousY = py; previousSegment = p[4];
        }
        var fy = powerY(ftpWatts);
        for (var x = Layout.PLOT_LEFT; x < Layout.PLOT_RIGHT; x += Layout.GUIDE_STEP) {
            color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(x-Layout.u(1), fy-Layout.u(1), Layout.GUIDE_HALO_WIDTH, Layout.GUIDE_HALO_HEIGHT);
            color(dc, 0x59636E); dc.fillRectangle(x, fy, Layout.GUIDE_DASH, Layout.STROKE);
        }
        var zy = powerY(ftpWatts*0.75);
        color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(Layout.PLOT_LEFT, zy-Layout.u(1), Layout.PLOT_FILL_WIDTH, Layout.GUIDE_HALO_HEIGHT);
        color(dc, DisplayRules.BLUE); dc.fillRectangle(Layout.PLOT_LEFT, zy, Layout.PLOT_FILL_WIDTH, Layout.STROKE);
        for (var i = 0; i < trend.boundaries.size(); i += 1) {
            var px = chartX(trend.boundaries[i]);
            if (px < Layout.PLOT_LEFT || px > Layout.PLOT_RIGHT) { continue; }
            color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(px-Layout.u(2), Layout.PLOT_TOP, Layout.u(4), Layout.PLOT_BOTTOM-Layout.PLOT_TOP+1);
            color(dc, DisplayRules.INK); dc.fillRectangle(px-Layout.u(1), Layout.PLOT_TOP, Layout.STROKE, Layout.PLOT_BOTTOM-Layout.PLOT_TOP+1); dc.fillRectangle(px-Layout.u(3), Layout.PLOT_TOP, Layout.LAP_CAP_WIDTH, Layout.GUIDE_HALO_HEIGHT);
        }
        color(dc, DisplayRules.BLUE); dc.fillRectangle(Layout.PLOT_RIGHT, Layout.PLOT_TOP, Layout.STROKE, Layout.PLOT_BOTTOM-Layout.PLOT_TOP+1);
    }
}
