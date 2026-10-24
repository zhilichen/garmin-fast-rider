import Toybox.Math;
import Toybox.Lang;

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

    // Position within the original numbered zone, independent of color grouping.
    function zoneFraction(value, limits as Lang.Array<Lang.Number or Lang.Float>, minimum, maximum) {
        var z = zone(value, limits);
        if (z == 0) { return null; }
        var low = z == 1 ? minimum : limits[z-2];
        var high = z <= limits.size() ? limits[z-1] : maximum;
        // Power Z7 has no finite upper bound; indicate overflow at the right edge.
        if (high == null) { return 1.0; }
        if (high <= low) { return null; }
        return clamp((value-low)/(high-low).toFloat(), 0.0, 1.0);
    }

    function ascentFeetValue(meters) {
        return meters == null || meters < 0 ? "--" : Math.round(meters*3.280839895).toNumber().format("%d");
    }
    function ascentFeetText(meters) { return ascentFeetValue(meters)+" ft"; }
    function remainingMilesText(meters, decimals) {
        if (meters == null || meters < 0) { return null; }
        var value = (meters/1609.344).format(decimals == 1 ? "%.1f" : "%.0f");
        var zero = value.equals("0.0") || value.equals("0");
        return "("+(zero ? "" : "-")+value+")";
    }
    function speedMphText(metersPerSecond) {
        return metersPerSecond == null || metersPerSecond < 0 ? "--" : (metersPerSecond*2.236936292).format("%.1f");
    }
    function clock12(hour, minute) {
        var h = hour%12; if (h == 0) { h = 12; }
        return h.format("%d")+":"+minute.format("%02d")+(hour < 12 ? " AM" : " PM");
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
