# Connect IQ Store submission

The Store listing is **Fast Rider**, a free, public cycling Data Field for the
12 Edge models in `config/devices.json`. Source and support use the public
GitHub repository. No paid account, subscription or payment integration is used.

Latest complete upload kit: [campaign/v0.4.1](campaign/v0.4.1/README.md), with exact-size images, per-field copy and a local HTML preview.

Prepared material:

- `listing-en-US.txt`: primary description, setup and data limitations.
- `listing-zh-CN.txt`: Chinese description of the same functionality.
- `reviewer-notes.txt`: real-data mode, input differences and permission details.
- `assets/icon-512.png`, `assets/icon-1024.png`: renders of the existing
  `design/launcher.svg` artwork, with no Garmin branding.
- `../PRIVACY.md`: privacy notice; publish its public GitHub URL before submission.
- Native screenshots: `../docs/validation/screens/`. Use newly accepted frames
  matching the submitted version; the sample metrics must be described as synthetic.

Export the actual store package with the existing signing key:

```bash
./scripts/export-store.sh
```

Output is `dist/connect-iq/v<version>/FastRider-<version>.iq` plus SHA256, input
fingerprints and device coverage metadata. The export uses `monkey.jungle` live
data and the SDK release flag. Garmin's IQ file is a signed 7-Zip archive; it is
different from both a sideload PRG and this repository's installation ZIPs.
The verification step uses a 7-Zip-capable `tar` (macOS includes libarchive tar).

Minimum API 3.2 includes the Edge 1030 Asian regional product, whose installed
device package declares CIQ3.2.5. Newer optional native APIs remain guarded.
The exporter verifies all 17 regional product numbers across the 12 models and
refuses a package which silently omits a variant.

The owner-visible listing is [Fast Rider](https://apps.garmin.com/apps/ba487f91-82ad-4baa-94f0-9002f86d6a53). Version **0.4.1** was submitted with the owner's authorization and its page confirms **App pending**. It is not publicly downloadable until Garmin approves it.

Version **0.4.2** adds native day/night themes. Its verified live IQ export is prepared locally at `../dist/connect-iq/v0.4.2/FastRider-0.4.2.iq`; it has not been uploaded to replace the pending 0.4.1 submission. See the [theme acceptance record](../docs/validation/themes/v0.4.2/README.md) and `submission.json` for the distinction between submitted and prepared versions.

Garmin reviews a new app before it becomes publicly downloadable. Record the
actual resulting app URL and submission status; a prepared IQ file or a saved
draft does not mean that the app has been submitted or approved.

Official entry: https://developer.garmin.com/connect-iq/submit-an-app/

Version **0.4.3** adds an automatic paused/stopped ride summary and local NP.
Prepared IQ: `../dist/connect-iq/v0.4.3/FastRider-0.4.3.iq`. This version has not
been uploaded or submitted in this change. [Acceptance record](../docs/validation/summary/v0.4.3/README.md).
The 0.4.1 pending status above records the earlier submission; current Store
approval status has not been rechecked for this change.

Suggested What's New: [English](whats-new-0.4.3-en.txt) · [中文](whats-new-0.4.3-zh-CN.txt).
