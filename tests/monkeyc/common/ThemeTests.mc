import Toybox.Graphics;
import Toybox.Test;

(:test)
function themeTransitionsTest(logger) {
    var t = new DisplayTheme();
    var colors = [DisplayRules.INK, DisplayRules.LABEL, DisplayRules.GRAY,
        DisplayRules.BLUE, DisplayRules.GREEN, DisplayRules.ORANGE,
        DisplayRules.RED, DisplayRules.PURPLE];
    // Simulate repeated system changes on the same field instance.
    for (var pass = 0; pass < 3; pass += 1) {
        t.setBackground(Graphics.COLOR_BLACK);
        Test.assert(t.night);
        Test.assertEqual(t.background, Graphics.COLOR_BLACK);
        Test.assertEqual(t.marker, Graphics.COLOR_WHITE);
        for (var i = 0; i < colors.size(); i += 1) { Test.assert(t.color(colors[i]) != colors[i]); }
        t.setBackground(Graphics.COLOR_WHITE);
        Test.assert(!t.night);
        Test.assertEqual(t.background, Graphics.COLOR_WHITE);
        Test.assertEqual(t.marker, Graphics.COLOR_BLACK);
        Test.assertEqual(t.ink, DisplayRules.INK);
        Test.assertEqual(t.label, DisplayRules.LABEL);
        Test.assertEqual(t.rule, DisplayRules.RULE);
        for (var i = 0; i < colors.size(); i += 1) { Test.assertEqual(t.color(colors[i]), colors[i]); }
    }
    return true;
}

(:test)
function themeEffortColorsTest(logger) {
    var t = new DisplayTheme();
    for (var mode = 0; mode < 2; mode += 1) {
        t.setBackground(mode == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
        Test.assertEqual(t.powerColor(2), t.blue);
        Test.assertEqual(t.zoneColor(2), t.blue);
        Test.assertEqual(t.powerColor(4), t.zoneColor(4));
        Test.assert(t.powerColor(2) != t.powerColor(4));
        Test.assert(t.powerColor(4) != t.powerColor(5));
        Test.assert(t.powerColor(5) != t.powerColor(6));
        Test.assertEqual(t.powerColor(6), t.powerColor(7));
        Test.assertEqual(t.powerColor(1), t.powerColor(3));
        Test.assertEqual(t.zoneColor(0), t.label);
        Test.assertEqual(t.gradeColor(null), t.label);
        Test.assertEqual(t.cadenceColor(null), t.label);
        Test.assertEqual(t.cadenceColor(70), t.ink);
        Test.assertEqual(t.cadenceColor(100), t.ink);
        Test.assertEqual(t.cadenceColor(69), t.red);
        Test.assertEqual(t.cadenceColor(101), t.powerColor(5));
        Test.assertEqual(t.gradeColor(5), t.ink);
        Test.assertEqual(t.gradeColor(6), t.powerColor(4));
        Test.assertEqual(t.gradeColor(11), t.red);
        Test.assertEqual(t.gradeColor(16), t.powerColor(5));
    }
    return true;
}

(:test)
function themePlotBackdropTest(logger) {
    var t = new DisplayTheme();
    Test.assertEqual(t.plotFill(DisplayRules.BLUE), DisplayRules.fadeWhite(DisplayRules.BLUE));
    t.setBackground(Graphics.COLOR_BLACK);
    Test.assertEqual(t.plotFill(Graphics.COLOR_WHITE), 0xE5E5E5);
    Test.assertEqual(t.plotFill(Graphics.COLOR_BLACK), Graphics.COLOR_BLACK);
    Test.assert(t.plotFill(t.blue) != DisplayRules.fadeWhite(t.blue));
    Test.assert(t.plotFill(t.blue) != t.background);
    t.setBackground(Graphics.COLOR_WHITE);
    Test.assertEqual(t.plotFill(DisplayRules.BLUE), DisplayRules.fadeWhite(DisplayRules.BLUE));
    return true;
}
