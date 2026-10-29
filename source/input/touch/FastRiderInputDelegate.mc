import Toybox.WatchUi;
import Toybox.System;
class FastRiderInputDelegate extends WatchUi.InputDelegate {
    var field;
    var bell;
    function initialize(view) { InputDelegate.initialize(); field = view; bell = new BellGesture(); }
    function onTap(event) {
        if (event.getType() != WatchUi.CLICK_TYPE_TAP) { bell.cancelPending(); return false; }
        var xy = event.getCoordinates();
        return handleTapAt(xy[0], xy[1], System.getTimer());
    }
    function handleTapAt(x, y, now) {
        if ((field has :width && field.width != Layout.WIDTH) || (field has :height && field.height != Layout.HEIGHT)) {
            bell.reset(); return false;
        }
        var bottom = field has :bellBottom ? field.bellBottom() : Layout.STATS_BOTTOM;
        if (bottom != bell.bottom) { bell.cancelPending(); bell.bottom = bottom; }
        var inBellRegion = bell.contains(x, y);
        var shouldRing = bell.tap(x, y, now);
        if (inBellRegion) {
            if (shouldRing && !ringBell()) { bell.reset(); }
            return true;
        }
        return field.handleTap(x, y);
    }
    function ringBell() { return BellAudio.play(); }
    function onHold(event) { bell.cancelPending(); return false; }
}
