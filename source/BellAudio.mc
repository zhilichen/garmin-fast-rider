import Toybox.Attention;
import Toybox.System;

// Data-only schedule: compute() advances at most one note per call. No Timer
// module (unavailable to DataFields), busy wait, or catch-up burst of sounds.
class BellPattern {
    const INTERVAL_MS = 800;
    const MAX_LATE_MS = 1500;
    const MAX_LENGTH_MS = 5000;
    var active = false;
    var index = 0;
    var startedAt = 0;
    var dueAt = 0;
    var lastClock = 0;

    function initialize() {}
    function cancel() { active = false; index = 0; }
    function start(now) {
        startedAt = now; lastClock = now;
        dueAt = now+INTERVAL_MS; index = 1; active = true;
        return BellAudio.TONES[0];
    }
    function next(now) {
        if (!active) { return null; }
        if (now < lastClock || now-startedAt >= MAX_LENGTH_MS || now-dueAt > MAX_LATE_MS) {
            cancel(); return null;
        }
        lastClock = now;
        if (now < dueAt) { return null; }
        var tone = BellAudio.TONES[index];
        index += 1;
        active = index < BellAudio.TONES.size();
        dueAt = now+INTERVAL_MS;
        return tone;
    }
}

module BellAudio {
    // Three loud strikes with two contrasting high/low accents. Native presets
    // own their amplitude/duration; this schedule specifies onset times only.
    const TONES = [Attention.TONE_LOUD_BEEP, Attention.TONE_ALERT_HI,
                   Attention.TONE_LOUD_BEEP, Attention.TONE_ALERT_LO,
                   Attention.TONE_LOUD_BEEP];
    const NAMES = ["LOUD_BEEP", "ALERT_HI", "LOUD_BEEP", "ALERT_LO", "LOUD_BEEP"];
    const COOLDOWN_MS = 5500;
    var pattern = null;

    function emit(tone) {
        try {
            Attention.playTone(tone);
            if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
                System.println("FastRider bell: step "+pattern.index+"/5 "+NAMES[pattern.index-1]+" @"+(System.getTimer()-pattern.startedAt)+"ms");
            }
            return true;
        } catch (error) {
            stop();
            if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
                System.println("FastRider bell: playback unavailable "+error);
            }
            return false;
        }
    }
    function play() {
        if (!(Attention has :playTone)) { return false; }
        if (pattern == null) { pattern = new BellPattern(); }
        if (pattern.active) { return true; }
        return emit(pattern.start(System.getTimer()));
    }
    function tick() {
        if (pattern == null || !pattern.active) { return; }
        var tone = pattern.next(System.getTimer());
        if (tone != null) { emit(tone); }
    }
    // Cancels future notes; an already-playing native preset may finish.
    function stop() { if (pattern != null) { pattern.cancel(); } }
}
