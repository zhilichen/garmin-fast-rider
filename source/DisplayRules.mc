import Toybox.Graphics;
import Toybox.Math;

// Native physical pixels, never CSS points. See docs/edge840-design-rules.md.
module DisplayRules {
    const WIDTH = 246;
    const HEIGHT = 322;
    const GRID = 2;
    const MARGIN = 8;
    const CELL_WIDTH = 108;
    const RIGHT_CELL = 130;
    const STROKE = 2;
    const ZONE_BAR = 4;
    const MARKER_STROKE = 3;
    const MARKER_RADIUS = 6;
    const MARKER_HALO = 8;
    const PLOT_LEFT = 16;
    const PLOT_RIGHT = 228;
    const BANNER_TOP = 184;
    const PLOT_TOP = 264;
    const PLOT_BOTTOM = 302;

    const INK = 0x15212B;
    const LABEL = 0x354550;
    const RULE = 0x83909B;
    const BLUE = 0x005AA8;
    const FUTURE = 0x53616B;
    const DONE_FILL = 0xAACDE7;
    const FUTURE_FILL = 0xD8DFE4;
    const BANNER_FILL = 0xF4F7F9;

    function pixel(value) { return Math.round(value).toNumber(); }

    function zoneColor(zone) {
        // Every text color has >= 4.5:1 sRGB contrast against white.
        var colors = [LABEL, 0x55616A, BLUE, 0x006B3C, 0x8F5B00, 0xB62612, 0x8620A0, 0xA61561];
        return colors[zone < 7 ? zone : 7];
    }
}
