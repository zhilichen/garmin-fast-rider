import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.UserProfile;
import Toybox.WatchUi;

class SummitView extends WatchUi.DataField {
    var power = null;
    var hr = null;
    var cadence = null;
    var gear = "--/--";
    var lap;
    var lapMillis = null;
    var lapPower = null;
    var lapSynced = false;
    var grade = null;
    var gradeEstimator;
    var meters = 0.0;
    var millis = 0;
    var powerLimits;
    var hrLimits;
    var history as ElevationHistory = new ElevationHistory();
    var demoSeeded = false;
    var start;
    var width;
    var height;

    function initialize() {
        DataField.initialize();
        gradeEstimator = new GradeEstimator();
        lap = new LapStats();
        start = System.getTimer();
        loadSettings();
    }

    function loadSettings() {
        var ftp = RideMath.clamp(Application.Properties.getValue("ftp"), 50, 600);
        var maxHr = RideMath.clamp(Application.Properties.getValue("maxHr"), 100, 240);
        powerLimits = [ftp*0.55, ftp*0.75, ftp*0.90, ftp*1.05, ftp*1.20, ftp*1.50];
        hrLimits = [maxHr*0.60, maxHr*0.70, maxHr*0.80, maxHr*0.90];
        if (!BuildMode.DEMO) {
            var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
            if (zones != null && zones.size() == 6 && zones[1] > 0) {
                hrLimits = [zones[1], zones[2], zones[3], zones[4]];
            }
            // Newer Edge firmware exposes FTP; guard for older devices/firmware.
            if (UserProfile has :getFunctionalThresholdPower) {
                var deviceFtp = UserProfile.getFunctionalThresholdPower(Activity.SPORT_CYCLING);
                if (deviceFtp != null && deviceFtp > 0) {
                    powerLimits = [deviceFtp*0.55, deviceFtp*0.75, deviceFtp*0.90, deviceFtp*1.05, deviceFtp*1.20, deviceFtp*1.50];
                }
            }
        }
    }

    function compute(info) {
        if (BuildMode.DEMO) {
            var t = (System.getTimer() - start) / 1000.0;
            power = (220 + 135*Math.sin(t/12.0)).toNumber();
            hr = (147 + 28*Math.sin(t/19.0)).toNumber();
            cadence = (90 + 7*Math.sin(t/11.0)).toNumber();
            gear = RideMath.gears(2, 5+((t.toNumber()/15).toNumber()%7));
            meters = 16600.0+t*8.0;
            millis = 4980000 + (t*1000).toNumber();
            lapMillis = (312000+(t*1000).toNumber())%360000;
            lapPower = (243+8*Math.sin(t/25.0)).toNumber();
            lapSynced = true;
            var now = System.getTimer();
            if (!demoSeeded) {
                for (var i = 0; i < 160; i += 1) {
                    var d = 16600.0*i/159;
                    history.update(d, RideMath.demoAltitude(d), true, now-(159-i)*1000);
                }
                demoSeeded = true;
            }
            history.update(meters, RideMath.demoAltitude(meters), true, now);
            grade = 5*(RideMath.demoAltitude(meters+10)-RideMath.demoAltitude(meters-10));
            return;
        }
        power = info.currentPower;
        hr = info.currentHeartRate;
        if (hr != null && hr <= 0) { hr = null; }
        cadence = info.currentCadence;
        if (cadence != null && cadence < 0) { cadence = null; }
        gear = RideMath.gears(info.frontDerailleurIndex, info.rearDerailleurIndex);
        meters = info.elapsedDistance;
        millis = info.elapsedTime;
        lap.update(info.timerTime, power, info.timerState == Activity.TIMER_STATE_ON);
        lapMillis = lap.timeMs; lapPower = lap.averagePower; lapSynced = lap.synced;
        grade = gradeEstimator.update(info.elapsedDistance, info.altitude, System.getTimer());
        history.update(info.elapsedDistance, info.altitude, info.timerState == Activity.TIMER_STATE_ON, System.getTimer());
    }

    function onTimerReset() {
        history.reset(); demoSeeded = false;
        gradeEstimator.reset();
        grade = null;
        lap.reset(); lapMillis = null; lapPower = null; lapSynced = false;
        meters = 0.0;
        millis = 0;
        start = System.getTimer();
    }

