# Installable downloads

Versioned production builds are committed here so each model can be downloaded
directly from the repository's main README. Choose the exact Edge model.

Each version contains the original signed PRGs, per-model ZIPs, a complete ZIP,
installation instructions, licenses, a manifest and SHA256 checksums. ZIPs include
the same PRGs as the direct downloads. Defaults are 3s / All / 5m.

Generate downloads with `python3 scripts/package.py --publish` after building and
validating all targets. The command checks build input fingerprints and binary
hashes before publication and updates the main README table from the device list.
Published version directories are immutable. Increment the application version
before distributing a changed program.

CI checks integrity without the Garmin SDK. Signing keys, demo/test programs and
device activity data remain outside Git. See [development](../docs/development.md).
