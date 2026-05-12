# iOS Action Test

This repository is a minimal GitHub Actions smoke test for iOS compilation on a macOS runner.

It uses a Swift Package with an iOS platform declaration and a workflow that runs `xcodebuild` on `macos-14`.

## Goal

Verify that GitHub Actions can start a macOS runner and compile Swift code for an iOS destination without code signing.

This does **not** produce an installable IPA yet, because real-device installation requires Apple code signing certificates and provisioning profiles.
