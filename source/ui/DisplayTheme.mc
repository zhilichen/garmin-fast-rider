import Toybox.Graphics;

// Follow Garmin's DataField background, including automatic day/night changes.
// Keep zone classification in DisplayRules; only the displayed palette changes.
class DisplayTheme {
    // These anchors survive the 64-color RGB cube on older MIP Edge displays.
    const NIGHT_INK = 0xFFFFFF;
    const NIGHT_LABEL = 0xCCCCCC;
    const NIGHT_RULE = 0xAAAAAA;
    const NIGHT_GRAY = 0xAAAAAA;
    const NIGHT_BLUE = 0x55AAFF;
    const NIGHT_GREEN = 0x55FF55;
    const NIGHT_ORANGE = 0xFFAA00;
    const NIGHT_RED = 0xFF5555;
    const NIGHT_PURPLE = 0xAA55FF;
    var background = Graphics.COLOR_WHITE;
    var ink = DisplayRules.INK;
    var label = DisplayRules.LABEL;
    var rule = DisplayRules.RULE;
    var blue = DisplayRules.BLUE;
    var red = DisplayRules.RED;
    var guide = 0x59636E;
    var marker = Graphics.COLOR_BLACK;
    var night = false;

    function initialize() {}

    function setBackground(value) {
        var dark = value == Graphics.COLOR_BLACK;
        if (dark == night) { return; }
        night = dark;
        background = night ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        ink = night ? NIGHT_INK : DisplayRules.INK;
        label = night ? NIGHT_LABEL : DisplayRules.LABEL;
        rule = night ? NIGHT_RULE : DisplayRules.RULE;
        blue = night ? NIGHT_BLUE : DisplayRules.BLUE;
        red = night ? NIGHT_RED : DisplayRules.RED;
        guide = night ? NIGHT_LABEL : 0x59636E;
        marker = night ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }

    function color(dayColor) {
        if (!night) { return dayColor; }
        if (dayColor == DisplayRules.INK) { return ink; }
        if (dayColor == DisplayRules.LABEL) { return label; }
        if (dayColor == DisplayRules.GRAY) { return NIGHT_GRAY; }
        if (dayColor == DisplayRules.BLUE) { return blue; }
        if (dayColor == DisplayRules.GREEN) { return NIGHT_GREEN; }
        if (dayColor == DisplayRules.ORANGE) { return NIGHT_ORANGE; }
        if (dayColor == DisplayRules.RED) { return red; }
        if (dayColor == DisplayRules.PURPLE) { return NIGHT_PURPLE; }
        return dayColor;
    }

    function zoneColor(zone) { return color(DisplayRules.zoneColor(zone)); }
    function powerColor(zone) { return color(DisplayRules.powerColor(zone)); }
    function gradeColor(value) { return color(DisplayRules.gradeColor(value)); }
    function cadenceColor(value) { return color(DisplayRules.cadenceColor(value)); }

    function plotFill(c) {
        if (!night) { return DisplayRules.fadeWhite(c); }
        // Match the day graph's 90% opacity, blended against its actual backdrop.
        var r = ((((c >> 16)&255)*9)/10).toNumber();
        var g = ((((c >> 8)&255)*9)/10).toNumber();
        var b = (((c&255)*9)/10).toNumber();
        return (r << 16)|(g << 8)|b;
    }
}
