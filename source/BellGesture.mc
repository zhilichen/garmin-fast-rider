// Independent of ride timing: the bell also works before Start and while paused.
class BellGesture {
    const DOUBLE_TAP_MS = 400;
    const MAX_DISTANCE_SQUARED = 24*24;
    var pendingTime = null;
    var pendingX = 0;
    var pendingY = 0;
    var busyUntil = null;
    var lastClock = null;

    function initialize() { reset(); }
    function reset() { cancelPending(); busyUntil = null; lastClock = null; }
    function cancelPending() { pendingTime = null; }
    function contains(x, y) { return x >= 0 && x < 122 && y >= 0 && y < 214; }

    // True exactly once per accepted double tap. Other regions break the pair.
    function tap(x, y, now) {
        if (lastClock != null && now < lastClock) { reset(); }
        lastClock = now;
        if (!contains(x, y)) { cancelPending(); return false; }
        if (busyUntil != null && now < busyUntil) { cancelPending(); return false; }
        if (pendingTime != null) {
            var elapsed = now-pendingTime;
            var dx = x-pendingX; var dy = y-pendingY;
            if (elapsed > 0 && elapsed <= DOUBLE_TAP_MS && dx*dx+dy*dy <= MAX_DISTANCE_SQUARED) {
                cancelPending();
                busyUntil = now+BellAudio.COOLDOWN_MS;
                return true;
            }
        }
        pendingTime = now; pendingX = x; pendingY = y;
        return false;
    }
}
