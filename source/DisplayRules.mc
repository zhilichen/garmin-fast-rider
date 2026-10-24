import Toybox.Graphics;
import Toybox.Math;

// Approved v46 design: native Edge 840 physical pixels, baseline text positions.
module DisplayRules {
    const WIDTH = 246;
    const HEIGHT = 322;
    const MARGIN = 8;
    const CELL_WIDTH = 108;
    const STROKE = 2;
    const COLUMN_DIVIDER = 122;
    const ZONE_BAR = 6;
    const ZONE_MARKER_WIDTH = 3;
    const ZONE_MARKER_HEIGHT = 10;
    const PLOT_LEFT = 16;
    const PLOT_RIGHT = 228;
    const BANNER_TOP = 220;
    const PLOT_TOP = 243;
    const PLOT_BOTTOM = 293;
    const INK = 0x15212B;
    const LABEL = 0x354550;
    const RULE = 0x83909B;
    const BLUE = 0x005AA8;
    const BANNER_FILL = 0xFFFFFF;
    const DEEP_RED = 0x991B1B;
    const DEEP_PURPLE = 0x581C87;
    const ORANGE = 0xB45309;

    function pixel(value) { return Math.round(value).toNumber(); }
    function zoneColor(zone) {
        var colors = [LABEL, 0x55616A, BLUE, 0x006B3C, 0x8F5B00, 0xB62612];
        return colors[RideMath.clamp(zone, 0, 5)];
    }
    function powerColor(zone) {
        if (zone == 2) { return BLUE; }
        if (zone == 4) { return ORANGE; }
        if (zone == 5) { return 0x6B2FA0; }
        if (zone >= 6) { return 0xB62612; }
        return 0x55616A;
    }
    function plotColor(zone) {
        if (zone == 2) { return 0x0075C9; }
        if (zone == 4) { return 0xE26A18; }
        if (zone == 5) { return 0x7B3FC6; }
        if (zone >= 6) { return 0xDC322F; }
        return 0x7D8794;
    }
    function fadeWhite(c) {
        // 80% opaque over the fixed white page; also works on non-alpha Dc.
        var r = (((c >> 16)&255)*0.8+51).toNumber();
        var g = (((c >> 8)&255)*0.8+51).toNumber();
        var b = ((c&255)*0.8+51).toNumber();
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
