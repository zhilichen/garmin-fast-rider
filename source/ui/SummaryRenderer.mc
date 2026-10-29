import Toybox.Graphics;
import Toybox.Lang;

// One shared paused/stopped layout across all display profiles and both themes.
module SummaryRenderer {
    function face(v as FastRiderView, dc, value, faces as Lang.Array<Lang.Number>, available, topRoom) {
        for (var i = 0; i < faces.size(); i += 1) {
            var f = faces[i];
            if (v.statsWidth(dc, value, f) <= available && FontInk.TOP[f] <= topRoom) { return f; }
        }
        return faces[faces.size()-1];
    }
    function room(label, value) {
        return value-label-FontInk.BOTTOM[3]-FontInk.NATIVE_BOTTOM_PAD-Layout.u(3);
    }
    function number(v as FastRiderView, dc, value, faces as Lang.Array<Lang.Number>, center, baseline, available, topRoom) {
        var f = face(v, dc, value, faces, available, topRoom);
        var x = center-DisplayRules.pixel(v.statsWidth(dc, value, f)/2.0);
        v.drawStatsNumber(dc, x, baseline, f, value, Graphics.TEXT_JUSTIFY_LEFT);
    }
    function draw(v as FastRiderView, dc) {
        var t = v.theme;
        var hr = v.intText(v.hr); var average = v.intText(v.averageHr);
        var hrFace = 5;
        v.drawHeart(dc, Layout.LEFT_EDGE, SummaryLayout.HEART_BASELINE-Layout.u(14));
        v.drawPacked(dc, Layout.LEFT_EDGE+Layout.HEART_WIDTH+Layout.u(6), SummaryLayout.HEART_BASELINE, hrFace, hr, t.zoneColor(RideMath.zone(v.hr, v.hrLimits)));
        // Keep the native radar icon's top-right area clear in this view too.
        var right = Layout.RADAR_LEFT-Layout.u(2);
        var digits = v.packedWidth(average, hrFace);
        var x = right-digits-v.textWidth(dc, "avg", 3)-Layout.u(5);
        v.text(dc, x, SummaryLayout.HEART_BASELINE, 3, "avg", t.label, Graphics.TEXT_JUSTIFY_LEFT);
        v.drawPacked(dc, right-digits, SummaryLayout.HEART_BASELINE, hrFace, average, t.zoneColor(RideMath.zone(v.averageHr, v.hrLimits)));
        v.color(dc, t.rule); dc.fillRectangle(Layout.LEFT_EDGE, SummaryLayout.TOP_RULE, Layout.RULE_WIDTH, Layout.STROKE);

        v.text(dc, Layout.LEFT_EDGE, SummaryLayout.ELAPSED_LABEL, 3, "Total time", t.label, Graphics.TEXT_JUSTIFY_LEFT);
        var elapsed = v.millis == null ? "--:--" : RideMath.duration(v.millis);
        number(v, dc, elapsed, FontInk.STATS_FACES, Layout.WIDTH/2, SummaryLayout.ELAPSED_VALUE,
            Layout.RULE_WIDTH, room(SummaryLayout.ELAPSED_LABEL, SummaryLayout.ELAPSED_VALUE));

        v.text(dc, Layout.LEFT_EDGE, SummaryLayout.DISTANCE_LABEL, 3, "Distance", t.label, Graphics.TEXT_JUSTIFY_LEFT);
        var parts = v.distancePartsWithin(dc, v.meters, v.remainingDistance, true, Layout.RULE_WIDTH,
            room(SummaryLayout.DISTANCE_LABEL, SummaryLayout.DISTANCE_VALUE));
        x = Layout.WIDTH/2-DisplayRules.pixel(v.distanceRowWidth(parts)/2.0);
        v.drawPacked(dc, x, SummaryLayout.DISTANCE_VALUE, parts[2], parts[0], t.ink);
        x += v.packedWidth(parts[0], parts[2])+Layout.PACKED_GAP;
        v.drawPacked(dc, x, SummaryLayout.DISTANCE_VALUE, 12, "mi", t.label);
        x += v.packedWidth("mi", 12)+Layout.PACKED_GAP;
        if (parts[1] != null) { v.drawPacked(dc, x, SummaryLayout.DISTANCE_VALUE, parts[3], parts[1], t.blue); }

        var np = v.normalized.value();
        var available = Layout.WIDTH/2-Layout.u(8);
        var topRoom = room(SummaryLayout.POWER_LABEL, SummaryLayout.POWER_VALUE);
        v.text(dc, Layout.WIDTH/4, SummaryLayout.POWER_LABEL, 3, "Avg W", t.label, Graphics.TEXT_JUSTIFY_CENTER);
        v.text(dc, Layout.WIDTH*3/4, SummaryLayout.POWER_LABEL, 3,
            np != null && v.normalized.estimated ? "NP est. W" : "NP W", t.label, Graphics.TEXT_JUSTIFY_CENTER);
        number(v, dc, v.intText(v.ridePower), FontInk.AVERAGE_FACES, Layout.WIDTH/4,
            SummaryLayout.POWER_VALUE, available, topRoom);
        number(v, dc, v.intText(np), FontInk.AVERAGE_FACES, Layout.WIDTH*3/4,
            SummaryLayout.POWER_VALUE, available, topRoom);
    }
}
