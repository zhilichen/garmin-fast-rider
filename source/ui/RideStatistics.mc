import Toybox.Graphics;
import Toybox.Lang;

// Inline title/time, followed by average watts and larger distance statistics.
module RideStatistics {
    function title(v as FastRiderView) {
        return v.ui.allStats ? "All" : "Lap "+(v.lapNumber == null ? "--" : v.lapNumber.format("%d"));
    }
    function timeParts(v as FastRiderView, dc, label, time) as Lang.Array {
        var lastColon = -1;var colons = 0;
        for (var i = 0; i < time.length(); i += 1) {
            if (time.substring(i,i+1).equals(":")) { colons += 1;lastColon = i; }
        }
        var head = colons == 2 ? time.substring(0,lastColon+1) : time;
        var seconds = colons == 2 ? time.substring(lastColon+1,time.length()) : null;
        var labels = [3,FontInk.SUMMARY_LABEL];var pairs = FontInk.RIDE_TIME_PAIRS;
        var result = [head,seconds,3,pairs[pairs.size()-1][1],FontInk.SUMMARY_LABEL,0];
        for (var i = 0; i < pairs.size(); i += 1) {
            var pair = pairs[i];
            if (FontInk.TOP[pair[0]] > Layout.STATS_TIME_BASELINE-Layout.MIDDLE_TOP-Layout.u(1)) { continue; }
            var width = v.packedWidth(head,pair[0]);
            if (seconds != null) { width += Layout.PACKED_GAP+Layout.COLON_GAP+v.packedWidth(seconds,pair[1]); }
            for (var j = 0; j < labels.size(); j += 1) {
                result = [head,seconds,pair[0],pair[1],labels[j],width];
                if (v.textWidth(dc,label,labels[j])+Layout.STATS_GAP+width <= Layout.RIGHT_WIDTH) { return result; }
            }
        }
        return result;
    }
    function drawTime(v as FastRiderView, dc, label, time) {
        var p = timeParts(v,dc,label,time);
        v.text(dc,Layout.RIGHT_START,Layout.STATS_TIME_BASELINE,p[4],label,v.theme.label,Graphics.TEXT_JUSTIFY_LEFT);
        var x = Layout.RIGHT_EDGE-p[5];
        v.drawPacked(dc,x,Layout.STATS_TIME_BASELINE,p[2],p[0],v.theme.ink);
        if (p[1] != null) {
            x += v.packedWidth(p[0],p[2])+Layout.PACKED_GAP+Layout.COLON_GAP;
            v.drawPacked(dc,x,Layout.STATS_TIME_BASELINE,p[3],p[1],v.theme.ink);
        }
    }
    function draw(v as FastRiderView, dc) {
        drawTime(v,dc,title(v),RideMath.lapDuration(v.ui.allStats ? v.timerMillis : v.lap.timeMs));
        var average = v.intText(v.ui.allStats ? v.ridePower : v.lap.averagePower);
        var uw = v.textWidth(dc,"AVG",3);
        var available = FontInk.PACK_STATS ? Layout.RIGHT_WIDTH-uw-Layout.STATS_GAP : Layout.AVERAGE_VALUE_WIDTH;
        var af = v.statsFace(dc,average,FontInk.AVERAGE_FACES,available);
        var aw = v.statsWidth(dc,average,af);
        var ax = Layout.RIGHT_START+DisplayRules.pixel((Layout.RIGHT_WIDTH-aw-Layout.STATS_GAP-uw)/2.0);
        v.drawStatsNumber(dc,ax,Layout.STATS_AVERAGE_BASELINE,af,average,Graphics.TEXT_JUSTIFY_LEFT);
        var center = ax+aw+Layout.STATS_GAP+uw/2;
        v.text(dc,center,Layout.STATS_AVERAGE_LABEL_BASELINE,3,"AVG",v.theme.label,Graphics.TEXT_JUSTIFY_CENTER);
        v.text(dc,center,Layout.STATS_AVERAGE_BASELINE,3,"W",v.theme.label,Graphics.TEXT_JUSTIFY_CENTER);
        var parts = v.distanceParts(dc,v.ui.allStats ? v.meters : v.lap.distance,v.ui.allStats ? v.remainingDistance : null,v.ui.allStats);
        var x = Layout.RIGHT_START+DisplayRules.pixel((Layout.RIGHT_WIDTH-v.distanceRowWidth(parts))/2.0);
        v.drawPacked(dc,x,Layout.STATS_DISTANCE_BASELINE,parts[2],parts[0],v.theme.ink);
        x += v.packedWidth(parts[0],parts[2])+Layout.PACKED_GAP;
        v.drawPacked(dc,x,Layout.STATS_DISTANCE_BASELINE,12,"mi",v.theme.label);
        x += v.packedWidth("mi",12)+Layout.PACKED_GAP;
        if (parts[1] != null) { v.drawPacked(dc,x,Layout.STATS_DISTANCE_BASELINE,parts[3],parts[1],v.theme.blue); }
    }
}
