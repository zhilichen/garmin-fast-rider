import Toybox.Test;

(:test)
function bellDoubleTapTest(logger) {
    var bell = new BellGesture();
    Test.assert(!bell.tap(20, 40, 0));
    Test.assert(!bell.tap(20, 40, 0)); // Duplicate timestamp is not a second touch.
    Test.assert(bell.tap(44, 40, 400)); // Inclusive time and distance limits.
    Test.assert(!bell.tap(20, 40, 500));
    Test.assert(!bell.tap(20, 40, 600)); // Playback cannot be restarted by more taps.
    Test.assert(!bell.tap(20, 40, 400+BellAudio.COOLDOWN_MS));
    Test.assert(bell.tap(20, 40, 500+BellAudio.COOLDOWN_MS));
    bell.reset();
    Test.assert(!bell.tap(20, 40, 100));
    Test.assert(!bell.tap(20, 40, 501)); // Timeout arms a fresh first touch.
    Test.assert(bell.tap(20, 40, 601));
    bell.reset();
    Test.assert(!bell.tap(20, 40, 100));
    Test.assert(!bell.tap(45, 40, 200)); // 25px movement is not a double tap.
    Test.assert(bell.tap(45, 40, 300));
    return true;
}

(:test)
function bellBoundaryAndResetTest(logger) {
    var bell = new BellGesture();
    Test.assert(bell.contains(0, 0)); Test.assert(bell.contains(121, 213));
    Test.assert(!bell.contains(-1, 30)); Test.assert(!bell.contains(122, 30));
    Test.assert(!bell.contains(20, 214)); Test.assert(!bell.contains(4, 316));
    bell.tap(20, 40, 100);
    Test.assert(!bell.tap(200, 40, 200)); // Another panel breaks the pair.
    Test.assert(!bell.tap(20, 40, 300));
    bell.cancelPending();
    Test.assert(!bell.tap(20, 40, 350)); // Hold also breaks the pair.
    Test.assert(bell.tap(20, 40, 400));
    Test.assert(!bell.tap(20, 40, 10)); // Monotonic-clock restart clears cooldown.
    Test.assert(bell.tap(20, 40, 110));
    return true;
}

class BellTestField {
    var width = 246;
    var height = 322;
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
    Test.assert(input.handleTapAt(31, 140, 100));
    Test.assertEqual(input.rings, 0);
    Test.assert(input.handleTapAt(33, 142, 250));
    Test.assertEqual(input.rings, 1);
    Test.assertEqual(field.ui.powerSeconds, 3); Test.assert(field.ui.allStats);
    Test.assertEqual(field.ui.range, 0);
    Test.assert(input.handleTapAt(200, 50, 300));
    Test.assertEqual(field.ui.powerSeconds, 10); // Other panels remain immediate.
    Test.assert(input.handleTapAt(126, 160, 350)); Test.assert(!field.ui.allStats);
    Test.assert(input.handleTapAt(4, 316, 400)); Test.assertEqual(field.ui.range, 1);
    field.width = 120;
    Test.assert(!input.handleTapAt(20, 40, 2000));
    Test.assert(!input.handleTapAt(20, 40, 2100));
    Test.assertEqual(input.rings, 1);
    return true;
}

(:test)
function bellCooldownExpiryTest(logger) {
    var bell = new BellGesture();
    Test.assert(!bell.tap(20, 40, 100));
    Test.assert(bell.tap(20, 40, 200));
    Test.assert(!bell.tap(20, 40, 199+BellAudio.COOLDOWN_MS));
    // Cooldown taps cannot become the first half of the next double tap.
    Test.assert(!bell.tap(20, 40, 200+BellAudio.COOLDOWN_MS));
    Test.assert(bell.tap(20, 40, 201+BellAudio.COOLDOWN_MS));
    return true;
}

(:test)
function bellPatternCadenceTest(logger) {
    var p = new BellPattern();
    Test.assertEqual(p.start(100), Toybox.Attention.TONE_LOUD_BEEP);
    Test.assert(p.next(899) == null);
    // At the real field's 1 Hz cadence, each update emits one different stage.
    Test.assertEqual(p.next(1100), Toybox.Attention.TONE_ALERT_HI);
    Test.assert(p.next(1100) == null);
    Test.assertEqual(p.next(2100), Toybox.Attention.TONE_LOUD_BEEP);
    Test.assertEqual(p.next(3100), Toybox.Attention.TONE_ALERT_LO);
    Test.assertEqual(p.next(4100), Toybox.Attention.TONE_LOUD_BEEP);
    Test.assert(!p.active); Test.assert(p.next(5100) == null);
    return true;
}

(:test)
function bellPatternCancellationTest(logger) {
    var p = new BellPattern(); p.start(1000);
    Test.assert(p.next(999) == null); Test.assert(!p.active);
    p.start(0);
    // Do not burst overdue sounds after an interrupted/stalled compute feed.
    Test.assert(p.next(2400) == null); Test.assert(!p.active);
    p.start(0); p.next(2200); p.next(3700);
    Test.assert(p.next(5000) == null); Test.assert(!p.active);
    p.start(100); p.cancel();
    Test.assert(p.next(1100) == null); Test.assert(!p.active);
    // Reopening the page or resetting the activity cancels the module's future notes.
    BellAudio.pattern = new BellPattern(); BellAudio.pattern.start(100);
    var view = new FastRiderView(); view.onHide();
    Test.assert(!BellAudio.pattern.active);
    BellAudio.pattern.start(100); view.onTimerReset(); Test.assert(!BellAudio.pattern.active);
    BellAudio.pattern.start(100); Toybox.Application.getApp().onStop(null);
    Test.assert(!BellAudio.pattern.active);
    return true;
}
