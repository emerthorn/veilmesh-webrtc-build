# veilmesh-webrtc-build

Reproducible builds of [libwebrtc](https://webrtc.googlesource.com/src/) for
the VeilMesh messenger: one pinned source commit, every platform slice built
from it in CI, published as a GitHub Release with a `SHA256SUMS` manifest.

Consumers pin a release **tag and the checksum** of each archive; nothing is
downloaded on trust.

## Sources

| Component | Where it comes from |
|---|---|
| libwebrtc | [`emerthorn/webrtc`](https://github.com/emerthorn/webrtc), branch `veilmesh` — a fork of [`webrtc-sdk/webrtc`](https://github.com/webrtc-sdk/webrtc) (the LiveKit fork of upstream WebRTC). The exact commit is in [`VERSION`](VERSION) and mirrored in [`.gclient`](.gclient); CI refuses to build if the two disagree. |
| Build scripts and patches | This repository. `build_*.sh`, `patches/*.patch`, `prefixed-jni/` and `boringssl_prefix_symbols.txt` are taken from LiveKit's [`rust-sdks`](https://github.com/livekit/rust-sdks) (`webrtc-sys/libwebrtc`, Apache-2.0) and kept unmodified, so the first release is built from the same commit, flags and patches as LiveKit's own `webrtc-89d790b` prebuilt. VeilMesh-specific patches live in [`patches/veilmesh/`](patches/veilmesh/). |
| Consumer | [`emerthorn/rust-sdks`](https://github.com/emerthorn/rust-sdks), branch `veilmesh`: its `webrtc-sys-build` crate downloads a release from here by tag and verifies the archive against a pinned sha256 before extracting it. |

## Versioning

Release tags have the form `webrtc-<sha7>-veilmesh.<revision>`, e.g.
`webrtc-89d790b-veilmesh.1`:

- `<sha7>` — first seven characters of the libwebrtc commit in `VERSION`;
- `<revision>` — `BUILD_REVISION` from `VERSION`, bumped when the sources stay
  the same but flags or patches change.

A new libwebrtc commit is a new `<sha7>`; the revision restarts at 1.

## Release contents

Each release carries one archive per slice plus `SHA256SUMS`:

```
webrtc-ios-device-arm64-release.zip
webrtc-ios-simulator-arm64-release.zip
webrtc-mac-arm64-release.zip
webrtc-mac-x64-release.zip
webrtc-android-arm64-release.zip
webrtc-android-arm-release.zip
webrtc-android-x64-release.zip
webrtc-linux-x64-release.zip
SHA256SUMS
```

An archive unpacks to `<os>-<arch>-release/` containing `lib/libwebrtc.a`,
`include/` (headers), `webrtc.ninja` (the compile definitions consumers must
replay), `LICENSE.md` (licenses of everything linked in), a copy of
`VERSION`, and `PROVENANCE.txt` (libwebrtc commit, commit and tag of this
repository, runner image, build time). Android archives additionally contain
`libwebrtc.jar`, the Java half of the SDK.

Verify a download:

```bash
sha256sum -c SHA256SUMS --ignore-missing
```

## Building in CI

[`.github/workflows/build.yml`](.github/workflows/build.yml) builds the matrix
on GitHub-hosted runners (macOS for iOS and macOS slices, Ubuntu for Android
and Linux). It runs on:

- **`workflow_dispatch`** — optionally with a comma-separated subset of slices
  (`targets`), useful for a smoke build of a single slice;
- **a pushed tag `webrtc-*`** — builds every slice and publishes the release.

Expect 40 minutes (Android) to about two hours (iOS/macOS) per slice; the
Chromium toolchain checkout is 20–40 GB. Windows slices are not built yet.

## Building locally

Requirements: macOS with Xcode and `ninja` for Apple slices; Linux with
`ninja-build`, `pkg-config` and a JDK for Android and Linux slices. The scripts
fetch `depot_tools` and the sources themselves.

```bash
echo 'target_os = ["ios"]' >> .gclient        # ios | mac | android | linux
./build_ios.sh --arch arm64 --profile release
./build_ios.sh --arch arm64 --profile release --environment simulator
./build_macos.sh --arch arm64 --profile release
./build_android.sh --arch arm64 --profile release   # Linux host only
./build_linux.sh --arch x64 --profile release
```

The output directory (`ios-device-arm64-release/` and so on) can be used
directly by a `webrtc-sys`-based project through the `LK_CUSTOM_WEBRTC`
environment variable, bypassing the download.

## Notes

- The Android Java package stays `livekit.org.webrtc` (LiveKit's
  `jni_prefix.patch`): the JNI initialisation in `webrtc-sys` depends on it.
- The Linux build renames BoringSSL symbols with a `livekit_` prefix
  (`boringssl_prefix_symbols.txt`), as LiveKit does; Apple and Android builds
  keep BoringSSL's original symbol names.
- Build flags are LiveKit's for now; narrowing the codec set is planned as a
  later revision.

## License

The scripts and patches in this repository are licensed under the
[Apache License 2.0](LICENSE). libwebrtc itself is BSD-licensed and bundles
third-party components under their own licenses — every release archive
includes the aggregated `LICENSE.md` generated during the build.
