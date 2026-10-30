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
    function value(v as FastRiderView, dc, shown, left, width, row, c) {
        var baseline = rowValue(row);
        var faces = FontInk.SUMMARY_INT_VALUE_FACES;
        for (var i = 0; i < shown.length(); i += 1) {
            if (shown.substring(i,i+1).equals(".")) { faces = FontInk.SUMMARY_VALUE_FACES; break; }
        }
        var f = face(v,dc,shown,faces,width,room(rowLabel(row),baseline));
        var x = left+DisplayRules.pixel((width-v.packedWidth(shown,f))/2.0);
        v.drawPacked(dc,x,baseline,f,shown,c);
    }
    function header(v as FastRiderView, dc) {
        var lf = FontInk.SUMMARY_LABEL;
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.HEADER_LABEL,"Ride");
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
    function distanceParts(v as FastRiderView, dc) as Lang.Array {
        return v.distancePartsUsing(dc,v.meters,v.remainingDistance,true,SummaryLayout.RIGHT_WIDTH,
            room(SummaryLayout.ROW_LABEL_1,SummaryLayout.ROW_VALUE_1),FontInk.SUMMARY_DISTANCE_PAIRS,false);
    }
    function distance(v as FastRiderView, dc) {
        var parts = distanceParts(v,dc);
        var x = SummaryLayout.RIGHT_START+DisplayRules.pixel((SummaryLayout.RIGHT_WIDTH-v.distanceRowWidthFor(parts,false))/2.0);
        v.drawPacked(dc,x,SummaryLayout.ROW_VALUE_1,parts[2],parts[0],v.theme.ink);
        if (parts[1] != null) {
            x += v.packedWidth(parts[0],parts[2])+Layout.PACKED_GAP;
            v.drawPacked(dc,x,SummaryLayout.ROW_VALUE_1,parts[3],parts[1],v.theme.blue);
        }
    }
    function draw(v as FastRiderView, dc) {
        header(v,dc);
        v.color(dc,v.theme.rule);dc.fillRectangle(SummaryLayout.COLUMN_DIVIDER,SummaryLayout.TOP_RULE+Layout.STROKE,
            Layout.STROKE,SummaryLayout.BANNER_TOP-SummaryLayout.TOP_RULE-Layout.STROKE);
        v.drawHeart(dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_1-Layout.u(12));
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_2,"AVG");
        v.drawHeart(dc,Layout.LEFT_EDGE+v.textWidth(dc,"AVG",FontInk.SUMMARY_LABEL)+Layout.STATS_GAP,
            SummaryLayout.ROW_LABEL_2-Layout.u(12));
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_3,"AVG W");
        var np = v.normalized.value();
        caption(v,dc,Layout.LEFT_EDGE,SummaryLayout.ROW_LABEL_4,np != null && v.normalized.estimated ? "NP est W" : "NP W");
        value(v,dc,v.intText(v.hr),Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,
            1,v.theme.zoneColor(RideMath.zone(v.hr,v.hrLimits)));
        value(v,dc,v.intText(v.averageHr),Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,
            2,v.theme.zoneColor(RideMath.zone(v.averageHr,v.hrLimits)));
        value(v,dc,v.intText(v.ridePower),Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,3,v.theme.ink);
        value(v,dc,v.intText(np),Layout.LEFT_EDGE,SummaryLayout.LEFT_WIDTH,4,v.theme.ink);
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_1,"mi");
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_2,"ft");
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_3,"AVG rpm");
        caption(v,dc,SummaryLayout.RIGHT_START,SummaryLayout.ROW_LABEL_4,"AVG mph");
        distance(v,dc);
        value(v,dc,RideMath.ascentFeetValue(v.ascent),SummaryLayout.RIGHT_START,SummaryLayout.RIGHT_WIDTH,2,v.theme.ink);
        value(v,dc,v.intText(v.averageCadence),SummaryLayout.RIGHT_START,SummaryLayout.RIGHT_WIDTH,
            3,v.theme.cadenceColor(v.averageCadence));
        value(v,dc,RideMath.speedMphText(v.averageSpeed),SummaryLayout.RIGHT_START,SummaryLayout.RIGHT_WIDTH,4,v.theme.ink);
    }
}
