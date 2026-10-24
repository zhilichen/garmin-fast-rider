import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;

module BellAudio {
    const DURATION_MS = 2000;
    const COOLDOWN_MS = DURATION_MS+100;
    // Three attacks at 0 / 600 / 1200ms. All notes and rests use a 25ms grid.
    // A bright strike, two alternating resonances, then a thinning pulse tail.
    // Zero-Hz rests are also used by Garmin's SDK Attention sample song.
    const STRIKE = [[5600,25],[2800,75],[4400,50],[2800,50],
                    [4400,25],[2800,75],[0,25],[2800,50],[0,25],
                    [4400,25],[0,50],[2800,25],[0,100]];
    const FINAL_STRIKE = [[5600,25],[2800,75],[4400,50],[2800,50],
                          [4400,25],[2800,75],[0,25],[2800,50],[0,25],
                          [4400,25],[0,50],[2800,25],[0,75],[2800,25],
                          [0,100],[2800,25],[0,50],[2800,25]];

    function append(tones as Lang.Array<Attention.ToneProfile>, notes as Lang.Array<Lang.Array<Lang.Number>>) {
        for (var i = 0; i < notes.size(); i += 1) {
            tones.add(new Attention.ToneProfile(notes[i][0], notes[i][1]));
        }
    }
    function profile() as Lang.Array<Attention.ToneProfile> {
        var tones = new Lang.Array<Attention.ToneProfile>[0];
        append(tones, STRIKE); append(tones, STRIKE); append(tones, FINAL_STRIKE);
        return tones;
    }
    function duration(tones as Lang.Array<Attention.ToneProfile>) {
        var total = 0;
        for (var i = 0; i < tones.size(); i += 1) { total += tones[i].duration; }
        return total;
    }
    function play() {
        if (!(Attention has :playTone) || !(Attention has :ToneProfile)) { return false; }
        try {
            var tones = profile(); var total = duration(tones);
            // Never substitute a native preset with an unspecified duration.
            if (total != DURATION_MS) { return false; }
            // Queue once: the tone engine owns every onset and the 2000ms end.
            // No repeating option, frame scheduling, sleep or busy wait.
            Attention.playTone({:toneProfile=>tones});
            if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
                System.println("FastRider bell: triple clang, "+tones.size()+" profiles, "+total+"ms, attacks=0/600/1200ms");
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
