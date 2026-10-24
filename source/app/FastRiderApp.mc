import Toybox.Application;
import Toybox.WatchUi;

class FastRiderApp extends Application.AppBase {
    var field;
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        field = new FastRiderView();
        return InputSupport.initialView(field);
    }
    function onSettingsChanged() {
        if (field != null) { field.loadSettings(); }
        WatchUi.requestUpdate();
    }
}
