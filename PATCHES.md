# Fluxer Beta — independent mobile patches

**Branch policy:** `beta` is an unmodified mirror of `fluxerapp/flutter_client:beta`.
Keep every fix as a patch file **only** on `patched`. Do not merge `patched`
into `beta`, and do not commit generated or patched application source onto
`patched`. The existing `canary` branch is unrelated.

## Patch manifest

The ordered manifest is `patches/series`. Comment out a line to disable
a patch in subsequent builds; do not rename or renumber patches casually.

| Patch | Purpose |
| --- | --- |
| 0001-mobile-speaker-control.patch | Offer the audio speaker/earpiece selector even when LiveKit's switching-capability flag is false on native iOS/Android. |
| 0002-mobile-audio-routing.patch | Always apply native output routing on supported mobile platforms; keep an explicitly selected speaker route even with a headset present; don't let a stale desktop-style output device override it. Includes updated route tests. |
| 0003-pip-media-lifecycle.patch | Recalculate PiP size when media changes, so an ended video/screen share becomes an avatar; prioritize actual transport publication state over delayed gateway flags; arm PiP expansion before navigation removes the compact overlay. Includes media-selection tests. |
| 0004-pip-regression-tests.patch | Widget regressions for camera-to-audio avatar sizing and repeated PiP expand/collapse. |
| 0005-patched-app-labels.patch | Show "Fluxer Beta Patched" as the app label on Android and iOS Beta, without modifying upstream source. |
| 0006-voice-only-layout-fallback.patch | When the last camera/screenshare ends, restore audio-only avatars in the full call grid even if "Only show videos" was previously selected; includes focused tests. |

## Patch application and upstream sync

Update the fork's `beta` branch from **official upstream Beta** using a clean
fast-forward/sync workflow. Do not sync from upstream Canary, and never force
`patched` onto `beta`. Then:

```bash
git fetch origin beta patched
git worktree add --detach ../fluxer-clean-build origin/beta
# Example assumes this is run from the repo on branch patched:
bash scripts/apply-patches.sh . ../fluxer-clean-build
```

The script requires a clean working tree, checks each patch with
`git apply --check`, skips patches already present upstream using
`git apply --reverse --check`, applies remaining patches in manifest order,
and fails on conflicts rather than guessing how to resolve them. It never
pushes or commits to `beta`. Remove the temporary worktree after testing.

As upstream changes, review failed hunks against the new source and update
the corresponding `.patch` file (or remove the now-upstreamed patch). The
correct behavior must be confirmed with tests before the next release.

## Verification workflow

`Patched Beta - compatibility and tests`:
`/.github/workflows/patched-beta.yml` runs on changes to the patchset
and on manual dispatch (where GitHub makes dispatch available). It checks out
the patchset and clean Beta **into separate directories**, applies patches
to the working copy, configures upstream's APNs development build,
runs dependency resolution/code generation/formatting/analysis, focused
audio and PiP tests, and the complete Flutter test suite. It records exact
source and patchset commit IDs.

CI code-level tests do not replace a physical device test:
- Android speaker/earpiece roundtrip, plus wired and Bluetooth headset changes.
- iPhone speaker/earpiece roundtrip and audio-session/CallKit interruptions.
- Start/stop local and remote camera, screenshare, and return to voice-only.
- PiP expand/collapse several times, with rapid navigation and rotation.

Do not announce the PiP/audio fixes as confirmed on real devices until these
steps are passed.

## GitHub release workflow

`/.github/workflows/patched-release.yml` is configured to build
**Android UnifiedPush OSS** and a **signed iOS Beta IPA** from fresh copies
of Beta with only enabled patches applied. Publishing is intentionally
gated by successful compatibility tests and both signed platform builds.

To publish, create and push a tag **pointing to the desired commit on
`patched`**, formatted `v<beta-version>-patched.<revision>`, for example
`v2026.10.100-patched.1`, or invoke manual release dispatch with
`publish=true` when GitHub permits. The title is `Fluxer Beta
<beta-version>-patched` and assets end in `-patched.apk` or
`-patched.ipa`. SHA256SUMS and exact commit provenance accompany the release.
The release is a GitHub **prerelease**, not an App Store/TestFlight upload.

**Android:** supply `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
and `ANDROID_KEY_PASSWORD` secrets in this fork. The workflow rejects
debug-only signing. You own and must retain the signing keystore for updates.

**iOS:** supply `CERTIFICATES_P12`, `CERTIFICATES_P12_PASSWORD`,
`PROVISIONING_PROFILE_BASE64`,
`BROADCAST_EXTENSION_PROVISIONING_PROFILE_BASE64`,
`NOTIFICATION_SERVICE_PROVISIONING_PROFILE_BASE64`,
`SHARE_EXTENSION_PROVISIONING_PROFILE_BASE64`,
and `IOS_EXPORT_OPTIONS_PLIST_BASE64`. These must match the app, its
extensions, and your Apple team. iOS Beta project settings inherit
upstream identifiers/team values, so adjust provisioning only on the patched
build if your certificate/team differs, not on `beta`.

A signed IPA is only installable through distribution permitted by its
profiles (development, Ad Hoc, enterprise, or TestFlight/App Store). Merely
attaching an App Store-signed IPA to GitHub releases does not make it directly
sideloadable. The workflow cannot succeed without valid Apple signing
materials, and will not publish unsigned binaries.

**Current verification status:** patch files and workflows have been
committed; use the GitHub Actions run logs to confirm test/build outcomes.
Android/iOS on-device behaviors remain to be verified with hardware.
