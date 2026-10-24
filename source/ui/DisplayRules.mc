import Toybox.Math;

// Shared color system; layout geometry is generated from design/layout.json.
module DisplayRules {
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
