# Connect IQ Store submission

The intended listing is **FastRider**, a free, public cycling Data Field for the
12 Edge models in `config/devices.json`. Source and support use the public
GitHub repository. No paid account, subscription or payment integration is used.

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

Native acceptance is complete for v0.4.1; see
`../docs/validation/layout-v041`. The owner will upload the package and complete
the Connect IQ form. No app file has been uploaded or submitted by this task.
The prepared file is `../dist/connect-iq/v0.4.1/FastRider-0.4.1.iq` (735,207 bytes),
SHA256 `b24cf77ca6a3afd8615c5541ffd9b853dbd2d7810c5e3bf996230c6a74c57ced`.
The public privacy notice is already available at the GitHub URL in
`submission.json`.

Garmin reviews a new app before it becomes publicly downloadable. Record the
actual resulting app URL and submission status; a prepared IQ file or a saved
draft does not mean that the app has been submitted or approved.

Official entry: https://developer.garmin.com/connect-iq/submit-an-app/
