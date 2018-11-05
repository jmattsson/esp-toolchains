# ESP toolchains

Convenience script for building both esp8266 and esp32 toolchains:

```
make esp8266
make esp32
```

Uses [pfalcon's esp-open-sdk](https://github.com/pfalcon/esp-open-sdk) for
the esp8266 toolchain (in toolchain-only mode), and the [official Espressif
repo](https://github.com/espressif/crosstool-NG) for the esp32 toolchain.

Based on the [nodemcu-prebuilt-toolchains](https://github.com/jmattsson/nodemcu-prebuilt-toolchains) script.
