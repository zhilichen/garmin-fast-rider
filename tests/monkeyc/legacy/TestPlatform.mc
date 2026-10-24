import Toybox.Graphics;
module TestPlatform {
    var bitmap;
    function dc(width,height) {
        bitmap = new Graphics.BufferedBitmap({:width=>width,:height=>height});
        return bitmap.getDc();
    }
    function lap(v) { v.onTimerLap(); return true; }
}
