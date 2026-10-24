import Toybox.Attention;
import Toybox.System;

module BellAudio {
    // The native loud-beep preset owns its amplitude and duration. The public
    // API has no volume control; this is an input cooldown, not a sound length.
    const COOLDOWN_MS = 1600;

    function play() {
        if (!(Attention has :playTone)) { return false; }
        try {
            // Use Garmin's loud preset in one non-blocking request.
            Attention.playTone(Attention.TONE_LOUD_BEEP);
            if (BuildMode.DEMO || BuildMode.DIAGNOSTICS) {
                System.println("FastRider bell: double tap -> TONE_LOUD_BEEP");
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
