import Toybox.Lang;

// Bounded measured history. Stored altitudes are never replaced by GPX data.
class ElevationHistory {
    const MAX_POINTS = 160;
    const SAMPLE_METERS = 5;
    var points as Lang.Array<Lang.Array<Lang.Numeric>> = [];
    var distance = null;
    var altitude = null;
    var segment = 0;
    var needsBreak = true;
    var lastClock = null;

    function initialize() { reset(); }
    function reset() {
        points = []; distance = null; altitude = null;
        segment = 0; needsBreak = true; lastClock = null;
    }
    function breakSample() { needsBreak = true; }

    function update(d, h, recording, clock) {
        if (d != null && points.size() > 0 && d < points[points.size()-1][0]) { reset(); }
        if (lastClock != null && (clock < lastClock || clock-lastClock > 5000)) { needsBreak = true; }
        lastClock = clock;
        distance = d != null && d >= 0 ? d : null; altitude = h;
        if (d == null || d < 0 || h == null) { needsBreak = true; return; }
        if (!recording) { needsBreak = true; return; }
        if (needsBreak) {
            segment += 1; needsBreak = false;
            points.add([d, h, segment]);
        } else {
            var last = points[points.size()-1];
            if (d == last[0]) { last[1] = h; }
            else if (d-last[0] >= SAMPLE_METERS) { points.add([d, h, segment]); }
        }
        while (points.size() > MAX_POINTS) { compact(); }
    }

    function compact() {
        // Remove the least-significant interior triangle, keeping original
        // measured samples and endpoints. Segment IDs prevent bridging gaps,
        // even if many breaks eventually require dropping a segment endpoint.
        var removeIndex = 1;
        var score = 1.0e30;
        for (var i = 1; i < points.size()-1; i += 1) {
            var a = points[i-1]; var b = points[i]; var c = points[i+1];
            if (a[2] != b[2] || b[2] != c[2]) { continue; }
            var area = (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
            if (area < 0) { area = -area; }
            if (area < score) { score = area; removeIndex = i; }
        }
        points.remove(points[removeIndex]);
    }

    // [altitude, segment] at a distance, or null outside observed segments.
    function sample(d) as Lang.Array<Lang.Numeric> or Null {
        if (points.size() == 0 || d < points[0][0]) { return null; }
        var lo = 0; var hi = points.size()-1;
        while (lo < hi) {
            var mid = ((lo+hi)/2).toNumber();
            if (points[mid][0] < d) { lo = mid+1; } else { hi = mid; }
        }
        var b = points[lo];
        if (d == b[0]) {
            while (lo+1 < points.size() && points[lo+1][0] == d) { lo += 1; }
            b = points[lo]; return [b[1], b[2]];
        }
        var a;
        if (d > b[0]) {
            if (needsBreak || distance == null || altitude == null || d > distance) { return null; }
            a = b; b = [distance, altitude, segment];
        } else {
            if (lo == 0) { return null; }
            a = points[lo-1];
        }
        if (a[2] != b[2] || b[0] <= a[0]) { return null; }
        return [a[1]+(b[1]-a[1])*(d-a[0])/(b[0]-a[0]).toFloat(), b[2]];
    }

    // Full observed ride, at least 100 m wide; current point anchors the right.
    function window() as Lang.Array<Lang.Numeric> {
        var end = distance;
        if (end == null || end < 0) { end = points.size() > 0 ? points[points.size()-1][0] : 0.0; }
        var first = points.size() > 0 ? points[0][0] : end;
        var span = end-first;
        if (span < 100) { span = 100.0; }
        var low = altitude; var high = altitude;
        for (var i = 0; i < points.size(); i += 1) {
            var h = points[i][1];
            if (low == null || h < low) { low = h; }
            if (high == null || h > high) { high = h; }
        }
        if (low == null) { low = 0.0; high = 40.0; }
        if (high-low < 40) { var middle = (high+low)/2.0; low = middle-20; high = middle+20; }
        return [end-span, end, low, high];
    }
}
