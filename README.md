# AERA Flutter demo

Flutter and Rust running inside AERA Recovery, drawn by the phone's GPU.
Built from [aera-flutter-template](https://github.com/1vivy/aera-flutter-template).

> **This branch targets AERA's generic pixel + GPU plugin host, which is
> not released yet.** An AERA maintainer is adding it; until it ships, the
> interface here is assumed and `.aerap` files from this branch will not
> install on current nightlies. What we need from the host is tracked in
> [aera-flutter-demo#1](https://github.com/1vivy/aera-flutter-demo/issues/1).
> The `main` branch keeps the working stopgap that borrows AERA Browser's slot.

| Page | Shows |
| --- | --- |
| Device | Kernel, CPUs, memory and uptime read by Rust ([aera-sdk](https://github.com/1vivy/aera-flutter-sdk)) |
| Notes | Typing with AERA's keyboard, files in private storage, export to `/sdcard/AERA/Downloads` |
| Sound | A keyboard played through the speaker by Rust over AERA's audio bridge |
| Fractal | The Mandelbrot set computed in Rust on every core; tap to zoom |
| Motion | A continuous animation with a frame-rate meter, to judge GPU smoothness |

## Install

Download `Flutter-Demo-<version>.aerap` from the releases, copy it to the
phone and install it from AERA's plugin screen once AERA ships the pixel
host. It installs under its own ID (`dev.aera.flutter-demo`) next to AERA
Browser.

## Build

Same as the template: `tool/aera.sh sim` runs it on a PC, `tool/aera.sh package`
builds the `.aerap`.
