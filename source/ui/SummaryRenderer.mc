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
    function unitWidth(v as FastRiderView, dc, unit) {
        return Layout.STATS_GAP+v.textWidth(dc,unit,FontInk.SUMMARY_LABEL);
    }
    function unitBaseline(face, row) {
        // Align ink bottoms and keep descenders clear of the following caption.
        return rowValue(row)+FontInk.BOTTOM[face]-FontInk.BOTTOM[FontInk.SUMMARY_LABEL];
    }
    // [numeric face, complete value/unit width, unit baseline]
    function valueParts(v as FastRiderView, dc, shown, unit, width, row) as Lang.Array {
        var baseline = rowValue(row);
        var faces = FontInk.SUMMARY_INT_VALUE_FACES;
        for (var i = 0; i < shown.length(); i += 1) {
            if (shown.substring(i,i+1).equals(".")) { faces = FontInk.SUMMARY_VALUE_FACES; break; }
        }
        var suffix = unitWidth(v,dc,unit);
        var f = face(v,dc,shown,faces,width-suffix,room(rowLabel(row),baseline));
        return [f,v.packedWidth(shown,f)+suffix,unitBaseline(f,row)];
    }
    function value(v as FastRiderView, dc, shown, unit, left, width, row, c) {
        var p = valueParts(v,dc,shown,unit,width,row);
        var x = left+DisplayRules.pixel((width-p[1])/2.0);
        v.drawPacked(dc,x,rowValue(row),p[0],shown,c);
        v.text(dc,x+v.packedWidth(shown,p[0])+Layout.STATS_GAP,p[2],
            FontInk.SUMMARY_LABEL,unit,v.theme.label,Graphics.TEXT_JUSTIFY_LEFT);
    }
    function header(v as FastRiderView, dc) {
        var elapsed = v.millis == null ? "--:--" : RideMath.duration(v.millis);
        var f = face(v,dc,elapsed,FontInk.STATS_FACES,Layout.LEFT_WIDTH,SummaryLayout.HEADER_VALUE-Layout.u(2));
        v.drawPacked(dc,Layout.LEFT_EDGE,SummaryLayout.HEADER_VALUE,f,elapsed,v.theme.ink);
        var right = Layout.RIGHT_EDGE;
        var clock = v.clockText();
        var suffix = clock.substring(clock.length()-2,clock.length());
        var number = clock.substring(0,clock.length()-3);
        var uw = v.textWidth(dc,suffix,3);
        f = face(v,dc,number,FontInk.STATS_FACES,right-Layout.RIGHT_START-uw-Layout.STATS_GAP,
            SummaryLayout.HEADER_VALUE-Layout.u(2));
        var x = right-uw-Layout.STATS_GAP-v.packedWidth(number,f);
        v.drawPacked(dc,x,SummaryLayout.HEADER_VALUE,f,number,v.theme.ink);
        v.text(dc,right,SummaryLayout.HEADER_VALUE,3,suffix,v.theme.label,Graphics.TEXT_JUSTIFY_RIGHT);
        v.color(dc,v.theme.rule);dc.fillRectangle(Layout.LEFT_EDGE,SummaryLayout.TOP_RULE,Layout.RULE_WIDTH,Layout.STROKE);
    }
    function distanceParts(v as FastRiderView, dc) as Lang.Array {
        return v.distancePartsUsing(dc,v.meters,v.remainingDistance,true,
            SummaryLayout.RIGHT_WIDTH-unitWidth(v,dc,"mi"),
            room(SummaryLayout.ROW_LABEL_1,SummaryLayout.ROW_VALUE_1),FontInk.SUMMARY_DISTANCE_PAIRS,false);
    }
    function distance(v as FastRiderView, dc) {
        var parts = distanceParts(v,dc);
        var width = v.distanceRowWidthFor(parts,false)+unitWidth(v,dc,"mi");
        var x = SummaryLayout.RIGHT_START+DisplayRules.pixel((SummaryLayout.RIGHT_WIDTH-width)/2.0);
        v.drawPacked(dc,x,SummaryLayout.ROW_VALUE_1,parts[2],parts[0],v.theme.ink);
        x += v.packedWidth(parts[0],parts[2])+Layout.STATS_GAP;
        v.text(dc,x,unitBaseline(parts[2],1),FontInk.SUMMARY_LABEL,"mi",v.theme.label,Graphics.TEXT_JUSTIFY_LEFT);
        if (parts[1] != null) {
            x += v.textWidth(dc,"mi",FontInk.SUMMARY_LABEL)+Layout.PACKED_GAP;
            v.drawPacked(dc,x,SummaryLayout.ROW_VALUE_1,parts[3],parts[1],v.theme.blue);
        }
    }
    function draw(v as FastRiderView, dc) {
        header(v,dc);
        v.color(dc,v.theme.rule);dc.fillRectangle(SummaryLayout.COLUMN_DIVIDER,SummaryLayout.TOP_RULE+Layout.STROKE,
            Layout.STROKE,SummaryLayout.BANNER_TOP-SummaryLayout.TOP_RULE-Layout.STROKE);
        v.drawHeart(dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_1-Layout.u(12));
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_2,"AVG HR");
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_3,"Avg PWR");
        var np = v.normalized.value();
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_4,np != null && v.normalized.estimated ? "NP est" : "NP");
        value(v,dc,v.intText(v.hr),"bpm",Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,
            1,v.theme.zoneColor(RideMath.zone(v.hr,v.hrLimits)));
        value(v,dc,v.intText(v.averageHr),"bpm",Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,
            2,v.theme.zoneColor(RideMath.zone(v.averageHr,v.hrLimits)));
        value(v,dc,v.intText(v.ridePower),"w",Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,3,v.theme.ink);
        value(v,dc,v.intText(np),"w",Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,4,v.theme.ink);
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_1,"DIST");
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_2,"ASC");
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_3,"Avg CAD");
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_4,"Avg SPD");
        distance(v,dc);
        value(v,dc,RideMath.ascentFeetValue(v.ascent),"ft",SummaryLayout.RIGHT_START,SummaryLayout.RIGHT_WIDTH,2,v.theme.ink);
        value(v,dc,v.intText(v.averageCadence),"rpm",SummaryLayout.RIGHT_START,SummaryLayout.RIGHT_WIDTH,
            3,v.theme.cadenceColor(v.averageCadence));
        value(v,dc,RideMath.speedMphText(v.averageSpeed),"mph",SummaryLayout.RIGHT_START,SummaryLayout.RIGHT_WIDTH,4,v.theme.ink);
    }
}
