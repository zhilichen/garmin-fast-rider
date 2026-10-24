import Toybox.Graphics;
module TestPlatform {
    var bitmap;
    function dc(width,height) {
        bitmap = Graphics.createBufferedBitmap({:width=>width,:height=>height});
        return bitmap.get().getDc();
    }
    function lap(v) { return v.onTimerLap2({:lapTrigger=>Toybox.WatchUi.DataField.LAP_TRIGGER_DISTANCE}); }
}
