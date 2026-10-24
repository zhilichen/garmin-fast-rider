import Toybox.Application;
import Toybox.Math;
import Toybox.Lang;
import Toybox.Position;
import Toybox.UserProfile;

module RideMath {
    // Math.min/max are API 6.0.3; Edge 840's simulator exposes 6.0.0.
    function clamp(value, lo, hi) { return value < lo ? lo : (value > hi ? hi : value); }

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
