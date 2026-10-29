import Toybox.Graphics;

// Shared 2x2 live cells: large numeric ink, with a tight vertical label beside it.
module LiveMetrics {
    function labelWidth(v as FastRiderView, dc, label) {
        if (label.equals("%")) { return v.textWidth(dc,label,FontInk.LIVE_SIDE_PERCENT); }
        var w = 0;
        for (var i = 0; i < label.length(); i += 1) {
            var next = v.textWidth(dc,label.substring(i,i+1),FontInk.LIVE_SIDE_LABEL);
            if (next > w) { w = next; }
        }
        return w;
    }
    function face(v as FastRiderView, dc, value, label, width) {
        var available = width-labelWidth(v,dc,label)-Layout.LIVE_SIDE_GAP;
        for (var i = 0; i < FontInk.LIVE_SIDE_FACES.size(); i += 1) {
            var f = FontInk.LIVE_SIDE_FACES[i];
            if (v.packedWidth(value,f) <= available) { return f; }
        }
        // Keep even outlier sensor values inside their cell without dropping decimals.
        return v.packedWidth(value,13) <= available ? 13 : 3;
    }
    function baseline(center, font) {
        return center+DisplayRules.pixel((FontInk.TOP[font]-FontInk.BOTTOM[font]-FontInk.NATIVE_BOTTOM_PAD)/2.0);
    }
    function cell(v as FastRiderView, dc, left, width, center, value, label, c) {
        var f = face(v,dc,value,label,width);
        var nw = v.packedWidth(value,f); var lw = labelWidth(v,dc,label);
        var x = left+DisplayRules.pixel((width-nw-Layout.LIVE_SIDE_GAP-lw)/2.0);
        v.drawPacked(dc,x,baseline(center,f),f,value,c);
        var unit = x+nw+Layout.LIVE_SIDE_GAP+lw/2.0;
        if (label.equals("%")) {
            var pf = FontInk.LIVE_SIDE_PERCENT;
            v.text(dc,unit,baseline(center,pf),pf,label,v.theme.label,Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            var lf = FontInk.LIVE_SIDE_LABEL;
            var pitch = FontInk.TOP[lf]+FontInk.BOTTOM[lf]+FontInk.NATIVE_BOTTOM_PAD+Layout.LIVE_LETTER_GAP;
            var h = pitch*label.length()-Layout.LIVE_LETTER_GAP;
            var y = center-DisplayRules.pixel(h/2.0)+FontInk.TOP[lf];
            for (var i = 0; i < label.length(); i += 1) {
                v.text(dc,unit,y+i*pitch,lf,label.substring(i,i+1),v.theme.label,Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }
    function draw(v as FastRiderView, dc) {
        var left = Layout.LEFT_EDGE;
        var right = Layout.LEFT_RIGHT-Layout.LIVE_RIGHT_WIDTH;
        cell(v,dc,left,Layout.LIVE_LEFT_WIDTH,Layout.LIVE_CENTER_TOP,v.intText(v.rearGear),"GEAR",v.theme.ink);
        cell(v,dc,right,Layout.LIVE_RIGHT_WIDTH,Layout.LIVE_CENTER_TOP,v.intText(v.cadence),"RPM",v.theme.cadenceColor(v.cadence));
        cell(v,dc,left,Layout.LIVE_LEFT_WIDTH,Layout.LIVE_CENTER_BOTTOM,v.intText(v.grade),"%",v.theme.gradeColor(v.grade));
        cell(v,dc,right,Layout.LIVE_RIGHT_WIDTH,Layout.LIVE_CENTER_BOTTOM,RideMath.speedMphText(v.speed),"MPH",v.theme.ink);
    }
}
