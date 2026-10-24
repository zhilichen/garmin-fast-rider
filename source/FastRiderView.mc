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
    var width = 246;
    var height = 322;
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
        if (BuildMode.DEMO) { BellAudio.tick(); computeDemo(); return; }
        if (timerMillis != null && info.timerTime != null && info.timerTime < timerMillis) { onTimerReset(); }
        BellAudio.tick();
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
        BellAudio.stop();
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
        if (width != 246 || height != 322 || !ui.tap(x, y)) { return false; }
        flashRegion = y < DisplayRules.PRIMARY_BOTTOM ? 1 : (y < 214 ? 2 : 3);
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
        // Use the known white page background for font coverage blending.
        dc.setColor(c, Graphics.COLOR_WHITE);
        var top = RideMath.clamp(baseline-FontInk.TOP[index], 0, height);
        var bottom = RideMath.clamp(baseline+FontInk.BOTTOM[index], 0, height);
        if (bottom <= top) { return; }
        dc.setClip(0, top, width, bottom-top);
        dc.drawText(x, baseline-fontSizes[index], fonts[index], value, align);
        dc.clearClip();
    }
    function textWidth(dc, value, index) { return dc.getTextWidthInPixels(value, fonts[index]); }
    function intText(value) { return value == null ? "--" : Math.round(value).toNumber().format("%d"); }
    function primaryFont(dc, value) { return textWidth(dc, value, 0) <= DisplayRules.RADAR_LEFT-DisplayRules.RIGHT_START ? 0 : 6; }
    function liveInteger(dc, value, available) {
        var s = intText(value);
        return textWidth(dc, s, 1) <= available ? s : "--";
    }
    function compactValue(dc, value, maxWidth) {
        if (value == null) { return "--"; }
        var s = value.format("%.1f");
        if (textWidth(dc, s, 1) > maxWidth) { s = intText(value); }
        return textWidth(dc, s, 1) > maxWidth ? "--" : s;
    }
    function onHide() { BellAudio.stop(); }
    function onUpdate(dc) {
        width = dc.getWidth(); height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        // Primitive AA is independent of font resource antialiasing.
        dc.setPenWidth(2); if (dc has :setAntiAlias) { dc.setAntiAlias(true); }
        loadFonts();
        if (width != 246 || height != 322) {
            text(dc, width/2, height/2, 3, "FastRider", DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
            text(dc, width/2, height/2+24, 3, "1 field", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER); return;
        }
        drawPrimary(dc);
        color(dc, DisplayRules.RULE); dc.fillRectangle(DisplayRules.COLUMN_DIVIDER, DisplayRules.MIDDLE_TOP, DisplayRules.STROKE, 123);
        text(dc, 31, 106, 3, "rpm", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 106, 3, "gear", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 31, 149, 1, liveInteger(dc, cadence, 60), DisplayRules.cadenceColor(cadence), Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 149, 1, liveInteger(dc, rearGear, 58), DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 31, 170, 3, "%", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 170, 3, "mph", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        var g = grade != null && grade > -0.05 && grade < 0.05 ? 0.0 : grade;
        text(dc, 31, 212, 1, compactValue(dc, g, 58), DisplayRules.gradeColor(grade), Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 212, 1, compactValue(dc, speed == null ? null : speed*2.236936292, 58), DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
        drawStats(dc); drawChartHeader(dc); drawPowerTrend(dc);
        if ((BuildMode.DEMO || BuildMode.DIAGNOSTICS) && !demoDiagnostics) {
            var stats = System.getSystemStats();
            System.println((BuildMode.DEMO ? "FastRider demo memory: " : "FastRider device memory: ")+stats.usedMemory+" / "+stats.totalMemory+" bytes");
            demoDiagnostics = true;
        }
        if (flashRegion != 0 && System.getTimer() < flashUntil) {
            color(dc, DisplayRules.BLUE);
            if (flashRegion == 1) { dc.drawRectangle(124, 1, 120, 88); }
            else if (flashRegion == 2) { dc.drawRectangle(124, DisplayRules.MIDDLE_TOP, 120, 122); }
            else { dc.drawRectangle(1, 220, 243, 99); }
        }
    }
    function drawPrimary(dc) {
        color(dc, DisplayRules.RULE); dc.fillRectangle(DisplayRules.COLUMN_DIVIDER, 2, DisplayRules.STROKE, 66);
        // Keep x=218..245 / y=0..33 clear for the native radar overlay.
        var watts = rolling.average(ui.powerSeconds);
        var hz = RideMath.zone(hr, hrLimits); var pz = RideMath.zone(watts, powerLimits);
        var hc = DisplayRules.zoneColor(hz); var pc = DisplayRules.powerColor(pz);
        var h = intText(hr); var p = intText(watts);
        var hf = primaryFont(dc, h); var pf = primaryFont(dc, p);
        text(dc, 2, DisplayRules.PRIMARY_BASELINE, hf, h, hc, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 126, DisplayRules.PRIMARY_BASELINE, pf, p, pc, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 2, DisplayRules.UNIT_BASELINE, 3, "bpm", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        var powerUnit = "W "+ui.powerSeconds+"s";
        text(dc, 126, DisplayRules.UNIT_BASELINE, 3, powerUnit, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        drawZoneBadge(dc, 120, hz, hf, hc);
        drawZoneBadge(dc, 244, pz, pf, pc);
        // Keep inline unit icons clear of the Zone lane below the radar.
        var hx = 2+textWidth(dc, "bpm", 3)+4; var iy = DisplayRules.UNIT_BASELINE-14;
        color(dc, DisplayRules.RED);
        dc.fillPolygon([[hx+8,iy+2],[hx+6,iy],[hx+3,iy],[hx,iy+3],[hx,iy+6],[hx+2,iy+9],[hx+8,iy+14],[hx+14,iy+9],[hx+16,iy+6],[hx+16,iy+3],[hx+13,iy],[hx+10,iy]]);
        var bx = 126+textWidth(dc, powerUnit, 3)+4;
        color(dc, DisplayRules.BLUE);
        dc.fillPolygon([[bx+9,iy],[bx,iy+8],[bx+5,iy+8],[bx+2,iy+14],[bx+14,iy+5],[bx+8,iy+5],[bx+12,iy]]);
        color(dc, hc); dc.fillRectangle(2, DisplayRules.ZONE_BAR_TOP, DisplayRules.CELL_WIDTH, DisplayRules.ZONE_BAR);
        color(dc, pc); dc.fillRectangle(126, DisplayRules.ZONE_BAR_TOP, DisplayRules.CELL_WIDTH, DisplayRules.ZONE_BAR);
        drawZoneMarker(dc, 2, RideMath.zoneFraction(hr, hrLimits, hrMinimum, hrMaximum));
        drawZoneMarker(dc, 126, RideMath.zoneFraction(watts, powerLimits, 0, null));
    }
    function zoneBadgeWidth(dc, zone, mainFont) {
        var zf = mainFont == 0 ? 9 : 10; var nf = mainFont == 0 ? 8 : 4;
        return textWidth(dc, "Z", zf)+textWidth(dc, zone.format("%d"), nf);
    }
    function drawZoneBadge(dc, right, zone, mainFont, c) {
        if (zone == 0) { text(dc, right, DisplayRules.ZONE_BASELINE, 3, "--", c, Graphics.TEXT_JUSTIFY_RIGHT); return; }
        var zf = mainFont == 0 ? 9 : 10; var nf = mainFont == 0 ? 8 : 4;
        var number = zone.format("%d");
        text(dc, right-textWidth(dc, number, nf), DisplayRules.ZONE_BASELINE, zf, "Z", c, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, right, DisplayRules.ZONE_BASELINE, nf, number, c, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    function drawZoneMarker(dc, left, fraction) {
        if (fraction == null) { return; }
        var x = left+DisplayRules.pixel(fraction*(DisplayRules.CELL_WIDTH-DisplayRules.ZONE_MARKER_WIDTH));
        var y = DisplayRules.ZONE_BAR_TOP-(DisplayRules.ZONE_MARKER_HEIGHT-DisplayRules.ZONE_BAR)/2;
        color(dc, 0x000000);
        dc.fillRectangle(x, y, DisplayRules.ZONE_MARKER_WIDTH, DisplayRules.ZONE_MARKER_HEIGHT);
        // Invert only the part crossing the colored bar; retain black end caps.
        color(dc, Graphics.COLOR_WHITE);
        dc.fillRectangle(x, DisplayRules.ZONE_BAR_TOP, DisplayRules.ZONE_MARKER_WIDTH, DisplayRules.ZONE_BAR);
    }
    function drawStats(dc) {
        var title = ui.allStats ? "All" : "LAP "+(lapNumber == null ? "?" : lapNumber.format("%d"));
        var time = RideMath.lapDuration(ui.allStats ? timerMillis : lap.timeMs);
        var average = intText(ui.allStats ? ridePower : lap.averagePower);
        var distance = ui.allStats ? meters : lap.distance;
        var parts = distanceParts(dc, distance, ui.allStats ? remainingDistance : null, ui.allStats);
        text(dc, 126, 105, 3, title, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        var tf = textWidth(dc, time, 5) <= 118 ? 5 : (textWidth(dc, time, 7) <= 118 ? 7 : 4);
        text(dc, 244, 132, tf, time, DisplayRules.INK, Graphics.TEXT_JUSTIFY_RIGHT);
        var af = textWidth(dc, average, 2) <= 84 ? 2 : 6;
        text(dc, 126, 180, af, average, DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
        var center = 126+textWidth(dc, average, af)+3+15;
        text(dc, center, 160, 3, "AVG", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, center, 180, 3, "W", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        var x = 126;
        text(dc, x, 212, parts[2], parts[0], DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
        x += textWidth(dc, parts[0], parts[2]);
        text(dc, x, 212, 12, "mi", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        x += textWidth(dc, "mi", 12);
        if (parts[1] != null) { text(dc, x, 212, parts[3], parts[1], DisplayRules.BLUE, Graphics.TEXT_JUSTIFY_LEFT); }
    }
    function distanceParts(dc, distance, remaining, all) as Lang.Array {
        var shown = distance == null ? "--" : (distance/1609.344).format(all ? "%.1f" : "%.2f");
        var rest = all ? RideMath.remainingMilesText(remaining, 1) : null;
        var pairs = [[5,13],[7,14],[4,15]];
        // Keep full precision first, then round the suffix only when very long.
        for (var pass = 0; pass < 3; pass += 1) {
            for (var i = 0; i < pairs.size(); i += 1) {
                var pair = pairs[i];
                var w = textWidth(dc, shown, pair[0])+textWidth(dc, "mi", 12)+(rest == null ? 0 : textWidth(dc, rest, pair[1]));
                if (w <= 118) { return [shown,rest,pair[0],pair[1]]; }
            }
            if (pass == 0 && rest != null) { rest = RideMath.remainingMilesText(remaining, 0); }
            else if (distance != null) { shown = (distance/1609.344).format("%.0f"); }
        }
        // Unrepresentable, non-riding-scale values must not overlap the neighbor.
        return [shown,null,4,15];
    }
    function drawChartHeader(dc) {
        color(dc, DisplayRules.RULE); dc.fillRectangle(2, 220, 242, 2);
        var climb = RideMath.ascentFeetValue(ascent);
        text(dc, 2, 238, 11, climb, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 2+textWidth(dc, climb, 11)+3, 238, 12, "ft", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 123, 238, 3, "< "+ui.rangeLabel()+" >", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        var clock = System.getClockTime();
        text(dc, 244, 238, 3, RideMath.clock12(clock.hour, clock.min), DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    function powerY(watts) {
        var lo = ftpWatts*0.55; var hi = ftpWatts*1.5;
        return DisplayRules.pixel(RideMath.clamp(DisplayRules.PLOT_BOTTOM-(watts-lo)*(DisplayRules.PLOT_BOTTOM-DisplayRules.PLOT_TOP)/(hi-lo), DisplayRules.PLOT_TOP, DisplayRules.PLOT_BOTTOM-1));
    }
    function chartX(t) { return DisplayRules.pixel(DisplayRules.PLOT_RIGHT+(t-trend.endTime)*(DisplayRules.PLOT_RIGHT-DisplayRules.PLOT_LEFT)/trend.windowMillis(ui.range).toFloat()); }
    function drawPowerTrend(dc) {
        if (trend.endTime == null) { return; }
        var points = trend.viewPoints(ui.range);
        var previousX = -1; var previousY = 0; var previousSegment = -1;
        dc.setPenWidth(2);
        for (var i = 0; i < points.size(); i += 1) {
            var p = points[i]; var px = chartX((p[0]+p[1])/2.0);
            if (px < DisplayRules.PLOT_LEFT || px > DisplayRules.PLOT_RIGHT) { previousX = -1; continue; }
            var watts = p[2]/p[3].toFloat(); var py = powerY(watts);
            var c = DisplayRules.plotColor(RideMath.zone(watts, powerLimits));
            color(dc, DisplayRules.fadeWhite(c)); dc.fillRectangle(px-1, py, 2, DisplayRules.PLOT_BOTTOM+1-py);
            color(dc, c);
            if (previousX >= DisplayRules.PLOT_LEFT && previousSegment == p[4] && p[4] >= 0) { dc.drawLine(previousX, previousY, px, py); }
            else { dc.fillRectangle(px-1, py, 2, 2); }
            previousX = px; previousY = py; previousSegment = p[4];
        }
        var fy = powerY(ftpWatts);
        for (var x = DisplayRules.PLOT_LEFT; x < DisplayRules.PLOT_RIGHT; x += 8) {
            color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(x-1, fy-1, 6, 4);
            color(dc, 0x59636E); dc.fillRectangle(x, fy, 4, 2);
        }
        var zy = powerY(ftpWatts*0.75);
        color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(DisplayRules.PLOT_LEFT, zy-1, 239, 4);
        color(dc, DisplayRules.BLUE); dc.fillRectangle(DisplayRules.PLOT_LEFT, zy, 239, 2);
        for (var i = 0; i < trend.boundaries.size(); i += 1) {
            var px = chartX(trend.boundaries[i]);
            if (px < DisplayRules.PLOT_LEFT || px > DisplayRules.PLOT_RIGHT) { continue; }
            color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(px-2, DisplayRules.PLOT_TOP, 4, DisplayRules.PLOT_BOTTOM-DisplayRules.PLOT_TOP+1);
            color(dc, DisplayRules.INK); dc.fillRectangle(px-1, DisplayRules.PLOT_TOP, 2, DisplayRules.PLOT_BOTTOM-DisplayRules.PLOT_TOP+1); dc.fillRectangle(px-3, DisplayRules.PLOT_TOP, 6, 4);
        }
        color(dc, DisplayRules.BLUE); dc.fillRectangle(DisplayRules.PLOT_RIGHT, DisplayRules.PLOT_TOP, 2, DisplayRules.PLOT_BOTTOM-DisplayRules.PLOT_TOP+1);
    }
}
