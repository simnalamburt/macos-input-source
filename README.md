macos-input-source
========
macos-input-source is a tiny input source manager for macOS.

### Installation
<!-- TODO: Package with homebrew
```bash
brew install simnalamburt/x/input-source
```
-->

input-source is <!-- also --> provided as a single static universal binary.
Whether you have an Mac with Apple silicon or Intel-based Mac, you can install
input-source by downloading just one file.

```bash
curl -LO https://github.com/simnalamburt/macos-input-source/releases/download/v0.1.2/input-source &&\
  chmod +x input-source
```

### Usage
```console
$ input-source
tiny input source manager

Usage: input-source <command>

Commands:
  current       Show current input source
  list          List available input sources
  set <Source>  Change input source to <source>

Examples:
  input-source list
  input-source set com.apple.keylayout.ABC
```

&nbsp;

--------
*macos-input-source* is primarily distributed under the terms of both the
[Apache License (Version 2.0)] and the [MIT license]. See [COPYRIGHT] for
details.

[MIT license]: LICENSE-MIT
[Apache License (Version 2.0)]: LICENSE-APACHE
[COPYRIGHT]: COPYRIGHT
