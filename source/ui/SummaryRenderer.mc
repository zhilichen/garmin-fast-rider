import Toybox.Graphics;
import Toybox.Lang;

// Two-column whole-ride summary, shared by every display profile and theme.
module SummaryRenderer {
    function face(v as FastRiderView, dc, value, faces as Lang.Array<Lang.Number>, available, topRoom) {
        for (var i = 0; i < faces.size(); i += 1) {
            var f = faces[i];
            if (v.packedWidth(value,f) <= available && FontInk.TOP[f] <= topRoom) { return f; }
        }
        return faces[faces.size()-1];
    }
    function room(label, value) {
        return value-label-FontInk.BOTTOM[FontInk.SUMMARY_LABEL]-FontInk.NATIVE_BOTTOM_PAD-Layout.u(2);
    }
    function caption(v as FastRiderView, dc, x, baseline, label) {
        v.text(dc,x,baseline,FontInk.SUMMARY_LABEL,label,v.theme.label,Graphics.TEXT_JUSTIFY_LEFT);
    }
    function rowLabel(row) {
        return row == 1 ? SummaryLayout.ROW_LABEL_1 : (row == 2 ? SummaryLayout.ROW_LABEL_2 :
            (row == 3 ? SummaryLayout.ROW_LABEL_3 : SummaryLayout.ROW_LABEL_4));
    }
    function rowValue(row) {
        return row == 1 ? SummaryLayout.ROW_VALUE_1 : (row == 2 ? SummaryLayout.ROW_VALUE_2 :
            (row == 3 ? SummaryLayout.ROW_VALUE_3 : SummaryLayout.ROW_VALUE_4));
    }
    function value(v as FastRiderView, dc, shown, unit, faces as Lang.Array<Lang.Number>, left, width, row, c) {
        var label = rowLabel(row); var baseline = rowValue(row);
        var uf = unit.equals("ft") ? 12 : FontInk.SUMMARY_LABEL;
        var uw = v.textWidth(dc,unit,uf);
        var f = face(v,dc,shown,faces,width-uw-Layout.STATS_GAP,room(label,baseline));
        var nw = v.packedWidth(shown,f);
        var x = left+DisplayRules.pixel((width-nw-uw-Layout.STATS_GAP)/2.0);
        v.drawPacked(dc,x,baseline,f,shown,c);
        v.text(dc,x+nw+Layout.STATS_GAP,baseline,uf,unit,v.theme.label,Graphics.TEXT_JUSTIFY_LEFT);
    }
    function header(v as FastRiderView, dc) {
        var lf = FontInk.SUMMARY_LABEL;
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.HEADER_LABEL,"Ride time");
        var elapsed = v.millis == null ? "--:--" : RideMath.duration(v.millis);
        var f = face(v,dc,elapsed,FontInk.STATS_FACES,Layout.LEFT_WIDTH,room(SummaryLayout.HEADER_LABEL,SummaryLayout.HEADER_VALUE));
        v.drawPacked(dc,Layout.LEFT_EDGE,SummaryLayout.HEADER_VALUE,f,elapsed,v.theme.ink);
        // The native radar overlay still owns the top-right corner.
        var right = Layout.RADAR_LEFT-Layout.u(2);
        v.text(dc,right,SummaryLayout.HEADER_LABEL,lf,"Time",v.theme.label,Graphics.TEXT_JUSTIFY_RIGHT);
        var clock = v.clockText();
        var suffix = clock.substring(clock.length()-2,clock.length());
        var number = clock.substring(0,clock.length()-3);
        var uw = v.textWidth(dc,suffix,3);
        f = face(v,dc,number,FontInk.STATS_FACES,right-Layout.RIGHT_START-uw-Layout.STATS_GAP,
            room(SummaryLayout.HEADER_LABEL,SummaryLayout.HEADER_VALUE));
        var x = right-uw-Layout.STATS_GAP-v.packedWidth(number,f);
        v.drawPacked(dc,x,SummaryLayout.HEADER_VALUE,f,number,v.theme.ink);
        v.text(dc,right,SummaryLayout.HEADER_VALUE,3,suffix,v.theme.label,Graphics.TEXT_JUSTIFY_RIGHT);
        v.color(dc,v.theme.rule);dc.fillRectangle(Layout.LEFT_EDGE,SummaryLayout.TOP_RULE,Layout.RULE_WIDTH,Layout.STROKE);
    }
    function distance(v as FastRiderView, dc) {
        var parts = v.distancePartsWithin(dc,v.meters,v.remainingDistance,true,Layout.RIGHT_WIDTH,
            room(SummaryLayout.ROW_LABEL_1,SummaryLayout.ROW_VALUE_1));
        var x = Layout.RIGHT_START+DisplayRules.pixel((Layout.RIGHT_WIDTH-v.distanceRowWidth(parts))/2.0);
        v.drawPacked(dc,x,SummaryLayout.ROW_VALUE_1,parts[2],parts[0],v.theme.ink);
        x += v.packedWidth(parts[0],parts[2])+Layout.PACKED_GAP;
        v.drawPacked(dc,x,SummaryLayout.ROW_VALUE_1,12,"mi",v.theme.label);
        x += v.packedWidth("mi",12)+Layout.PACKED_GAP;
        if (parts[1] != null) { v.drawPacked(dc,x,SummaryLayout.ROW_VALUE_1,parts[3],parts[1],v.theme.blue); }
    }
    function draw(v as FastRiderView, dc) {
        header(v,dc);
        v.color(dc,v.theme.rule);dc.fillRectangle(Layout.COLUMN_DIVIDER,SummaryLayout.TOP_RULE+Layout.STROKE,
            Layout.STROKE,SummaryLayout.BANNER_TOP-SummaryLayout.TOP_RULE-Layout.STROKE);
        v.drawHeart(dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_1-Layout.u(12));
        caption(v,dc,Layout.LEFT_EDGE+Layout.HEART_WIDTH+Layout.STATS_GAP,SummaryLayout.ROW_LABEL_1,"HR");
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_2,"Avg HR");
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_3,"Avg power");
        var np = v.normalized.value();
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_4,np != null && v.normalized.estimated ? "NP est." : "NP");
        value(v,dc,v.intText(v.hr),"bpm",FontInk.SUMMARY_INT_FACES,Layout.LEFT_EDGE,Layout.LEFT_WIDTH,
            1,v.theme.zoneColor(RideMath.zone(v.hr,v.hrLimits)));
        value(v,dc,v.intText(v.averageHr),"bpm",FontInk.SUMMARY_INT_FACES,Layout.LEFT_EDGE,Layout.LEFT_WIDTH,
            2,v.theme.zoneColor(RideMath.zone(v.averageHr,v.hrLimits)));
        value(v,dc,v.intText(v.ridePower),"W",FontInk.SUMMARY_INT_FACES,Layout.LEFT_EDGE,Layout.LEFT_WIDTH,
            3,v.theme.ink);
        value(v,dc,v.intText(np),"W",FontInk.SUMMARY_INT_FACES,Layout.LEFT_EDGE,Layout.LEFT_WIDTH,
            4,v.theme.ink);
        caption(v,dc,Layout.RIGHT_START,SummaryLayout.ROW_LABEL_1,"Distance");
        caption(v,dc,Layout.RIGHT_START,SummaryLayout.ROW_LABEL_2,"Ascent");
        caption(v,dc,Layout.RIGHT_START,SummaryLayout.ROW_LABEL_3,"Avg cadence");
        caption(v,dc,Layout.RIGHT_START,SummaryLayout.ROW_LABEL_4,"Avg speed");
        distance(v,dc);
        value(v,dc,RideMath.ascentFeetValue(v.ascent),"ft",FontInk.SUMMARY_INT_FACES,Layout.RIGHT_START,Layout.RIGHT_WIDTH,
            2,v.theme.ink);
        value(v,dc,v.intText(v.averageCadence),"rpm",FontInk.SUMMARY_INT_FACES,Layout.RIGHT_START,Layout.RIGHT_WIDTH,
            3,v.theme.cadenceColor(v.averageCadence));
        value(v,dc,RideMath.speedMphText(v.averageSpeed),"mph",FontInk.STATS_FACES,Layout.RIGHT_START,Layout.RIGHT_WIDTH,
            4,v.theme.ink);
    }
}
