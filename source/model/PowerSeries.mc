// [first elapsed timestamp, last, watt sum, count, contiguous segment].
// Adaptive all-ride buckets compact without discarding the start of the ride.
import Toybox.Lang;
class PowerSeries {
    // Ordinary windows need ~101 buckets; reserve the remainder for gaps.
    const MAX_POINTS = 128;
    var points as Lang.Array<Lang.Array<Lang.Numeric>> = [];
    var bucketMs;
    var initialBucket;
    var windowMs;
    var adaptive;
    function initialize(bucket, window, compact) {
        initialBucket = bucket; windowMs = window; adaptive = compact; reset();
    }
    function reset() { points = []; bucketMs = initialBucket; }
    function prune(t) {
        if (windowMs != null) {
            while (points.size() > 0 && points[0][1] < t-windowMs) { points.remove(points[0]); }
        }
    }
    function add(t, watts, segment) {
        prune(t);
        var p = points.size() > 0 ? points[points.size()-1] : null;
        if (p != null && (p[0]/bucketMs).toNumber() == (t/bucketMs).toNumber() && (adaptive || p[4] == segment)) {
            p[1] = t; p[2] += watts; p[3] += 1;
            if (p[4] != segment) { p[4] = -1; }
        } else { points.add([t, t, watts, 1, segment]); }
        if (adaptive) {
            while (points.size() > MAX_POINTS) { compact(); }
        } else {
            while (points.size() > MAX_POINTS) { points.remove(points[0]); }
        }
    }
    function compact() {
        bucketMs *= 2;
        var merged = [] as Lang.Array<Lang.Array<Lang.Numeric>>;
        for (var i = 0; i < points.size(); i += 1) {
            var p = points[i]; var last = merged.size() > 0 ? merged[merged.size()-1] : null;
            if (last != null && (last[0]/bucketMs).toNumber() == (p[0]/bucketMs).toNumber()) {
                last[1] = p[1]; last[2] += p[2]; last[3] += p[3];
                if (last[4] != p[4]) { last[4] = -1; }
            } else { merged.add([p[0], p[1], p[2], p[3], p[4]]); }
        }
        points = merged;
    }
}
