import Toybox.Activity;

// The activity owns the timer. Screen selection never changes recording or laps.
class RideScreenState {
    var state = Activity.TIMER_STATE_OFF;
    function initialize() {}
    function reset() { state = Activity.TIMER_STATE_OFF; }
    function update(value) { if (value != null) { state = value; } }
    function summary() {
        return state == Activity.TIMER_STATE_PAUSED || state == Activity.TIMER_STATE_STOPPED;
    }
}
