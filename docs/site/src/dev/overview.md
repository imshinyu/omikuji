# Overview

Omikuji is two crates and a QML frontend.

- `crates/omikuji-core` is the backend. Pure Rust, no Qt. Game library, runners, prefixes, downloaders, per-publisher install logic. If it doesn't touch the UI, it lives here.
- `crates/omikuji` is the app: `main.rs`, the cxx-qt bridges in `src/bridge/`, and the QML in `qml/`.

The split is enforced. `omikuji-core` never imports Qt, and QML never calls core directly. Everything crosses through a bridge object.

## Building

```sh
cargo build -p omikuji
```

cxx-qt regenerates C++ glue on every build, so it isn't fast. The QML is compiled into the binary as a Qt resource, so editing a `.qml` (or adding one) needs a rebuild to show up.

Syntax-check QML without a full build:

```sh
qmllint qml/components/SomeFile.qml
```

`qmllint` only sees syntax. It doesn't know the types a bridge exposes, so it flags every bridge call as unknown.

## Shape of a change

A typical feature touches three layers: something in `omikuji-core`, a bridge in `src/bridge/` to expose it, and the QML that calls it. [Adding things](adding.md) covers the common cases.
