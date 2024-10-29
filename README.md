macos-input-source
========
macos-input-source is a tiny input source manager for macOS.

### Installation
```bash
brew install simnalamburt/x/input-source
```

input-source is also provided as a single static universal binary. Whether you
have an Mac with Apple silicon or Intel-based Mac, you can install input-source
by downloading just one file.

```bash
curl -LO https://github.com/simnalamburt/macos-input-source/releases/download/v0.1.4/input-source &&\
  chmod +x input-source
```

### Usage
```console
$ input-source
tiny input source manager

Usage: input-source <command> [--localized-name] [<args>]

Commands:
  current           Show current input source
  list              List available input sources
  set <Source>      Change input source to <source>

Options:
  --localized-name  Use LocalizedName instead of InputSourceID

Examples:
  input-source current
  input-source current --localized-name
  input-source list
  input-source list --localized-name
  input-source set com.apple.keylayout.ABC
  input-source set --localized-name ABC
```

### Development
```bash
zig build

# Build universal binary
zig build -Duniversal-binary
```

&nbsp;

--------
*macos-input-source* is primarily distributed under the terms of both the
[Apache License (Version 2.0)] and the [MIT license]. See [COPYRIGHT] for
details.

[MIT license]: LICENSE-MIT
[Apache License (Version 2.0)]: LICENSE-APACHE
[COPYRIGHT]: COPYRIGHT
