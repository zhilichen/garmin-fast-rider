# Contributing

Changes to metrics, formatting and drawing belong in shared code. Keep device-specific differences in `config/devices.json`; keep geometry in `design/layout.json`. Avoid adding model-name branches to the renderer.

1. Regenerate changed project/font assets and run the Python checks.
2. Build the affected device matrix and run the native VM tests.
3. For UI changes, capture native single-field screens, including long numbers and missing sensors. Preserve the 840 golden images unless the design change intentionally updates them.
4. Describe the resulting behavior, affected profiles and validation in the pull request.

The included snapshots use synthetic metrics and a fixed clock. Use synthetic fixtures for bug reports; keep signing keys, SDK binaries and personal ride files out of commits. A fork published as a separate Connect IQ application should use its own application ID and signing key.

The project code is MIT-licensed. Preserve the separate notices and licenses for bundled font sources and generated glyph resources.
