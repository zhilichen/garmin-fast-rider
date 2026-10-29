import Toybox.Test;

(:test)
function bellDoubleTapTest(logger) {
    var bell = new BellGesture();
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 0));
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 0)); // Duplicate timestamp is not a second touch.
    Test.assert(bell.tap(Layout.u(44), Layout.u(40), 400)); // Inclusive time and distance limits.
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 500));
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 600)); // Playback cannot be restarted by more taps.
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 400+BellAudio.COOLDOWN_MS));
    Test.assert(bell.tap(Layout.u(20), Layout.u(40), 500+BellAudio.COOLDOWN_MS));
    bell.reset();
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 100));
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 501)); // Timeout arms a fresh first touch.
    Test.assert(bell.tap(Layout.u(20), Layout.u(40), 601));
    bell.reset();
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 100));
    Test.assert(!bell.tap(Layout.u(45), Layout.u(40), 200)); // 25px movement is not a double tap.
    Test.assert(bell.tap(Layout.u(45), Layout.u(40), 300));
    return true;
}

(:test)
function bellBoundaryAndResetTest(logger) {
    var bell = new BellGesture();
    Test.assert(bell.contains(0, 0)); Test.assert(bell.contains(Layout.COLUMN_DIVIDER-1, Layout.STATS_BOTTOM-1));
    Test.assert(!bell.contains(-1, 30)); Test.assert(!bell.contains(Layout.COLUMN_DIVIDER, Layout.u(30)));
    Test.assert(!bell.contains(Layout.u(20), Layout.STATS_BOTTOM)); Test.assert(!bell.contains(Layout.PLOT_LEFT, Layout.PLOT_BOTTOM-Layout.u(3)));
    bell.tap(Layout.u(20), Layout.u(40), 100);
    Test.assert(!bell.tap(Layout.u(200), Layout.u(40), 200)); // Another panel breaks the pair.
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 300));
    bell.cancelPending();
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 350)); // Hold also breaks the pair.
    Test.assert(bell.tap(Layout.u(20), Layout.u(40), 400));
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 10)); // Monotonic-clock restart clears cooldown.
    Test.assert(bell.tap(Layout.u(20), Layout.u(40), 110));
    return true;
}

class BellTestField {
    var width = Layout.WIDTH;
    var height = Layout.HEIGHT;
    var ui;
    function initialize() { ui = new InteractionState(); }
    function handleTap(x, y) { return ui.tap(x, y); }
}
class BellTestDelegate extends FastRiderInputDelegate {
    var rings = 0;
    function initialize(view) { FastRiderInputDelegate.initialize(view); }
    function ringBell() { rings += 1; return true; }
}

(:test)
function bellInputRoutingTest(logger) {
    var field = new BellTestField(); var input = new BellTestDelegate(field);
    Test.assert(input.handleTapAt(Layout.u(31), Layout.STATS_TIME_BASELINE, 100));
    Test.assertEqual(input.rings, 0);
    Test.assert(input.handleTapAt(Layout.u(33), Layout.STATS_TIME_BASELINE+Layout.u(2), 250));
    Test.assertEqual(input.rings, 1);
    Test.assertEqual(field.ui.powerSeconds, 3); Test.assert(field.ui.allStats);
    Test.assertEqual(field.ui.range, 0);
    Test.assert(input.handleTapAt(Layout.RIGHT_EDGE-Layout.u(44), Layout.u(50), 300));
    Test.assertEqual(field.ui.powerSeconds, 10); // Other panels remain immediate.
    Test.assert(input.handleTapAt(Layout.RIGHT_START+Layout.u(10), Layout.STATS_TIME_BASELINE, 350)); Test.assert(!field.ui.allStats);
    Test.assert(input.handleTapAt(Layout.PLOT_LEFT, Layout.PLOT_BOTTOM-Layout.u(3), 400)); Test.assertEqual(field.ui.range, 1);
    // The right-panel edge after the 5px readjustment is now the right panel, not the bell region.
    Test.assert(input.handleTapAt(Layout.RIGHT_TAP_LEFT+1, Layout.u(50), 450));
    Test.assertEqual(field.ui.powerSeconds, 3); Test.assertEqual(input.rings, 1);
    Test.assert(input.handleTapAt(Layout.RIGHT_TAP_LEFT+1, Layout.STATS_TIME_BASELINE, 500)); Test.assert(field.ui.allStats);
    field.width = 120;
    Test.assert(!input.handleTapAt(20, 40, 2000));
    Test.assert(!input.handleTapAt(20, 40, 2100));
    Test.assertEqual(input.rings, 1);
    return true;
}

(:test)
function bellCooldownExpiryTest(logger) {
    var bell = new BellGesture();
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 100));
    Test.assert(bell.tap(Layout.u(20), Layout.u(40), 200));
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 199+BellAudio.COOLDOWN_MS));
    // Cooldown taps cannot become the first half of the next double tap.
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 200+BellAudio.COOLDOWN_MS));
    Test.assert(bell.tap(Layout.u(20), Layout.u(40), 201+BellAudio.COOLDOWN_MS));
    return true;
}

(:test)
function bellExactDurationTest(logger) {
    var tones = BellAudio.profile(); var total = 0; var strikes = 0;
    var sounding = 0; var silence = 0;
    for (var i = 0; i < tones.size(); i += 1) {
        var tone = tones[i];
        Test.assert(tone.duration > 0); Test.assertEqual(tone.duration%25, 0);
        Test.assert(tone.frequency >= 0);
        if (tone.frequency == 5600) { Test.assertEqual(total, strikes*600); strikes += 1; }
        if (tone.frequency == 0) { silence += tone.duration; }
        else { sounding += tone.duration; }
        total += tone.duration;
    }
    Test.assertEqual(total, 2000); Test.assertEqual(BellAudio.duration(tones), 2000);
    Test.assertEqual(strikes, 3);
    Test.assert(silence > 0); Test.assert(sounding > silence);
    // The final audible pulse ends at 2000ms, rather than padding with silence.
    Test.assert(tones[tones.size()-1].frequency > 0);
    return true;
}

(:test)
function bellRepeatAfterTwoSecondsTest(logger) {
    var bell = new BellGesture();
    bell.tap(Layout.u(20), Layout.u(40), 100); Test.assert(bell.tap(Layout.u(20), Layout.u(40), 200));
    // Late taps inside the sound cannot arm an immediate restart.
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 2199));
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 2299));
    Test.assert(!bell.tap(Layout.u(20), Layout.u(40), 2300));
    Test.assert(bell.tap(Layout.u(20), Layout.u(40), 2400));
    return true;
}

(:test)
function summaryBellAndGraphRoutingTest(logger) {
    var field = new FastRiderView();field.computeDemo();field.onTimerStop();
    var input = new BellTestDelegate(field);
    Test.assert(input.handleTapAt(Layout.u(20),SummaryLayout.ROW_VALUE_4,100));
    Test.assert(input.handleTapAt(Layout.u(20),SummaryLayout.ROW_VALUE_4,200));
    Test.assertEqual(input.rings,1);
    Test.assertEqual(input.bell.bottom,SummaryLayout.BANNER_TOP);
    Test.assert(input.handleTapAt(Layout.WIDTH/2,SummaryLayout.HEADER_BASELINE,300));
    Test.assertEqual(field.ui.range,1);
    field.onTimerResume();
    Test.assert(!input.handleTapAt(Layout.u(20),Layout.STATS_BOTTOM+1,400));
    Test.assertEqual(input.bell.bottom,Layout.STATS_BOTTOM);
    return true;
}
