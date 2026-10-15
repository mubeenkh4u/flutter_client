# Fluxer Beta mobile patchset

This `patched` branch is an **independent patch collection**, not a replacement for upstream source. The fork's `beta` branch stays clean and tracks `fluxerapp/flutter_client:beta`.

## Patches

- `0001-mobile-speaker-control.patch`: allows the mobile speaker/earpiece control to appear if native platform routing is available, even when LiveKit reports `canSwitchSpeakerphone=false`.
- PiP expansion and return-to-voice-only regressions are **not yet fixed**. These require further source-level investigation, tests and physical-device validation.
- Android's `VoiceSpeakerRoute.kt` already implements a native channel; showing the control does **not prove** audio successfully routes, especially when another audio session overrides it.

## Patch application

After updating `beta` from upstream, always apply to a fresh checkout or worktree:

```bash
git fetch origin beta patched
git worktree add --detach ../flutter_client-patched origin/beta
cd ../flutter_client-patched
git apply --check ../flutter_client/patches/0001-mobile-speaker-control.patch
git apply ../flutter_client/patches/0001-mobile-speaker-control.patch
git diff --check
```

If patches stop applying, fix the patch intentionally and review the upstream change; never apply with `--reject` or ignore errors.

## Release contract

Do not label builds ready while Dart analysis, PiP and audio acceptance tests, and platform builds are unverified. Once validated, the release tag should follow `<beta-version>-patched.<revision>`, with assets such as `fluxer-android-oss-patched.apk` and `fluxer-ios-patched.ipa`.

Android release artifacts need a reproducible build and signing strategy. iOS IPA distribution needs valid Apple signing/provisioning and legally permitted distribution; upstream's TestFlight workflow uses secrets belonging to upstream, which may not be available in the fork. Merely renaming an IPA does not make it installable.

## Required acceptance tests

1. Join a voice call, start camera or screen share, collapse to PiP, expand repeatedly (including after navigation).
2. Stop camera/screen share; verify the UI returns to the live voice-only call rather than a frozen video panel.
3. Switch speaker to earpiece and back on real Android hardware, including when a headset is attached and removed.
4. Repeat on iOS where signing and devices permit. Check route selection survives audio-session restarts.

The compatibility workflow applies patches to **fresh beta source** on each run. Publication will be added only after the patch set and platform build pipeline pass these checks.
