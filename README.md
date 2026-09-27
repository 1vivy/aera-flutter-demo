# AERA Flutter demo

Flutter and Rust running inside AERA Recovery, drawn by the phone's GPU.
Built from [aera-flutter-template](https://github.com/1vivy/aera-flutter-template).

| Page | Shows |
| --- | --- |
| Device | Kernel, CPUs, memory and uptime read by Rust ([aera-sdk](https://github.com/1vivy/aera-flutter-sdk)) |
| Notes | Typing with AERA's keyboard, files in private storage, export to `/sdcard/AERA/Downloads` |
| Sound | A keyboard played through the speaker by Rust over AERA's audio bridge |
| Fractal | The Mandelbrot set computed in Rust on every core; tap to zoom |
| Motion | A continuous animation with a frame-rate meter, to judge GPU smoothness |

## Install

Download `Flutter-Demo-<version>.aerap` from the releases, copy it to the
phone and install it from AERA's plugin screen. It installs as an unofficial
app in the browser slot, replacing AERA Browser until you reinstall it.

## Build

Same as the template: `tool/aera.sh sim` runs it on a PC, `tool/aera.sh package`
builds the `.aerap`.
