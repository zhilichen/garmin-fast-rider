import Toybox.Lang;

// Large distance on the left, with a shared unit/remaining-distance column.
module RideDistance {
    function inkHeight(face) { return FontInk.TOP[face]+FontInk.BOTTOM[face]+FontInk.NATIVE_BOTTOM_PAD; }
    function maxHeight() {
        var cap = inkHeight(FontInk.LIVE_SIDE_FACES[0]);
        var room = Layout.STATS_DISTANCE_BASELINE-Layout.STATS_AVERAGE_BASELINE-FontInk.BOTTOM[3]-FontInk.NATIVE_BOTTOM_PAD-Layout.u(2);
        return cap < room ? cap : room;
    }
    function rowWidth(v as FastRiderView, shown, rest, mainFace, restFace) {
        var side = v.packedWidth("mi",12);
        if (rest != null) {
            var width = v.packedWidth(rest,restFace);
            if (width > side) { side = width; }
        }
        return v.packedWidth(shown,mainFace)+Layout.STATS_GAP+side;
    }
    function rowHeight(mainFace, restFace, hasRest) {
        var side = inkHeight(12);
        if (hasRest) { side += Layout.DISTANCE_STACK_GAP+inkHeight(restFace); }
        var main = inkHeight(mainFace);
        return main > side ? main : side;
    }
    // [distance, remaining, main face, remaining face, block width, block height]
    function parts(v as FastRiderView, distance, remaining, all) as Lang.Array {
        var pairs = FontInk.RIDE_STACK_PAIRS;
        for (var pass = 0; pass < 3; pass += 1) {
            var text = v.distanceText(distance,remaining,all,pass);
            for (var i = 0; i < pairs.size(); i += 1) {
                var pair = pairs[i] as Lang.Array;
                var w = rowWidth(v,text[0],text[1],pair[0],pair[1]);
                var h = rowHeight(pair[0],pair[1],text[1] != null);
                if (w <= Layout.RIGHT_WIDTH && h <= maxHeight()) { return [text[0],text[1],pair[0],pair[1],w,h]; }
            }
        }
        var text = v.distanceText(distance,remaining,all,2);
        return [text[0],null,4,15,rowWidth(v,text[0],null,4,15),rowHeight(4,15,false)];
    }
    // [left, main baseline, side left, unit baseline, remaining baseline, top, bottom]
    function positions(v as FastRiderView, p as Lang.Array) as Lang.Array {
        var x = Layout.RIGHT_START+DisplayRules.pixel((Layout.RIGHT_WIDTH-p[4])/2.0);
        var bottom = Layout.STATS_DISTANCE_BASELINE+FontInk.NATIVE_BOTTOM_PAD;
        var top = bottom-p[5];
        var mainBase = top+DisplayRules.pixel((p[5]-inkHeight(p[2]))/2.0)+FontInk.TOP[p[2]];
        return [x,mainBase,x+v.packedWidth(p[0],p[2])+Layout.STATS_GAP,
            top+FontInk.TOP[12],bottom-FontInk.BOTTOM[p[3]]-FontInk.NATIVE_BOTTOM_PAD,top,bottom];
    }
    function draw(v as FastRiderView, dc, distance, remaining, all) {
        var p = parts(v,distance,remaining,all);var pos = positions(v,p);
        v.drawPacked(dc,pos[0],pos[1],p[2],p[0],v.theme.ink);
        v.drawPacked(dc,pos[2],pos[3],12,"mi",v.theme.label);
        if (p[1] != null) { v.drawPacked(dc,pos[2],pos[4],p[3],p[1],v.theme.blue); }
    }
}
