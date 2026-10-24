import Toybox.Application;
import Toybox.WatchUi;

class FastRiderApp extends Application.AppBase {
    var field;
    function initialize() { AppBase.initialize(); }
    function onStop(state) { BellAudio.stop(); }
    function getInitialView() {
        field = new FastRiderView();
        return [field, new FastRiderInputDelegate(field)];
    }
    function onSettingsChanged() {
        if (field != null) { field.loadSettings(); }
        WatchUi.requestUpdate();
    }
}
