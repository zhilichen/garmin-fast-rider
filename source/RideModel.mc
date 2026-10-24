import Toybox.Application;
import Toybox.Math;
import Toybox.Lang;
import Toybox.Position;
import Toybox.UserProfile;

module RideMath {
    // Math.min/max are API 6.0.3; Edge 840's simulator exposes 6.0.0.
    function clamp(value, lo, hi) { return value < lo ? lo : (value > hi ? hi : value); }

    function navigationDistance(distance, destination) {
        // A default zero without a named navigation target is not a remaining route.
        return destination != null && destination.length() > 0 && distance != null && distance >= 0 ? distance : null;
    }
    function rideAverage(timer, nativePower, observedPower) {
        // Before a new activity has elapsed, some hosts retain a previous average.
        if (timer == null || timer <= 0) { return null; }
        return nativePower != null && nativePower >= 0 ? nativePower : observedPower;
    }

    // Thresholds are upper bounds, inclusive; missing sensor != zero watts.
    function zone(value, limits as Lang.Array<Lang.Number or Lang.Float>) {
        if (value == null) { return 0; }
        for (var i = 0; i < limits.size(); i += 1) {
            if (value <= limits[i]) { return i + 1; }
        }
        return limits.size() + 1;
    }

    function duration(ms) {
        var sec = (ms / 1000).toNumber();
        var hour = (sec / 3600).toNumber();
        var minute = ((sec % 3600) / 60).toNumber();
        return hour.format("%d") + ":" + minute.format("%02d") + ":" + (sec % 60).format("%02d");
    }

    function gears(front, rear) {
        var f = front != null && front > 0 ? front.format("%d") : "--";
        var r = rear != null && rear > 0 ? rear.format("%d") : "--";
        return f + "/" + r;
    }

    function lapDuration(ms) {
        if (ms == null) { return "--:--"; }
        if (ms >= 3600000) { return duration(ms); }
        var seconds = (ms/1000).toNumber();
        return (seconds/60).toNumber().format("%02d")+":"+(seconds%60).format("%02d");
    }

    function gradeText(value) {
        if (value == null) { return "--"; }
        // Avoid displaying a negative zero after rounding to one decimal.
        if (value > -0.05 && value < 0.05) { value = 0.0; }
        return (value >= 0 ? "+" : "") + value.format("%.1f");
    }

    // Synthetic measured-altitude feed for DEMO only; independent of GPX.
    function demoAltitude(d) { return 180+0.009*d+90*Math.sin(d/1700.0)+14*Math.sin(d/280.0); }
    function demoPower(t) { return 210+95*Math.sin(t/19.0)+40*Math.sin(t/5.0); }

    function courseGrade(distance) {
        distance = clamp(distance, 0, CourseData.LENGTH);
        var a = clamp(distance-15, 0, CourseData.LENGTH);
        var b = clamp(distance+15, 0, CourseData.LENGTH);
        return (elevation(b)-elevation(a))*100.0/(b-a);
    }

    function elevation(distance) {
        var ds = CourseData.DISTANCES;
        var es = CourseData.ELEVATIONS;
        // Called for every chart column: avoid scanning the full course per pixel.
        var lo = 1;
        var hi = ds.size() - 1;
        while (lo < hi) {
            var mid = ((lo + hi) / 2).toNumber();
            if (ds[mid] < distance) { lo = mid + 1; }
            else { hi = mid; }
        }
        var fraction = clamp((distance - ds[lo-1]) / (ds[lo] - ds[lo-1]).toFloat(), 0, 1);
        return es[lo-1] + fraction * (es[lo] - es[lo-1]);
    }
}

// Live grade from measured altitude and traveled distance, not the imported GPX.
// Sample every 5 m; use a >=20 m baseline and smooth successive estimates.
class GradeEstimator {
    var samples as Lang.Array<Lang.Array<Lang.Numeric>> = [];
    var value = null;
    var lastClock = null;
    function initialize() { reset(); }
    function reset() { samples = []; value = null; lastClock = null; }

    function update(distance, altitude, clock) {
        if (distance == null || altitude == null) { reset(); return null; }
        if (lastClock != null && clock < lastClock) { reset(); }
        lastClock = clock;
        if (samples.size() > 0) {
            var last = samples[samples.size()-1];
            if (distance < last[0] || clock-last[2] > 15000) {
                reset(); lastClock = clock;
            } else if (distance-last[0] < 5) {
                return value;
            }
        }
        samples.add([distance, altitude, clock]);
        while (samples.size() > 2 && distance-samples[1][0] >= 20) { samples.remove(samples[0]); }
        var first = samples[0];
        var baseline = distance-first[0];
        if (baseline < 20) { return value; }
        var raw = 100.0*(altitude-first[1])/baseline;
        // Reject discontinuous altitude fixes instead of showing a clamped slope.
        if (raw < -60 || raw > 60) { reset(); return null; }
        value = value == null ? raw : 0.5*value+0.5*raw;
        return value;
    }
}

class CourseTracker {
    var distance = null;
    var state = "GPS --";
    var lastDistance = null;

    function initialize() {}

    // Project GPS onto course segments. Reject fixes >150 m from the course;
    // at crossings prefer a nearby previous course distance.
    function update(location as Position.Location or Null) {
        if (location == null) { distance = null; state = "GPS --"; return; }
        var pos = location.toDegrees();
        var cosLat = Math.cos(pos[0] * Math.PI / 180.0);
        var bestScore = 1.0e20;
        var bestOffset = 1.0e20;
        var bestDistance = 0.0;
        var points = CourseData.POINTS;
        for (var i = 1; i < points.size(); i += 1) {
            var ax = (points[i-1][1] - pos[1]) * cosLat * 111320;
            var ay = (points[i-1][0] - pos[0]) * 111320;
            var bx = (points[i][1] - pos[1]) * cosLat * 111320;
            var by = (points[i][0] - pos[0]) * 111320;
            var dx = bx - ax;
            var dy = by - ay;
            var len = dx*dx + dy*dy;
            var t = len > 0 ? RideMath.clamp(-(ax*dx + ay*dy) / len, 0, 1) : 0;
            var offset = (ax+t*dx)*(ax+t*dx) + (ay+t*dy)*(ay+t*dy);
            var d = CourseData.DISTANCES[i-1] + t*(CourseData.DISTANCES[i]-CourseData.DISTANCES[i-1]);
            var score = offset;
            if (lastDistance != null) {
                var delta = d-lastDistance;
                if (delta < 0) { delta = -delta; }
                score += RideMath.clamp(delta, 0, 10000) * 0.02;
            }
            if (score < bestScore) { bestScore = score; bestOffset = offset; bestDistance = d; }
        }
        if (bestOffset > 22500) { distance = null; state = "OFF COURSE"; return; }
        distance = bestDistance;
        lastDistance = bestDistance;
        state = "ON COURSE";
    }
}
