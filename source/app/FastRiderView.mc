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
    var fonts as Lang.Array<Graphics.FontType or Null> or Null = null;
    var fontResources as Lang.Array = [];
    var fontOrder as Lang.Array<Lang.Number> = [];
    var fontCacheLimit = 16;
    var fontSizes as Lang.Array<Lang.Number> = FontInk.SIZES;
    var flashRegion = 0;
    var flashUntil = 0;
    var sensorMask = -1;
    var theme as DisplayTheme;
    var screen as RideScreenState;
    var normalized as NormalizedPower;
    var averageHr = null;
    var averageCadence = null;
    var averageSpeed = null;

    function initialize() {
        DataField.initialize();
        if (!(Graphics has :createBufferedBitmap)) { fontCacheLimit = 8; }
        theme = new DisplayTheme();
        screen = new RideScreenState(); normalized = new NormalizedPower();
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
        screen.update(info.timerState);
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
        averageHr = timerMillis != null && timerMillis > 0 && info.averageHeartRate != null && info.averageHeartRate > 0 ? info.averageHeartRate : null;
        averageCadence = RideMath.recordedAverage(timerMillis, info.averageCadence);
        averageSpeed = RideMath.recordedAverage(timerMillis, info.averageSpeed);
        normalized.update(timerMillis, power, running);
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
        for (var n = 0; n <= 120; n += 1) { normalized.update(n*1000, 220, true); }
    }
    function computeDemo() {
        if (!demoSeeded) { seedDemo(); }
        var t = (System.getTimer()-start)/1000.0;
        if (screen.state == Activity.TIMER_STATE_OFF) { screen.update(Activity.TIMER_STATE_ON); }
        millis = 4988000+(t*1000).toNumber();
        if (!screen.summary() || timerMillis == null) { timerMillis = millis; }
        power = RideMath.demoPower(millis/1000.0);
        hr = 158; cadence = 64; rearGear = 5; speed = 10.0138;
        meters = demoMeters(millis/1000.0); ascent = 682.0+t/10.0; grade = 6.4;
        remainingDistance = 19955.8656; remainingAscent = 365.76;
        ridePower = 212; averageHr = 146; averageCadence = 86; averageSpeed = 8.9408;
        rolling.update(timerMillis, power, true);
        lap.update(timerMillis, power, true); lap.updateDistance(meters);
        trend.update(millis, power, true);
    }
    function onTimerReset() {
        hardwareLog("timer reset -> defaults=3s/All/5m");
        trend.reset(); rolling.reset(); lap.reset(); ride.reset(); ui.reset();
        normalized.reset(); screen.reset(); averageHr = null; averageCadence = null; averageSpeed = null;
        gradeEstimator.reset(); grade = null; lapNumber = null;
        demoSeeded = false; demoDiagnostics = false; ascent = null; remainingDistance = null; remainingAscent = null;
        meters = null; millis = null; timerMillis = null; ridePower = null;
        power = null; hr = null; cadence = null; speed = null; rearGear = null;
        flashRegion = 0; start = System.getTimer();
        sensorMask = -1;
    }
    function onTimerStart() {
        hardwareLog("timer start");
        screen.update(Activity.TIMER_STATE_ON); WatchUi.requestUpdate();
        if (BuildMode.DEMO) { return; }
        var info = Activity.getActivityInfo();
        if (info.timerTime != null && info.timerTime == 0) {
            lap.beginAt(0, info.currentPower, info.elapsedDistance);
            ride.beginAt(0, info.currentPower, info.elapsedDistance); lapNumber = 1;
        } else { lap.started(info.timerTime); ride.started(info.timerTime); }
        trend.started(info.elapsedTime); rolling.reset(); normalized.started(info.timerTime);
    }
    function breakSamples() { lap.breakSample(); ride.breakSample(); trend.breakSample(); rolling.reset(); normalized.breakSample(); }
    function onTimerPause() { hardwareLog("timer pause"); screen.update(Activity.TIMER_STATE_PAUSED); breakSamples(); WatchUi.requestUpdate(); }
    function onTimerResume() { hardwareLog("timer resume"); screen.update(Activity.TIMER_STATE_ON); breakSamples(); WatchUi.requestUpdate(); }
    function onTimerStop() { hardwareLog("timer stop"); screen.update(Activity.TIMER_STATE_STOPPED); breakSamples(); WatchUi.requestUpdate(); }
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
        if (screen.summary() && y < chartTop()) { return false; }
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
        fontResources = FontInk.resources();
        fonts = [];
        for (var i = 0; i < fontResources.size(); i += 1) { fonts.add(null); }
    }
    // Preserve role indices while loading only the glyph atlases actually used.
    // Retired Zone/Z faces and unused size fallbacks consume no field heap.
    function font(index) as Graphics.FontType {
        if (fonts[index] == null) {
            // Bound retained atlases across view and digit-width changes on 530/830.
            if (fontOrder.size() >= fontCacheLimit) { fonts[fontOrder[0]] = null; fontOrder.remove(fontOrder[0]); }
            fonts[index] = WatchUi.loadResource(fontResources[index]) as Graphics.FontType;
        } else { fontOrder.remove(index); }
        fontOrder.add(index);
        return fonts[index] as Graphics.FontType;
    }
    function color(dc, c) { dc.setColor(c, Graphics.COLOR_TRANSPARENT); }
    function text(dc, x, baseline, index, value, c, align) {
        // Native BMFont rasterization adds one row below the source ink bounds.
        // Keep it inside the theme AA backdrop clip so rounded bottoms survive.
        dc.setColor(c, theme.background);
        var top = RideMath.clamp(baseline-FontInk.TOP[index], 0, height);
        var bottom = RideMath.clamp(baseline+FontInk.BOTTOM[index]+FontInk.NATIVE_BOTTOM_PAD, 0, height);
        if (bottom <= top) { return; }
        dc.setClip(0, top, width, bottom-top);
        dc.drawText(x, baseline-fontSizes[index], font(index), value, align);
        dc.clearClip();
    }
    function textWidth(dc, value, index) { return dc.getTextWidthInPixels(value, font(index)); }
    function intText(value) { return value == null ? "--" : Math.round(value).toNumber().format("%d"); }
    function primaryFont(dc, value) {
        var available = powerValueWidth();
        if (numberWidth(dc,value,0,0) <= available) { return 0; }
        if (packedWidth(value,FontInk.PRIMARY_COMPACT) <= available) { return FontInk.PRIMARY_COMPACT; }
        return compactPrimaryFont(value,available);
    }
    function compactPrimaryFont(value, available) {
        for (var i = 0; i < FontInk.LIVE_SIDE_FACES.size(); i += 1) {
            var f = FontInk.LIVE_SIDE_FACES[i];
            if (packedWidth(value,f) <= available) { return f; }
        }
        return 4;
    }
    function primaryBaseline(face) {
        var extra = FontInk.TOP[face]-FontInk.TOP[0];
        return Layout.PRIMARY_BASELINE+(extra > 0 ? extra : 0);
    }
    function powerBadgeRight() { return Layout.RADAR_LEFT-Layout.u(2); }
    function powerValueWidth() { return powerBadgeRight()-Layout.ZONE_BADGE_WIDTH-Layout.RIGHT_START-Layout.PRIMARY_ZONE_GAP; }
    function digitIndex(ch) {
        if (ch.equals(".")) { return 10; } if (ch.equals("-")) { return 11; }
        if (ch.equals("(")) { return 12; } if (ch.equals(")")) { return 13; }
        if (ch.equals("m")) { return 14; } if (ch.equals("i")) { return 15; }
        if (ch.equals(":")) { return 16; }
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
            // the theme AA backdrop so it cannot erase its closer neighbor.
            dc.setClip(lo, top, hi-lo, h); dc.setColor(c, theme.background);
            dc.drawText(origin+pen, baseline-fontSizes[index], font(index), ch, Graphics.TEXT_JUSTIFY_LEFT);
            dc.clearClip(); pen += textWidth(dc, ch, index)-tracking;
        }
    }
    function heartFont(dc, value) {
        var tracking = value.length() > 2 ? Layout.HEART_TRACKING : 0;
        var bounds = numberBounds(dc, value, 0, tracking);
        return bounds[1]-bounds[0]+Layout.ZONE_BADGE_WIDTH+Layout.PRIMARY_ZONE_GAP <= Layout.LEFT_WIDTH ? 0 : 6;
    }
    function packedGap(value, position) {
        if (position >= value.length()-1) { return 0; }
        var punctuation = value.substring(position,position+1).equals(":") || value.substring(position+1,position+2).equals(":");
        return Layout.PACKED_GAP+(punctuation ? Layout.COLON_GAP : 0);
    }
    function packedWidth(value, index) {
        var w = 0;
        for (var i = 0; i < value.length(); i += 1) {
            var d = digitIndex(value.substring(i,i+1));
            w += FontInk.NUMERIC_RIGHT[index][d]-FontInk.NUMERIC_LEFT[index][d]+packedGap(value,i);
        }
        return w;
    }
    function drawPacked(dc, x, baseline, index, value, c) {
        var top = baseline-FontInk.TOP[index]; var h = FontInk.TOP[index]+FontInk.BOTTOM[index]+FontInk.NATIVE_BOTTOM_PAD;
        var cursor = x;
        for (var i = 0; i < value.length(); i += 1) {
            var ch = value.substring(i,i+1); var d = digitIndex(ch);
            var left = FontInk.NUMERIC_LEFT[index][d];
            var w = FontInk.NUMERIC_RIGHT[index][d]-left;
            dc.setClip(cursor, top, w, h); dc.setColor(c, theme.background);
            dc.drawText(cursor-left, baseline-fontSizes[index], font(index), ch, Graphics.TEXT_JUSTIFY_LEFT);
            dc.clearClip(); cursor += w+packedGap(value,i);
        }
    }
    function liveFont(value, available) {
        var faces = FontInk.LIVE_FACES;
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
    function statsWidth(dc, value, face) {
        return FontInk.PACK_STATS ? packedWidth(value, face) : textWidth(dc, value, face);
    }
    function statsFace(dc, value, faces as Lang.Array, available) {
        for (var i = 0; i < faces.size(); i += 1) {
            if (statsWidth(dc, value, faces[i]) <= available) { return faces[i]; }
        }
        return faces[faces.size()-1];
    }
    function drawStatsNumber(dc, x, baseline, face, value, align) {
        if (!FontInk.PACK_STATS) { text(dc, x, baseline, face, value, theme.ink, align); return; }
        if (align == Graphics.TEXT_JUSTIFY_RIGHT) { x -= packedWidth(value, face); }
        drawPacked(dc, x, baseline, face, value, theme.ink);
    }
    function onUpdate(dc) {
        width = dc.getWidth(); height = dc.getHeight();
        theme.setBackground(getBackgroundColor());
        dc.setColor(theme.ink, theme.background); dc.clear();
        // Primitive AA is independent of font resource antialiasing.
        dc.setPenWidth(Layout.STROKE); if (dc has :setAntiAlias) { dc.setAntiAlias(true); }
        loadFonts();
        if (width != Layout.WIDTH || height != Layout.HEIGHT) {
            text(dc, width/2, height/2, 3, "FastRider", theme.ink, Graphics.TEXT_JUSTIFY_CENTER);
            text(dc, width/2, height/2+Layout.u(24), 3, "1 field", theme.label, Graphics.TEXT_JUSTIFY_CENTER); return;
        }
        if (screen.summary()) { SummaryRenderer.draw(self, dc); }
        else {
            drawPrimary(dc);
            color(dc, theme.rule); dc.fillRectangle(Layout.COLUMN_DIVIDER, Layout.MIDDLE_TOP, Layout.STROKE, Layout.STATS_BOTTOM-Layout.MIDDLE_TOP);
            LiveMetrics.draw(self,dc);
            drawStats(dc);
        }
        drawChartHeader(dc); drawPowerTrend(dc);
        if ((BuildMode.DEMO || BuildMode.DIAGNOSTICS) && !demoDiagnostics) {
            var stats = System.getSystemStats();
            System.println((BuildMode.DEMO ? "FastRider demo memory: " : "FastRider device memory: ")+stats.usedMemory+" / "+stats.totalMemory+" bytes");
            demoDiagnostics = true;
        }
        if (flashRegion != 0 && System.getTimer() < flashUntil) {
            color(dc, theme.blue);
            if (flashRegion == 1) { dc.drawRectangle(Layout.RIGHT_TAP_LEFT, Layout.u(1), Layout.RIGHT_EDGE-Layout.RIGHT_TAP_LEFT, Layout.PRIMARY_BOTTOM-Layout.u(2)); }
            else if (flashRegion == 2) { dc.drawRectangle(Layout.RIGHT_TAP_LEFT, Layout.MIDDLE_TOP, Layout.RIGHT_EDGE-Layout.RIGHT_TAP_LEFT, Layout.STATS_BOTTOM-Layout.MIDDLE_TOP-Layout.u(1)); }
            else { dc.drawRectangle(Layout.u(1), chartTop(), Layout.WIDTH-Layout.u(3), Layout.PLOT_BOTTOM-chartTop()); }
        }
    }
    function drawPrimary(dc) {
        color(dc, theme.rule); dc.fillRectangle(Layout.COLUMN_DIVIDER, Layout.TOP_RULE_Y, Layout.STROKE, Layout.TOP_RULE_HEIGHT);
        // Keep x=218..245 / y=0..33 clear for the native radar overlay.
        var watts = rolling.average(ui.powerSeconds);
        var hz = RideMath.zone(hr, hrLimits); var pz = RideMath.zone(watts, powerLimits);
        var hc = theme.zoneColor(hz); var pc = theme.powerColor(pz);
        var h = intText(hr); var p = intText(watts);
        var hf = heartFont(dc, h); var pf = primaryFont(dc, p);
        // Align visible numeral ink with the icon at each panel's left edge.
        var tracking = hf == 0 && h.length() > 2 ? Layout.HEART_TRACKING : 0;
        var hx = Layout.LEFT_EDGE; var bx = Layout.RIGHT_START;
        drawDigits(dc, hx-numberBounds(dc, h, hf, tracking)[0], Layout.PRIMARY_BASELINE, hf, h, hc, tracking, false);
        if (pf == 0) { drawDigits(dc,bx-numberBounds(dc,p,pf,0)[0],Layout.PRIMARY_BASELINE,pf,p,pc,0,false); }
        else { drawPacked(dc,bx,primaryBaseline(pf),pf,p,pc); }
        drawZoneBadge(dc, Layout.LEFT_RIGHT, hz, hf, hc);
        drawZoneBadge(dc, powerBadgeRight(), pz, pf, pc);
        var iy = Layout.UNIT_BASELINE-Layout.BOLT_WIDTH;
        drawHeart(dc, hx, iy);
        drawBolt(dc, bx, iy);
        text(dc, bx+Layout.BOLT_WIDTH+Layout.INLINE_GAP, Layout.UNIT_BASELINE, 3, ui.powerSeconds+"s", theme.label, Graphics.TEXT_JUSTIFY_LEFT);
        drawZoneGauge(dc, Layout.LEFT_EDGE, Layout.LEFT_WIDTH, RideMath.zoneFraction(hr, hrLimits, hrMinimum, hrMaximum), hc);
        drawZoneGauge(dc, Layout.RIGHT_START, Layout.RIGHT_WIDTH, RideMath.zoneFraction(watts, powerLimits, 0, null), pc);
    }
    function drawHeart(dc, x, y) {
        color(dc, theme.red);
        dc.fillPolygon([[x+Layout.u(8),y+Layout.u(2)],[x+Layout.u(6),y],[x+Layout.u(3),y],[x,y+Layout.u(3)],[x,y+Layout.u(6)],[x+Layout.u(2),y+Layout.u(9)],[x+Layout.u(8),y+Layout.u(14)],[x+Layout.u(14),y+Layout.u(9)],[x+Layout.u(16),y+Layout.u(6)],[x+Layout.u(16),y+Layout.u(3)],[x+Layout.u(13),y],[x+Layout.u(10),y]]);
    }
    function zoneBadgeFont(mainFont) { return 1; }
    function zoneBadgeWidth(dc, zone, mainFont) {
        return mainFont == 6 ? Layout.ZONE_SMALL_BADGE_WIDTH : Layout.ZONE_BADGE_WIDTH;
    }
    function drawZoneBadge(dc, right, zone, mainFont, c) {
        var nf = zoneBadgeFont(mainFont);
        var number = zone == 0 ? "--" : zone.format("%d");
        var w = zoneBadgeWidth(dc, zone, mainFont);
        var h = FontInk.TOP[nf]+FontInk.BOTTOM[nf]+FontInk.NATIVE_BOTTOM_PAD+2*Layout.ZONE_BADGE_PADDING;
        var x = right-w; var y = Layout.ZONE_BADGE_BOTTOM-h;
        // Filled outer/inner shapes keep the border inside its pixel bounds.
        color(dc, c); dc.fillRoundedRectangle(x, y, w, h, Layout.ZONE_BADGE_RADIUS);
        color(dc, theme.background);
        dc.fillRoundedRectangle(x+Layout.STROKE, y+Layout.STROKE, w-2*Layout.STROKE,
            h-2*Layout.STROKE, Layout.ZONE_BADGE_RADIUS-Layout.STROKE);
        drawPacked(dc, x+DisplayRules.pixel((w-packedWidth(number,nf))/2.0),
            Layout.ZONE_BADGE_BOTTOM-Layout.ZONE_BADGE_PADDING-FontInk.BOTTOM[nf]-FontInk.NATIVE_BOTTOM_PAD,
            nf, number, c);
    }
    function drawZoneGauge(dc, left, barWidth, fraction, c) {
        var top = Layout.ZONE_WEDGE_TOP; var bottom = Layout.ZONE_WEDGE_BOTTOM;
        var inset = Layout.STROKE/2.0;
        var right = left+barWidth-1;
        var points = [[left+inset,bottom-Layout.ZONE_WEDGE_THIN+1],
            [right-inset,top+inset],[right-inset,bottom-inset],[left+inset,bottom-inset]];
        var filled = zoneGaugeWidth(barWidth,fraction);
        color(dc, c);
        // Fill up to the current position; the rest retains the real day/night backdrop.
        if (filled > 0) {
            dc.setClip(left,top,filled,bottom-top+1); dc.fillPolygon(points); dc.clearClip();
        }
        dc.setPenWidth(Layout.STROKE);
        for (var i = 0; i < points.size(); i += 1) {
            var next = (i+1)%points.size();
            dc.drawLine(points[i][0],points[i][1],points[next][0],points[next][1]);
        }
    }
    function zoneGaugeWidth(barWidth, fraction) {
        return fraction == null ? 0 : DisplayRules.pixel(barWidth*RideMath.clamp(fraction,0.0,1.0));
    }
    function drawStats(dc) { RideStatistics.draw(self,dc); }
    function distanceRowWidth(parts as Lang.Array) {
        return packedWidth(parts[0], parts[2])+Layout.PACKED_GAP+packedWidth("mi", 12)+(parts[1] == null ? 0 : Layout.PACKED_GAP+packedWidth(parts[1], parts[3]));
    }
    function distanceParts(dc, distance, remaining, all) as Lang.Array {
        var room = Layout.STATS_DISTANCE_BASELINE-Layout.STATS_AVERAGE_BASELINE-FontInk.BOTTOM[3]-FontInk.NATIVE_BOTTOM_PAD-Layout.u(3);
        var maxTop = FontInk.TOP[FontInk.LIVE_SIDE_FACES[2]];
        if (room < maxTop) { maxTop = room; }
        return distancePartsUsing(dc,distance,remaining,all,Layout.RIGHT_WIDTH,maxTop,FontInk.RIDE_DISTANCE_PAIRS);
    }
    function distancePartsWithin(dc, distance, remaining, all, available, maxTop) as Lang.Array {
        return distancePartsUsing(dc,distance,remaining,all,available,maxTop,FontInk.DISTANCE_PAIRS);
    }
    function distancePartsUsing(dc, distance, remaining, all, available, maxTop, pairs as Lang.Array) as Lang.Array {
        var shown = distance == null ? "--" : (distance/1609.344).format(all ? "%.1f" : "%.2f");
        var rest = all ? RideMath.remainingMilesText(remaining, 1) : null;
        // Fit complete decimal strings before considering extreme-value rounding.
        for (var pass = 0; pass < 3; pass += 1) {
            for (var i = 0; i < pairs.size(); i += 1) {
                var pair = pairs[i] as Lang.Array; var parts = [shown,rest,pair[0],pair[1]];
                if (distanceRowWidth(parts) <= available && (maxTop == null || FontInk.TOP[pair[0]] <= maxTop && FontInk.TOP[pair[1]] <= maxTop)) { return parts; }
            }
            if (pass == 0 && rest != null) { rest = RideMath.remainingMilesText(remaining, 0); }
            else if (distance != null) { shown = (distance/1609.344).format("%.0f"); }
        }
        return [shown,null,4,15];
    }
    function clockText() {
        var clock = System.getClockTime();
        return RideMath.clock12(clock.hour, clock.min);
    }
    function chartTop() { return screen.summary() ? SummaryLayout.BANNER_TOP : Layout.BANNER_TOP; }
    function bellBottom() { return screen.summary() ? SummaryLayout.BANNER_TOP : Layout.STATS_BOTTOM; }
    function drawChartHeader(dc) {
        color(dc, theme.rule); dc.fillRectangle(Layout.LEFT_EDGE, chartTop(), Layout.RULE_WIDTH, Layout.STROKE);
        if (screen.summary()) { drawRangeLabel(dc,ui.rangeLabel()); return; }
        var climb = RideMath.ascentFeetValue(ascent);
        text(dc, Layout.LEFT_EDGE, Layout.HEADER_BASELINE, 11, climb, theme.label, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, Layout.LEFT_EDGE+textWidth(dc, climb, 11)+Layout.STATS_GAP, Layout.HEADER_BASELINE, 12, "ft", theme.label, Graphics.TEXT_JUSTIFY_LEFT);
        drawRangeLabel(dc, ui.rangeLabel());
        text(dc, Layout.RIGHT_EDGE, Layout.HEADER_BASELINE, 3, clockText(), theme.label, Graphics.TEXT_JUSTIFY_RIGHT);
    }
    function drawBolt(dc, x, y) {
        color(dc, theme.blue);
        dc.fillPolygon([[x+Layout.u(9),y],[x,y+Layout.u(8)],[x+Layout.u(5),y+Layout.u(8)],[x+Layout.u(2),y+Layout.u(14)],[x+Layout.u(14),y+Layout.u(5)],[x+Layout.u(8),y+Layout.u(5)],[x+Layout.u(12),y]]);
    }
    function rangeWidth(dc, label) { return textWidth(dc, screen.summary() ? "<" : "< ", 3)+Layout.BOLT_WIDTH+textWidth(dc, screen.summary() ? label+">" : " "+label+" >", 3); }
    function drawRangeLabel(dc, label) {
        var x = (Layout.WIDTH/2)-DisplayRules.pixel(rangeWidth(dc, label)/2.0);
        var lead = screen.summary() ? "<" : "< ";
        var tail = screen.summary() ? label+">" : " "+label+" >";
        var bx = x+textWidth(dc, lead, 3);
        var baseline = screen.summary() ? SummaryLayout.HEADER_BASELINE : Layout.HEADER_BASELINE;
        text(dc, x, baseline, 3, lead, theme.label, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, bx+Layout.BOLT_WIDTH, baseline, 3, tail, theme.label, Graphics.TEXT_JUSTIFY_LEFT);
        drawBolt(dc, bx, screen.summary() ? SummaryLayout.HEADER_BOLT_TOP : Layout.HEADER_BOLT_TOP);
    }
    function plotTop() { return screen.summary() ? SummaryLayout.PLOT_TOP : Layout.PLOT_TOP; }
    function powerY(watts) {
        var lo = ftpWatts*0.55; var hi = ftpWatts*1.5;
        return DisplayRules.pixel(RideMath.clamp(Layout.PLOT_BOTTOM-(watts-lo)*(Layout.PLOT_BOTTOM-plotTop())/(hi-lo), plotTop(), Layout.PLOT_BOTTOM-Layout.u(1)));
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
            var c = theme.powerColor(RideMath.zone(watts, powerLimits));
            color(dc, theme.plotFill(c)); dc.fillRectangle(px-Layout.u(1), py, Layout.BUCKET_WIDTH, Layout.PLOT_BOTTOM+1-py);
            color(dc, c);
            if (previousX >= Layout.PLOT_LEFT && previousSegment == p[4] && p[4] >= 0) { dc.drawLine(previousX, previousY, px, py); }
            else { dc.fillRectangle(px-Layout.u(1), py, Layout.BUCKET_WIDTH, Layout.STROKE); }
            previousX = px; previousY = py; previousSegment = p[4];
        }
        var fy = powerY(ftpWatts);
        for (var x = Layout.PLOT_LEFT; x < Layout.PLOT_RIGHT; x += Layout.GUIDE_STEP) {
            color(dc, theme.background); dc.fillRectangle(x-Layout.u(1), fy-Layout.u(1), Layout.GUIDE_HALO_WIDTH, Layout.GUIDE_HALO_HEIGHT);
            color(dc, theme.guide); dc.fillRectangle(x, fy, Layout.GUIDE_DASH, Layout.STROKE);
        }
        var zy = powerY(ftpWatts*0.75);
        color(dc, theme.background); dc.fillRectangle(Layout.PLOT_LEFT, zy-Layout.u(1), Layout.PLOT_FILL_WIDTH, Layout.GUIDE_HALO_HEIGHT);
        color(dc, theme.blue); dc.fillRectangle(Layout.PLOT_LEFT, zy, Layout.PLOT_FILL_WIDTH, Layout.STROKE);
        for (var i = 0; i < trend.boundaries.size(); i += 1) {
            var px = chartX(trend.boundaries[i]);
            if (px < Layout.PLOT_LEFT || px > Layout.PLOT_RIGHT) { continue; }
            color(dc, theme.background); dc.fillRectangle(px-Layout.u(2), plotTop(), Layout.u(4), Layout.PLOT_BOTTOM-plotTop()+1);
            color(dc, theme.ink); dc.fillRectangle(px-Layout.u(1), plotTop(), Layout.STROKE, Layout.PLOT_BOTTOM-plotTop()+1); dc.fillRectangle(px-Layout.u(3), plotTop(), Layout.LAP_CAP_WIDTH, Layout.GUIDE_HALO_HEIGHT);
        }
        color(dc, theme.blue); dc.fillRectangle(Layout.PLOT_RIGHT, plotTop(), Layout.STROKE, Layout.PLOT_BOTTOM-plotTop()+1);
    }
}
