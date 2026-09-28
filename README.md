# surfaces demo

One page per [surfaces](https://github.com/1vivy/aera-flutter-sdk) feature,
running the same Flutter and Rust code on every host: KernelSU, SukiSU,
KernelSU Next, APatch, KsuWebUIStandalone and WebUI X modules, a plain
browser, AERA Recovery and Linux desktop. Each page shows which of its
capabilities the host has and what the app does instead when it doesn't.

| Page | Shows |
| --- | --- |
| Host | What surfaces detected: kind, WebUI tier, engine, all 24 capabilities with their fallbacks; share the report |
| Back and exit | Host Back as a route pop through `PopScope`, nested pages, closing the app |
| Window | Safe-area insets (with an overlay), keyboard height, full screen, status bar icons |
| Lifecycle | Pause, resume and Back events as they arrive |
| Storage | A note in root-owned files, localStorage or the app data folder |
| Files | Pick a file and hash it in the Rust core; save a file to Downloads |
| Toast and share | Host toasts or in-app ones; the share sheet or the clipboard |
| Theme | The host's Material You colours and the scheme built from them |
| Apps | Installed apps, with labels where the host gives them |
| Shell | Root commands, and how long the host froze the page to run one |
| Ops and jobs | Rust ops as root (the module's worker) or in-process: calls, jobs with progress and cancel, and one op with swappable backends picked by what the host can use (`rust/core/src/disks.rs`) |
| Fractal | The Mandelbrot set drawn by the Rust core: every CPU natively, `core.wasm` on the web |
| Motion | A frame-rate meter |
| Sound | AERA's speaker played by Rust (AERA only) |

## Install

- **KernelSU / APatch / Magisk with WebUI X**: install `surfaces_demo-<version>.zip`
  from the releases in your root manager and open its WebUI.
- **AERA Recovery**: copy `Surfaces-Demo-<version>.aerap` to the phone and install
  it from AERA's plugin screen. It takes the browser slot until you reinstall AERA Browser.
- **Linux**: unpack `surfaces_demo-<version>-linux-x64.tar.gz` and run `surfaces_demo/surfaces_demo`.
- **Browser**: serve `build/web` from any static server.

## Build and try

Built like the [template](https://github.com/1vivy/aera-flutter-template):
`dart run surfaces_cli:surfaces build all`, and `surfaces serve --host <tier>`
to try the WebUI build against a fake root manager on a PC.
`tool/e2e_steps.cjs` walks the pages in every tier with the SDK's
`tools/e2e/webui_tiers.cjs`.
