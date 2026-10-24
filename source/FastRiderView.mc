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
    var fontSizes as Lang.Array<Lang.Number> = [49, 33, 44, 18, 20, 26, 32];
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
        if (width != 246 || height != 322 || !ui.tap(x, y)) { return false; }
        flashRegion = y < 98 ? 1 : (y < 214 ? 2 : 3);
        flashUntil = System.getTimer()+180;
        if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
            System.println("Tap ["+x+","+y+"] -> "+ui.powerSeconds+"s, "+(ui.allStats ? "All" : "LAP")+", "+ui.rangeLabel());
        }
        WatchUi.requestUpdate();
        return true;
    }
    function loadFonts() {
        if (fonts != null) { return; }
        fonts = [WatchUi.loadResource(Rez.Fonts.Primary49), WatchUi.loadResource(Rez.Fonts.Live33),
                 WatchUi.loadResource(Rez.Fonts.Average44), WatchUi.loadResource(Rez.Fonts.Meta18),
                 WatchUi.loadResource(Rez.Fonts.Chart20), WatchUi.loadResource(Rez.Fonts.Stats26),
                 WatchUi.loadResource(Rez.Fonts.Average32)];
    }
    function color(dc, c) { dc.setColor(c, Graphics.COLOR_TRANSPARENT); }
    function text(dc, x, baseline, index, value, c, align) {
        color(dc, c); dc.drawText(x, baseline-fontSizes[index], fonts[index], value, align);
    }
    function textWidth(dc, value, index) { return dc.getTextWidthInPixels(value, fonts[index]); }
    function intText(value) { return value == null ? "--" : Math.round(value).toNumber().format("%d"); }
    function compactValue(dc, value, maxWidth) {
        if (value == null) { return "--"; }
        var s = value.format("%.1f");
        if (textWidth(dc, s, 1) > maxWidth) { s = intText(value); }
        return textWidth(dc, s, 1) > maxWidth ? "--" : s;
    }
    function onUpdate(dc) {
        width = dc.getWidth(); height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setPenWidth(2); if (dc has :setAntiAlias) { dc.setAntiAlias(false); }
        loadFonts();
        if (width != 246 || height != 322) {
            text(dc, width/2, height/2, 3, "FastRider", DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
            text(dc, width/2, height/2+24, 3, "1 field", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER); return;
        }
        drawPrimary(dc);
        color(dc, DisplayRules.RULE); dc.fillRectangle(DisplayRules.COLUMN_DIVIDER, 102, DisplayRules.STROKE, 111);
        text(dc, 33, 117, 3, "rpm", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 117, 3, "gear", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 33, 149, 1, intText(cadence), DisplayRules.cadenceColor(cadence), Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 149, 1, intText(rearGear), DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 33, 174, 3, "%", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 174, 3, "mph", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        var g = grade != null && grade > -0.05 && grade < 0.05 ? 0.0 : grade;
        text(dc, 33, 207, 1, compactValue(dc, g, 50), DisplayRules.gradeColor(grade), Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 92, 207, 1, compactValue(dc, speed == null ? null : speed*2.236936292, 58), DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
        drawStats(dc); drawChartHeader(dc); drawPowerTrend(dc); drawFooter(dc);
        if ((BuildMode.DEMO || BuildMode.DIAGNOSTICS) && !demoDiagnostics) {
            var stats = System.getSystemStats();
            System.println((BuildMode.DEMO ? "FastRider demo memory: " : "FastRider device memory: ")+stats.usedMemory+" / "+stats.totalMemory+" bytes");
            demoDiagnostics = true;
        }
        if (flashRegion != 0 && System.getTimer() < flashUntil) {
            color(dc, DisplayRules.BLUE);
            if (flashRegion == 1) { dc.drawRectangle(124, 0, 121, 98); }
            else if (flashRegion == 2) { dc.drawRectangle(128, 102, 117, 112); }
            else { dc.drawRectangle(0, 220, 245, 78); }
        }
    }
    function drawPrimary(dc) {
        color(dc, DisplayRules.RULE); dc.fillRectangle(DisplayRules.COLUMN_DIVIDER, 17, DisplayRules.STROKE, 65);
        color(dc, 0xC62D32);
        dc.fillPolygon([[18,20],[15,17],[11,17],[8,20],[8,25],[10,28],[18,35],[26,28],[28,25],[28,20],[25,17],[21,17]]);
        color(dc, DisplayRules.BLUE); dc.fillPolygon([[142,17],[132,29],[138,29],[134,37],[150,24],[142,24],[146,17]]);
        var watts = rolling.average(ui.powerSeconds);
        var hz = RideMath.zone(hr, hrLimits); var pz = RideMath.zone(watts, powerLimits);
        var hc = DisplayRules.zoneColor(hz); var pc = DisplayRules.powerColor(pz);
        var h = intText(hr); var p = intText(watts);
        text(dc, 116, 52, textWidth(dc, h, 0) <= 84 ? 0 : 1, h, hc, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, 238, 52, textWidth(dc, p, 0) <= 84 ? 0 : 1, p, pc, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, 8, 76, 3, "bpm", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 130, 76, 3, "W "+ui.powerSeconds+"s", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 116, 76, 3, hz == 0 ? "--" : "Z"+hz, hc, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, 238, 76, 3, pz == 0 ? "--" : "Z"+pz, pc, Graphics.TEXT_JUSTIFY_RIGHT);
        color(dc, hc); dc.fillRectangle(8, 88, 108, DisplayRules.ZONE_BAR);
        color(dc, pc); dc.fillRectangle(130, 88, 108, DisplayRules.ZONE_BAR);
        drawZoneMarker(dc, 8, RideMath.zoneFraction(hr, hrLimits, hrMinimum, hrMaximum));
        drawZoneMarker(dc, 130, RideMath.zoneFraction(watts, powerLimits, 0, null));
    }
    function drawZoneMarker(dc, left, fraction) {
        if (fraction == null) { return; }
        var x = left+DisplayRules.pixel(fraction*(DisplayRules.CELL_WIDTH-DisplayRules.ZONE_MARKER_WIDTH));
        var y = 88-(DisplayRules.ZONE_MARKER_HEIGHT-DisplayRules.ZONE_BAR)/2;
        color(dc, 0x000000);
        dc.fillRectangle(x, y, DisplayRules.ZONE_MARKER_WIDTH, DisplayRules.ZONE_MARKER_HEIGHT);
    }
    function drawStats(dc) {
        var title = ui.allStats ? "All" : "LAP "+(lapNumber == null ? "?" : lapNumber.format("%d"));
        var time = RideMath.lapDuration(ui.allStats ? timerMillis : lap.timeMs);
        var average = intText(ui.allStats ? ridePower : lap.averagePower);
        var distance = ui.allStats ? meters : lap.distance;
        var dist = distance == null ? "-- mi" : (distance/1609.344).format(ui.allStats ? "%.1f" : "%.2f")+" mi";
        text(dc, 134, 117, 3, title, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        var available = 104-textWidth(dc, title, 3)-4;
        var tf = textWidth(dc, time, 5) <= available ? 5 : (textWidth(dc, time, 4) <= available ? 4 : 3);
        text(dc, 238, 123, tf, time, DisplayRules.INK, Graphics.TEXT_JUSTIFY_RIGHT);
        var af = textWidth(dc, average, 2) <= 67 ? 2 : 6;
        text(dc, 134, 169, af, average, DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
        var center = 134+textWidth(dc, average, af)+6+15;
        text(dc, center, 149, 3, "AVG", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, center, 169, 3, "W", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        if (textWidth(dc, dist, 5) > 104 && distance != null) { dist = (distance/1609.344).format("%.1f")+" mi"; }
        text(dc, 134, 202, textWidth(dc, dist, 5) <= 104 ? 5 : 4, dist, DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
    }
    function drawChartHeader(dc) {
        color(dc, DisplayRules.RULE); dc.fillRectangle(8, 220, 230, 2);
        text(dc, 8, 238, 4, millis == null ? "--:--" : RideMath.duration(millis), DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 123, 238, 3, "< "+ui.rangeLabel()+" >", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
        var clock = System.getClockTime(); var hour = clock.hour%12; if (hour == 0) { hour = 12; }
        var time = hour.format("%d")+":"+clock.min.format("%02d");
        var half = clock.hour < 12 ? "A" : "B";
        text(dc, 238-textWidth(dc, half, 3)-2, 238, 4, time, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, 238, 238, 3, half, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    function powerY(watts) {
        var lo = ftpWatts*0.55; var hi = ftpWatts*1.5;
        return DisplayRules.pixel(RideMath.clamp(293-(watts-lo)*50/(hi-lo), 243, 292));
    }
    function chartX(t) { return DisplayRules.pixel(228+(t-trend.endTime)*212/trend.windowMillis(ui.range).toFloat()); }
    function drawPowerTrend(dc) {
        if (trend.endTime == null) { return; }
        var points = trend.viewPoints(ui.range);
        var previousX = -1; var previousY = 0; var previousSegment = -1;
        dc.setPenWidth(2);
        for (var i = 0; i < points.size(); i += 1) {
            var p = points[i]; var px = chartX((p[0]+p[1])/2.0);
            if (px < 16 || px > 228) { previousX = -1; continue; }
            var watts = p[2]/p[3].toFloat(); var py = powerY(watts);
            var c = DisplayRules.plotColor(RideMath.zone(watts, powerLimits));
            color(dc, DisplayRules.fadeWhite(c)); dc.fillRectangle(px-1, py, 2, 294-py);
            color(dc, c);
            if (previousX >= 16 && previousSegment == p[4] && p[4] >= 0) { dc.drawLine(previousX, previousY, px, py); }
            else { dc.fillRectangle(px-1, py, 2, 2); }
            previousX = px; previousY = py; previousSegment = p[4];
        }
        var fy = powerY(ftpWatts);
        for (var x = 16; x < 228; x += 8) {
            color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(x-1, fy-1, 6, 4);
            color(dc, 0x59636E); dc.fillRectangle(x, fy, 4, 2);
        }
        var zy = powerY(ftpWatts*0.75);
        color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(16, zy-1, 213, 4);
        color(dc, DisplayRules.BLUE); dc.fillRectangle(16, zy, 213, 2);
        for (var i = 0; i < trend.boundaries.size(); i += 1) {
            var px = chartX(trend.boundaries[i]);
            if (px < 16 || px > 228) { continue; }
            color(dc, Graphics.COLOR_WHITE); dc.fillRectangle(px-2, 243, 4, 51);
            color(dc, DisplayRules.INK); dc.fillRectangle(px-1, 243, 2, 51); dc.fillRectangle(px-3, 243, 6, 4);
        }
        color(dc, DisplayRules.BLUE); dc.fillRectangle(227, 243, 3, 51);
    }
    function footerWidth(dc, total, remaining, unit) {
        return textWidth(dc, total, 4)+2+textWidth(dc, unit, 3)+(remaining == null ? 0 : 2+textWidth(dc, remaining, 4));
    }
    function footerGroup(dc, x, total, remaining, unit) {
        text(dc, x, 316, 4, total, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT); x += textWidth(dc, total, 4)+2;
        if (remaining != null) {
            text(dc, x, 316, 4, remaining, DisplayRules.BLUE, Graphics.TEXT_JUSTIFY_LEFT); x += textWidth(dc, remaining, 4)+2;
        }
        text(dc, x, 316, 3, unit, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
    }
    function drawFooter(dc) {
        var dist = meters == null ? "--" : (meters/1609.344).format("%.1f");
        var up = ascent == null ? "--" : intText(ascent*3.280839895);
        var rest = remainingDistance == null ? null : "("+(remainingDistance/1609.344).format("%.1f")+")";
        var restUp = remainingAscent == null ? null : "("+intText(remainingAscent*3.280839895)+")";
        var lw = footerWidth(dc, dist, rest, "mi"); var rw = footerWidth(dc, up, restUp, "ft");
        if (lw+rw > 228 && meters != null) { dist = (meters/1609.344).format("%.0f"); }
        if (footerWidth(dc, dist, rest, "mi")+rw > 228 && remainingDistance != null) { rest = "("+(remainingDistance/1609.344).format("%.0f")+")"; }
        if (footerWidth(dc, dist, rest, "mi")+rw > 228) { rest = null; restUp = null; rw = footerWidth(dc, up, null, "ft"); }
        footerGroup(dc, 6, dist, rest, "mi");
        footerGroup(dc, 240-rw, up, restUp, "ft");
    }
}
