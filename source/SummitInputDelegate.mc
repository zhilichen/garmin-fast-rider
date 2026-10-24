import Toybox.WatchUi;
class SummitInputDelegate extends WatchUi.InputDelegate {
    var field;
    function initialize(view) { InputDelegate.initialize(); field = view; }
    function onTap(event) {
        if (event.getType() != WatchUi.CLICK_TYPE_TAP) { return false; }
        var xy = event.getCoordinates();
        return field.handleTap(xy[0], xy[1]);
    }
}
