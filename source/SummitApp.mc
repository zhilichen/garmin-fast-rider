import Toybox.Application;
import Toybox.WatchUi;

class SummitApp extends Application.AppBase {
    var field;
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        field = new SummitView();
        return [field, new SummitInputDelegate(field)];
    }
    function onSettingsChanged() {
        if (field != null) { field.loadSettings(); }
        WatchUi.requestUpdate();
    }
}
