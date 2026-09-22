# veilmesh-webrtc-build

Собственная сборка libwebrtc для VeilMesh (решение D5,
`veilmesh/docs/CALLS_ARCHITECTURE_2026-09-21.md` §9): один зафиксированный
коммит форка → все платформенные срезы одной версией → релиз с `SHA256SUMS`.
Сторонние prebuilt-артефакты в production запрещены; этот репозиторий их
заменяет.

## Что и откуда

| Что | Где |
|---|---|
| Исходники libwebrtc | форк [`emerthorn/webrtc`](https://github.com/emerthorn/webrtc), ветка `veilmesh` (от `webrtc-sdk/webrtc`, коммит в `VERSION`) |
| Скрипты и патчи сборки | этот репозиторий — копия `webrtc-sys/libwebrtc` из livekit `rust-sdks` (Apache-2.0) с нашими правками; наши патчи кладутся в `patches/veilmesh/` |
| Потребитель | форк [`emerthorn/rust-sdks`](https://github.com/emerthorn/rust-sdks), ветка `veilmesh`: `webrtc-sys-build` качает релиз отсюда по тегу и сверяет sha256 |

Первый релиз собирается из того же коммита `89d790b`, из которого livekit
собрал свой `webrtc-89d790b`, с теми же флагами и патчами — чтобы любая
разница в поведении списывалась на сборку, а не на код.

## Версия и теги

`VERSION` — единственный источник правды: `WEBRTC_COMMIT` (полный sha форка,
дублируется в `.gclient`; CI проверяет совпадение), `BUILD_REVISION`.
Тег релиза: `webrtc-<sha7>-veilmesh.<BUILD_REVISION>`, например
`webrtc-89d790b-veilmesh.1`. Новая ревизия при тех же исходниках (поменялись
флаги/патчи) — `+1` к `BUILD_REVISION`; новый коммит libwebrtc — новый sha.

## Сборка в CI

`.github/workflows/build.yml`: матрица `ios-device-arm64`,
`ios-simulator-arm64`, `mac-arm64`, `mac-x64`, `android-{arm64,arm,x64}`,
`linux-x64` на хостовых раннерах GitHub (macOS 15 / Ubuntu 24.04, как у
livekit); Windows — с этапа C. Запуск: `workflow_dispatch` (можно указать
подмножество срезов) или push тега `webrtc-*` — тогда после сборки создаётся
GitHub Release с zip'ами и `SHA256SUMS`.

Один срез — от 40 минут (Android) до 2 часов (iOS/macOS) на хостовом
раннере; checkout Chromium-toolchain — 20–40 ГБ. Если репозиторий приватный,
macOS-минуты считаются ×10 — публичный репозиторий собирает бесплатно.

Каждый zip несёт `PROVENANCE.txt` (коммит libwebrtc, коммит и тег этого
репозитория, раннер, время) и копию `VERSION`.

## Сборка локально

```bash
# macOS: Xcode + brew install ninja; Linux: ninja-build pkg-config openjdk-17-jdk
echo 'target_os = ["ios"]' >> .gclient       # или mac / android / linux
./build_ios.sh --arch arm64 --profile release                # device
./build_ios.sh --arch arm64 --profile release --environment simulator
./build_macos.sh --arch arm64 --profile release
./build_android.sh --arch arm64 --profile release            # только Linux-хост
```

Результат — каталог `<os>-<arch>-release/` (`lib/libwebrtc.a`, `include/`,
`webrtc.ninja`, `LICENSE.md`; для Android ещё `libwebrtc.jar`). Подключить к
ядру без релиза: `LK_CUSTOM_WEBRTC=<путь к каталогу> cargo build ...`.

## Что здесь наше, а что livekit

- `build_*.sh`, `patches/*.patch`, `prefixed-jni/`, `boringssl_prefix_symbols.txt`
  — livekit, без изменений (кроме `.gclient`, который указывает на наш форк).
  Java-пакет Android остаётся `livekit.org.webrtc`: на него завязана
  JNI-инициализация в `webrtc-sys`; переименование — отдельный шаг.
- `patches/veilmesh/` — наши патчи (пока пусто). Правило D5: флаги сборки,
  экспорт символов, objc++-шимы; никакой логики.
- Префиксация символов BoringSSL (`llvm-objcopy --redefine-syms`) у livekit
  делается только для Linux. Ядру VeilMesh она **не нужна и вредна**: с
  CF-206 SQLCipher линкуется против этого же BoringSSL как единственного
  libcrypto процесса (`prepare_boringssl_shim.sh`). Для Linux-среза это
  надо будет выключить на этапе C.
- `rtc_use_h265=true` в Android-сборке livekit и прочие флаги оставлены как
  есть ради воспроизводимости первой сборки; сужение под профиль §8 (VP8 +
  Opus, без H.265/AV1) — следующая ревизия.
