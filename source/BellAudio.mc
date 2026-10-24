import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;

module BellAudio {
    const DURATION_MS = 1500;
    // Two 750ms electronic ding-ringing phrases. No undocumented zero-Hz pauses.
    const NOTES = [[3300,90],[2500,160],[3300,90],[2500,410],
                   [3300,90],[2500,160],[3300,90],[2500,410]];

    function profile() as Lang.Array<Attention.ToneProfile> {
        var tones = [];
        for (var i = 0; i < NOTES.size(); i += 1) {
            tones.add(new Attention.ToneProfile(NOTES[i][0], NOTES[i][1]));
        }
        return tones;
    }

    function play() {
        if (!(Attention has :playTone) || !(Attention has :ToneProfile)) { return false; }
        try {
            // Submit one complete sequence; no sleeps or timers in the input path.
            Attention.playTone({:toneProfile=>profile()});
            if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
                System.println("FastRider bell: double tap -> 1500ms");
            }
            return true;
        } catch (error) {
            if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
                System.println("FastRider bell: playback unavailable "+error);
            }
            return false;
        }
    }
}
