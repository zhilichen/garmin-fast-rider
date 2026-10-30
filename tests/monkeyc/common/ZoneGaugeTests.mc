import Toybox.Graphics;
import Toybox.Test;

(:test)
function zoneGaugeGeometryTest(logger) {
    var dc = TestPlatform.dc(16,16); var v = new FastRiderView(); v.loadFonts();
    var widths = [Layout.LEFT_WIDTH,Layout.RIGHT_WIDTH];
    for (var i = 0; i < widths.size(); i += 1) {
        var w = widths[i];
        Test.assertEqual(v.zoneGaugeWidth(w,null),0);
        Test.assertEqual(v.zoneGaugeWidth(w,0.0),0);
        Test.assertEqual(v.zoneGaugeWidth(w,1.0),w);
        Test.assertEqual(v.zoneGaugeWidth(w,-1.0),0);
        Test.assertEqual(v.zoneGaugeWidth(w,2.0),w);
        Test.assertEqual(v.zoneGaugeWidth(w,0.5),DisplayRules.pixel(w/2.0));
        Test.assert(v.zoneGaugeWidth(w,0.25) < v.zoneGaugeWidth(w,0.75));
    }
    var faces = [0,6];
    for (var i = 0; i < faces.size(); i += 1) {
        var f = v.zoneBadgeFont(faces[i]);
        for (var z = 1; z <= 7; z += 1) {
            Test.assert(v.packedWidth(z.format("%d"),f)+2*Layout.ZONE_BADGE_PADDING <= v.zoneBadgeWidth(dc,z,faces[i]));
        }
        var top = Layout.ZONE_BADGE_BOTTOM-FontInk.TOP[f]-FontInk.BOTTOM[f]-FontInk.NATIVE_BOTTOM_PAD-2*Layout.ZONE_BADGE_PADDING;
        Test.assert(top > Layout.PRIMARY_BASELINE-FontInk.TOP[0]);
        Test.assertEqual(v.powerBadgeRight(),Layout.RIGHT_EDGE);
    }
    Test.assert(FontInk.TOP[v.zoneBadgeFont(0)] > FontInk.TOP[5]);
    Test.assert(Layout.ZONE_BADGE_BOTTOM-Layout.ZONE_BADGE_PADDING-FontInk.NATIVE_BOTTOM_PAD > Layout.PRIMARY_BASELINE);
    Test.assert(Layout.ZONE_BADGE_BOTTOM < Layout.ZONE_WEDGE_TOP);
    Test.assert(Layout.ZONE_WEDGE_BOTTOM < Layout.MIDDLE_TOP);
    Test.assert(Layout.ZONE_WEDGE_THIN >= Layout.STROKE*2);
    return true;
}

(:test)
function zoneGaugeRenderStatesTest(logger) {
    var dc = TestPlatform.dc(Layout.WIDTH,Layout.HEIGHT);
    var v = new FastRiderView(); v.loadFonts();
    var positions = [null,0.0,0.25,0.5,0.75,1.0];
    for (var mode = 0; mode < 2; mode += 1) {
        v.theme.setBackground(mode == 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK);
        dc.setColor(v.theme.ink,v.theme.background); dc.clear();
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }
        for (var z = 0; z <= 7; z += 1) {
            v.drawZoneBadge(dc,Layout.LEFT_RIGHT,z,0,v.theme.zoneColor(z));
            v.drawZoneBadge(dc,Layout.RIGHT_EDGE,z,6,v.theme.powerColor(z));
            for (var i = 0; i < positions.size(); i += 1) {
                v.drawZoneGauge(dc,Layout.LEFT_EDGE,Layout.LEFT_WIDTH,positions[i],v.theme.zoneColor(z));
                v.drawZoneGauge(dc,Layout.RIGHT_START,Layout.RIGHT_WIDTH,positions[i],v.theme.powerColor(z));
            }
        }
    }
    return true;
}