    function onTimerStart() { lap.started(Activity.getActivityInfo().timerTime); }
    function onTimerPause() { lap.breakSample(); history.breakSample(); }
    function onTimerResume() { lap.breakSample(); history.breakSample(); }
    function onTimerStop() { lap.breakSample(); history.breakSample(); }

    function onTimerLap() {
        var info = Activity.getActivityInfo();
        lap.begin(info.timerTime, info.currentPower);
        lapMillis = lap.timeMs; lapPower = lap.averagePower; lapSynced = lap.synced;
        WatchUi.requestUpdate();
    }

    function onTimerLap2(trigger) {
        onTimerLap();
        // Prevent the SDK's fallback onTimerLap from resetting the same lap twice.
        return true;
    }

    function color(dc, c) { dc.setColor(c, Graphics.COLOR_TRANSPARENT); }
    function text(dc, xx, yy, font, value, c, align) {
        color(dc, c);
        dc.drawText(xx, yy, font, value, align);
    }

    function fitFont(dc, value, maxWidth, big) {
        // Never shrink a ride metric into a caption font to make it fit.
        var fonts = big ? [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM] : [Graphics.FONT_NUMBER_MILD];
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(value, fonts[i]) <= maxWidth) { return fonts[i]; }
        }
        return null;
    }

    function number(dc, left, top, value, c, big) {
        var font = fitFont(dc, value, DisplayRules.CELL_WIDTH, big);
        if (font == null) { value = "--"; font = big ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_MILD; }
        text(dc, left+54, top, font, value, c, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function metric(dc, left, label, value, unit, z) {
        var c = DisplayRules.zoneColor(z);
        text(dc, left, 8, Graphics.FONT_MEDIUM, label, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        number(dc, left, 32, value, c, true);
        text(dc, left, 92, Graphics.FONT_SMALL, unit, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, left+108, 90, Graphics.FONT_MEDIUM, z == 0 ? "--" : "Z"+z, c, Graphics.TEXT_JUSTIFY_RIGHT);
        color(dc, c);
        dc.fillRectangle(left, 116, DisplayRules.CELL_WIDTH, DisplayRules.ZONE_BAR);
    }

    function onUpdate(dc) {
        width = dc.getWidth(); height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        dc.setPenWidth(DisplayRules.STROKE);
        if (dc has :setAntiAlias) { dc.setAntiAlias(false); }
        if (width != DisplayRules.WIDTH || height != DisplayRules.HEIGHT) {
            text(dc, width/2, height/2-20, Graphics.FONT_SMALL, "SUMMIT", DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
            text(dc, width/2, height/2+4, Graphics.FONT_SMALL, "1 field", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        color(dc, DisplayRules.RULE); dc.fillRectangle(122, 8, DisplayRules.STROKE, 104);
        metric(dc, 8, "HEART RATE", hr == null ? "--" : hr.format("%d"), "bpm", RideMath.zone(hr, hrLimits));
        metric(dc, 130, "PWR", power == null ? "--" : power.format("%d"), "W", RideMath.zone(power, powerLimits));
        var badge = BuildMode.DEMO ? "DEMO" : (history.distance == null ? "DIST --" : (history.altitude == null ? "ALT --" : ""));
        text(dc, 238, BuildMode.DEMO ? 10 : 8, BuildMode.DEMO ? Graphics.FONT_SMALL : Graphics.FONT_MEDIUM, badge, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, 8, 124, Graphics.FONT_MEDIUM, "CADENCE", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 116, 126, Graphics.FONT_SMALL, gear, DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_RIGHT);
        text(dc, 46, 144, Graphics.FONT_NUMBER_MEDIUM, cadence == null ? "--" : cadence.format("%d"), DisplayRules.INK, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 86, 160, Graphics.FONT_SMALL, "rpm", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        color(dc, DisplayRules.RULE); dc.fillRectangle(122, 124, DisplayRules.STROKE, 54);
        drawLap(dc);
        color(dc, DisplayRules.BANNER_FILL); dc.fillRectangle(0, DisplayRules.BANNER_TOP, width, height-DisplayRules.BANNER_TOP);
        color(dc, DisplayRules.RULE); dc.fillRectangle(8, DisplayRules.BANNER_TOP, 230, DisplayRules.STROKE);
        drawBannerStats(dc);
        drawProfile(dc);
    }

    function drawLap(dc) {
        if (lapSynced) {
            text(dc, 130, 124, Graphics.FONT_SMALL, "LAP", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
            text(dc, 238, 124, Graphics.FONT_MEDIUM, RideMath.lapDuration(lapMillis), DisplayRules.INK, Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            text(dc, 130, 124, Graphics.FONT_MEDIUM, "LAP SYNC", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        }
        var average = lapPower == null ? "--" : Math.round(lapPower).toNumber().format("%d");
        var maxNumber = 108-dc.getTextWidthInPixels("~AVG W", Graphics.FONT_SMALL)-4;
        if (dc.getTextWidthInPixels(average, Graphics.FONT_NUMBER_MILD) <= maxNumber) {
            text(dc, 130, 146, Graphics.FONT_NUMBER_MILD, average, DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
            text(dc, 238, 158, Graphics.FONT_SMALL, "~AVG W", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_RIGHT);
        } else {
            text(dc, 130, 152, Graphics.FONT_MEDIUM, "~AVG "+average+" W", DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    function drawBannerStats(dc) {
        text(dc, 8, 192, Graphics.FONT_MEDIUM, "~GRADE %", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        var slope = RideMath.gradeText(grade);
        var font = fitFont(dc, slope, 84, false);
        text(dc, 8, 214, font == null ? Graphics.FONT_MEDIUM : font, slope, DisplayRules.INK, Graphics.TEXT_JUSTIFY_LEFT);
        var dist = meters == null ? "-- km" : (meters/1000.0).format("%.1f")+" km";
        if (dc.getTextWidthInPixels(dist, Graphics.FONT_MEDIUM) > 144) {
            dist = (meters/1000.0).format("%.0f")+" km";
        }
        text(dc, 238, 192, Graphics.FONT_MEDIUM, dist, DisplayRules.INK, Graphics.TEXT_JUSTIFY_RIGHT);
        var time = millis == null ? "--" : RideMath.duration(millis);
        text(dc, 98, 218, Graphics.FONT_SMALL, "TIME", DisplayRules.LABEL, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 238, 216, Graphics.FONT_MEDIUM, time, DisplayRules.INK, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    function drawProfile(dc) {
        var left = DisplayRules.PLOT_LEFT; var right = DisplayRules.PLOT_RIGHT;
        var top = DisplayRules.PLOT_TOP; var bottom = DisplayRules.PLOT_BOTTOM;
        var bounds = history.window();
        var startD = bounds[0]; var endD = bounds[1];
        var low = bounds[2]; var range = bounds[3]-low;
        var ys = [];
        var segments = [];
        // Only interpolate measured segments. Missing readings create gaps.
        for (var px = left; px <= right; px += 1) {
            var d = startD+(endD-startD)*(px-left)/(right-left).toFloat();
            var sample = history.sample(d);
            if (sample == null) { ys.add(null); segments.add(null); continue; }
            var py = DisplayRules.pixel(bottom-8-(sample[0]-low)*(bottom-top-16)/range);
            ys.add(py); segments.add(sample[1]);
            color(dc, DisplayRules.DONE_FILL); dc.fillRectangle(px, py, 1, bottom-py+1);
        }
        dc.setPenWidth(DisplayRules.STROKE);
        color(dc, DisplayRules.BLUE);
        for (var px = left+1; px <= right; px += 1) {
            var i = px-left;
            if (ys[i-1] != null && ys[i] != null && segments[i-1] == segments[i]) {
                dc.drawLine(px-1, ys[i-1], px, ys[i]);
            }
        }
        if (history.distance != null && history.altitude != null) {
            var markerY = DisplayRules.pixel(bottom-8-(history.altitude-low)*(bottom-top-16)/range);
            color(dc, DisplayRules.BLUE); dc.fillRectangle(right-1, top, DisplayRules.MARKER_STROKE, bottom-top+1);
            color(dc, Graphics.COLOR_WHITE); dc.fillCircle(right, markerY, DisplayRules.MARKER_HALO);
            color(dc, DisplayRules.BLUE); dc.fillCircle(right, markerY, DisplayRules.MARKER_RADIUS);
            color(dc, Graphics.COLOR_WHITE); dc.fillCircle(right, markerY, 2);
        }
    }
}
