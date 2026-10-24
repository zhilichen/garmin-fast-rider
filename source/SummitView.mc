import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Math;
import Toybox.System;
import Toybox.UserProfile;
import Toybox.WatchUi;

class SummitView extends WatchUi.DataField {
    const INK = 0x172B3A;
    const MUTED = 0x607080;
    const RULE = 0xDDE3E8;
    const BLUE = 0x0077CC;
    var power = null;
    var hr = null;
    var meters = 0.0;
    var millis = 0;
    var powerLimits;
    var hrLimits;
    var tracker;
    var offset = -1;
    var start;
    var width;
    var height;

    function initialize() {
        DataField.initialize();
        tracker = new CourseTracker();
        start = System.getTimer();
        loadSettings();
    }

    function loadSettings() {
        var ftp = RideMath.clamp(Application.Properties.getValue("ftp"), 50, 600);
        var maxHr = RideMath.clamp(Application.Properties.getValue("maxHr"), 100, 240);
        offset = Application.Properties.getValue("courseStart");
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
            var p = (t.toNumber() % 180) / 180.0;
            power = (220 + 135*Math.sin(t/12.0)).toNumber();
            hr = (147 + 28*Math.sin(t/19.0)).toNumber();
            meters = CourseData.LENGTH * (0.37 + 0.25*p);
            millis = 4980000 + (t*1000).toNumber();
            tracker.distance = meters;
            tracker.state = "DEMO";
            return;
        }
        power = info.currentPower;
        hr = info.currentHeartRate;
        if (hr != null && hr <= 0) { hr = null; }
        meters = info.elapsedDistance != null ? info.elapsedDistance : 0.0;
        millis = info.timerTime != null ? info.timerTime : 0;
        tracker.update(info.currentLocation);
        if (tracker.distance == null && offset >= 0) {
            tracker.distance = RideMath.clamp(meters-offset, 0, CourseData.LENGTH);
            tracker.state = "ODO EST.";
        }
    }

    function onTimerReset() {
        tracker = new CourseTracker();
        meters = 0.0;
        millis = 0;
        start = System.getTimer();
    }

    function x(v) { return (v * width / 246.0).toNumber(); }
    function y(v) { return (v * height / 322.0).toNumber(); }
    function color(dc, c) { dc.setColor(c, Graphics.COLOR_TRANSPARENT); }
    function text(dc, xx, yy, font, value, c, align) {
        color(dc, c);
        dc.drawText(x(xx), y(yy), font, value, align);
    }

    function zoneColor(z) {
        var colors = [MUTED, 0x71808A, 0x0077CC, 0x008844, 0xCC8800, 0xDD3300, 0xAA22AA, 0xCC2277];
        return colors[z < 7 ? z : 7];
    }

    function fitFont(dc, value, maxWidth, big) {
        var fonts = big ? [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD, Graphics.FONT_SMALL] : [Graphics.FONT_NUMBER_MILD, Graphics.FONT_GLANCE_NUMBER, Graphics.FONT_SMALL, Graphics.FONT_XTINY];
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(value, fonts[i]) <= maxWidth) { return fonts[i]; }
        }
        return Graphics.FONT_XTINY;
    }

    function metric(dc, left, label, value, unit, z) {
        var c = zoneColor(z);
        text(dc, left+10, 29, Graphics.FONT_XTINY, label, MUTED, Graphics.TEXT_JUSTIFY_LEFT);
        var font = fitFont(dc, value, x(106), true);
        text(dc, left+61, 51, font, value, c, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, left+10, 114, Graphics.FONT_XTINY, unit, MUTED, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, left+111, 114, Graphics.FONT_XTINY, z == 0 ? "--" : "Z"+z, c, Graphics.TEXT_JUSTIFY_RIGHT);
        color(dc, c);
        dc.fillRectangle(x(left+10), y(139), x(103), 3);
    }

    function onUpdate(dc) {
        width = dc.getWidth(); height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); dc.clear();
        if (width < 220 || height < 240) {
            text(dc, 123, 95, Graphics.FONT_SMALL, "SUMMIT", INK, Graphics.TEXT_JUSTIFY_CENTER);
            text(dc, 123, 155, Graphics.FONT_XTINY, "Select 1-field layout", MUTED, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        text(dc, 10, 3, Graphics.FONT_XTINY, "SUMMIT", INK, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 236, 3, Graphics.FONT_XTINY, BuildMode.DEMO ? "DEMO" : "RIDE", BLUE, Graphics.TEXT_JUSTIFY_RIGHT);
        color(dc, RULE); dc.drawLine(0, y(25), width, y(25));
        dc.drawLine(x(123), y(33), x(123), y(134));
        metric(dc, 0, "POWER", power == null ? "--" : power.format("%d"), "W", RideMath.zone(power, powerLimits));
        metric(dc, 123, "HEART RATE", hr == null ? "--" : hr.format("%d"), "bpm", RideMath.zone(hr, hrLimits));
        text(dc, 10, 151, Graphics.FONT_XTINY, "DISTANCE  km", MUTED, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 133, 151, Graphics.FONT_XTINY, "RIDE TIME", MUTED, Graphics.TEXT_JUSTIFY_LEFT);
        var dist = (meters/1000.0).format("%.1f");
        text(dc, 10, 171, fitFont(dc, dist, x(103), false), dist, INK, Graphics.TEXT_JUSTIFY_LEFT);
        var time = RideMath.duration(millis);
        text(dc, 133, 179, fitFont(dc, time, x(103), false), time, INK, Graphics.TEXT_JUSTIFY_LEFT);
        color(dc, RULE); dc.drawLine(0, y(216), width, y(216));
        drawProfile(dc);
    }

    function drawProfile(dc) {
        var d = tracker.distance;
        text(dc, 10, 222, Graphics.FONT_XTINY, CourseData.IS_SAMPLE ? "SAMPLE" : "COURSE", INK, Graphics.TEXT_JUSTIFY_LEFT);
        var summary = d == null ? tracker.state : (100*d/CourseData.LENGTH).format("%.0f") + "%  " + ((CourseData.LENGTH-d)/1000.0).format("%.1f") + " km left";
        if (d != null && tracker.state.equals("ODO EST.")) { summary = "EST " + (100*d/CourseData.LENGTH).format("%.0f") + "%"; }
        text(dc, 236, 222, Graphics.FONT_XTINY, summary, d == null ? MUTED : BLUE, Graphics.TEXT_JUSTIFY_RIGHT);
        var left = x(10); var right = x(236);
        var top = y(249); var bottom = y(297);
        var range = CourseData.HIGH-CourseData.LOW;
        if (range < 40) { range = 40; }
        var marker = d == null ? -1 : left + (right-left)*d/CourseData.LENGTH;
        var prevY = bottom;
        for (var px = left; px <= right; px += 1) {
            var at = (px-left)*CourseData.LENGTH/(right-left).toFloat();
            var py = bottom - 3 - (RideMath.elevation(at)-CourseData.LOW)*(bottom-top-6)/range;
            color(dc, px <= marker ? 0x99CCEE : 0xDDE3E8);
            dc.drawLine(px, py.toNumber(), px, bottom);
            color(dc, px <= marker ? BLUE : 0x84939D);
            if (px > left) { dc.drawLine(px-1, prevY.toNumber(), px, py.toNumber()); }
            prevY = py;
        }
        if (d != null) {
            var markerY = bottom - 3 - (RideMath.elevation(d)-CourseData.LOW)*(bottom-top-6)/range;
            color(dc, BLUE); dc.drawLine(marker.toNumber(), top-1, marker.toNumber(), bottom+2);
            dc.fillCircle(marker.toNumber(), markerY.toNumber(), 5);
            color(dc, Graphics.COLOR_WHITE); dc.fillCircle(marker.toNumber(), markerY.toNumber(), 2);
        }
        text(dc, 10, 301, Graphics.FONT_XTINY, "0", MUTED, Graphics.TEXT_JUSTIFY_LEFT);
        text(dc, 123, 301, Graphics.FONT_XTINY, CourseData.ASCENT.format("%d") + " m up", MUTED, Graphics.TEXT_JUSTIFY_CENTER);
        text(dc, 236, 301, Graphics.FONT_XTINY, (CourseData.LENGTH/1000.0).format("%.1f") + " km", MUTED, Graphics.TEXT_JUSTIFY_RIGHT);
    }
}
