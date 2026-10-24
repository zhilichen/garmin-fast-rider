import Toybox.Graphics;
import Toybox.Math;

// Approved v46 design: native Edge 840 physical pixels, baseline text positions.
module DisplayRules {
    const WIDTH = 246;
    const HEIGHT = 322;
    const MARGIN = 2;
    const STROKE = 2;
    const COLUMN_DIVIDER = 112;
    const RIGHT_START = 116;
    const RIGHT_EDGE = 244;
    const LEFT_EDGE = 2;
    const LEFT_RIGHT = 110;
    const LEFT_WIDTH = 108;
    const RIGHT_WIDTH = 128;
    const RIGHT_TAP_LEFT = COLUMN_DIVIDER+STROKE;
    const LIVE_LEFT_CENTER = 26;
    const LIVE_RIGHT_CENTER = 81;
    const LIVE_LEFT_WIDTH = 48;
    const LIVE_RIGHT_WIDTH = 58;
    // Keep the existing font-selection thresholds: moving columns changes
    // spacing, not the type sizes selected for the same displayed values.
    const STATS_VALUE_WIDTH = 118;
    const RADAR_LEFT = 218;
    const RADAR_BOTTOM = 34;
    // First atlas row quantizes transparent on Edge 840; visible ink starts y2.
    const PRIMARY_BASELINE = 43;
    const ZONE_BASELINE = 66;
    const PRIMARY_BOTTOM = 90;
    const MIDDLE_TOP = 91;
    const UNIT_BASELINE = 62;
    const ZONE_BADGE_WIDTH = 31;
    const ZONE_SMALL_BADGE_WIDTH = 20;
    const ZONE_BAR_TOP = 76;
    const ZONE_BAR = 6;
    const ZONE_MARKER_WIDTH = 4;
    const ZONE_MARKER_HEIGHT = 22;
    const PLOT_LEFT = 4;
    const PLOT_RIGHT = 242;
    const BANNER_TOP = 220;
    const PLOT_TOP = 243;
    const PLOT_BOTTOM = 319;
    const INK = 0x15212B;
    const LABEL = 0x354550;
    const RULE = 0x83909B;
    // Fully saturated chromatic anchors; neutral gray stays achromatic.
    // Share anchors across text, bars and plots so zones never change hue.
    const GRAY = 0x555555;
    const BLUE = 0x004CFF;
    const GREEN = 0x008A20;
    const ORANGE = 0xD05A00;
    const RED = 0xD00020;
    const PURPLE = 0x8000D8;
    const BANNER_FILL = 0xFFFFFF;
    const DEEP_RED = RED;
    const DEEP_PURPLE = PURPLE;

    function pixel(value) { return Math.round(value).toNumber(); }
    function zoneColor(zone) {
        var colors = [LABEL, GRAY, BLUE, GREEN, ORANGE, RED];
        return colors[RideMath.clamp(zone, 0, 5)];
    }
    function powerColor(zone) {
        if (zone == 2) { return BLUE; }
        if (zone == 4) { return ORANGE; }
        if (zone == 5) { return PURPLE; }
        if (zone >= 6) { return RED; }
        return GRAY;
    }
    function plotColor(zone) {
        return powerColor(zone);
    }
    function fadeWhite(c) {
        // 90% opaque; white underlays preserve FTP/Z2/lap guide visibility.
        var r = ((((c >> 16)&255)*9+255)/10).toNumber();
        var g = ((((c >> 8)&255)*9+255)/10).toNumber();
        var b = (((c&255)*9+255)/10).toNumber();
        return (r << 16)|(g << 8)|b;
    }
    function gradeColor(value) {
        if (value == null) { return LABEL; }
        if (value > 15) { return DEEP_PURPLE; }
        if (value > 10) { return DEEP_RED; }
        if (value > 5) { return ORANGE; }
        return INK;
    }
    function cadenceColor(value) {
        if (value == null) { return LABEL; }
        if (value < 70) { return DEEP_RED; }
        if (value > 100) { return DEEP_PURPLE; }
        return INK;
    }
}
