# Connect IQ Store submission

The Store listing is **Fast Rider**, a free, public cycling Data Field for the
12 Edge models in `config/devices.json`. Source and support use the public
GitHub repository. No paid account, subscription or payment integration is used.

Latest complete upload kit: [campaign/v0.4.13](campaign/v0.4.13/README.md), with exact-size images, per-field copy and a local HTML preview.

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

Version **0.4.4** adds number-only zone badges and tapered fill gauges. Prepared IQ: `../dist/connect-iq/v0.4.4/FastRider-0.4.4.iq`. This candidate has not been submitted in this change. [Acceptance](../docs/validation/zones/v0.4.4/README.md) · What's New: [English](whats-new-0.4.4-en.txt) / [中文](whats-new-0.4.4-zh-CN.txt).

Version **0.4.5** enlarges the four riding live metrics, with tight vertical side labels. Prepared IQ: `../dist/connect-iq/v0.4.5/FastRider-0.4.5.iq`. This candidate has not been submitted in this change. [Acceptance](../docs/validation/live-cells/v0.4.5/README.md) · What's New: [English](whats-new-0.4.5-en.txt) / [中文](whats-new-0.4.5-zh-CN.txt).

Version **0.4.6** reorganizes the paused summary: time on top, eight metrics in two columns and a compact graph. Prepared IQ: `../dist/connect-iq/v0.4.6/FastRider-0.4.6.iq`. This candidate has not been submitted in this change. [Acceptance](../docs/validation/summary/v0.4.6/README.md) · What's New: [English](whats-new-0.4.6-en.txt) / [中文](whats-new-0.4.6-zh-CN.txt).

Version **0.4.7** raises/enlarges Zone badges and gauges, puts All/Lap beside time with smaller hour-format seconds, and enlarges distance. Font and history caches are bounded for legacy runtimes. Prepared IQ: `../dist/connect-iq/v0.4.7/FastRider-0.4.7.iq`. Not submitted by this change. [Acceptance](../docs/validation/riding/v0.4.7/README.md) · What's New: [English](whats-new-0.4.7-en.txt) / [中文](whats-new-0.4.7-zh-CN.txt).

Version **0.4.8** simplifies the paused summary, enlarges numeric values and widens its right column. Prepared IQ: `../dist/connect-iq/v0.4.8/FastRider-0.4.8.iq`. Not submitted in this change. [Acceptance](../docs/validation/summary/v0.4.8/README.md) · What's New: [English](whats-new-0.4.8-en.txt) / [中文](whats-new-0.4.8-zh-CN.txt).

Version **0.4.9** right-aligns the power Zone badge and fits full-size three-digit / smaller four-digit power. Prepared IQ: `../dist/connect-iq/v0.4.9/FastRider-0.4.9.iq`. Not submitted in this change. [Acceptance](../docs/validation/power/v0.4.9/README.md).

Version **0.4.10** stacks mi above remaining miles beside the large riding distance. Prepared IQ: `../dist/connect-iq/v0.4.10/FastRider-0.4.10.iq`. Not submitted in this change. [Acceptance](../docs/validation/distance/v0.4.10/README.md).

Version **0.4.11** enlarges riding metrics and distance, removes paused header labels, and gives the paused statistics more room. Prepared IQ: `../dist/connect-iq/v0.4.11/FastRider-0.4.11.iq`. Not submitted. [Acceptance](../docs/validation/readability/v0.4.11/README.md).

Version **0.4.12** uses short paused-screen metric names and small units beside each value. Prepared IQ: `../dist/connect-iq/v0.4.12/FastRider-0.4.12.iq`. Not submitted. [Acceptance](../docs/validation/summary/v0.4.12/README.md).

Version **0.4.13** aligns the paused clock at the top-right edge and refreshes all campaign screenshots/copy, adding paused-summary and day/night feature cards. Prepared IQ: `../dist/connect-iq/v0.4.13/FastRider-0.4.13.iq`. Not submitted. [Acceptance](../docs/validation/clock/v0.4.13/README.md).
