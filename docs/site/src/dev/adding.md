# Adding things

Three common changes, start to finish. Each builds on [The cxx-qt bridge](cxx-qt.md).

## A setting

A setting is a value in `ui.toml` that QML reads and writes live. It exists in two structs and crosses through `UiSettingsBridge`. For a new bool `show_clock`:

1. Add the field to the core struct in `omikuji-core/src/ui_settings.rs` (the right section, e.g. `BehaviorSettings`) and to that section's `Default`.

2. Add the matching field to `UiSettingsRust` in `crates/omikuji/src/bridge/ui_settings.rs`, plus a property line:
```rust
#[qproperty(bool, show_clock, cxx_name = "showCock")]
```

3. Carry the field through the three conversions in that same file: `from_settings` (core to bridge), `snapshot` (bridge to core), and `reload_from_disk`.

4. Add the apply invokable. Declare it in the `unsafe extern "RustQt"` block, then generate the body with the macro:
```rust
apply_setting!(apply_show_clock, set_show_clock, bool);
```
Write the body by hand instead if the setter does more than set-and-persist (clamping, a side effect, a custom signal). `apply_ui_scale` and `apply_discord_rpc` are the existing examples.

5. In QML, read `uiSettings.showClock` and write through `uiSettings.applyShowClock(value)`.

`from_settings` and `snapshot` are exhaustive struct literals, so a missing field won't compile. `reload_from_disk` is a list of setters, so a field missing there compiles fine and just doesn't reload.

## A per-game setting

Per-game config (the fields in `GameSettingsPage`: wine version, env, launch options) lives on the `Game` struct in `library.toml`, not `ui.toml`, and it doesn't use properties: the whole game config crosses to QML as one string-keyed map, so a new field is one row in a table.

1. Add the field to the right struct on `Game` in `omikuji-core/src/library/mod.rs` (`WineConfig`, `LaunchConfig`, ...), with a serde default.

2. Register it in the `game_fields!` table in `crates/omikuji/src/bridge/game_model.rs`:
```rust
"wine.my_flag" => bool, wine.my_flag,
```
That row wires both directions: reading the field into the config map and writing it back from QML. The kind tag picks the conversion (`str`, `path`, `bool`, `int`, `json` for maps and vecs, `args` for launch args). Add `readonly` after the kind for a read-only field.

3. In the settings tab QML (`TabRunnerOptions`, `TabSystem`, ...), add the control. Read the value from `config["wine.my_flag"]` and write changes through the page's `updateField("wine.my_flag", value)`, which updates the draft and refreshes `config`.

## A runtime tool

Runtime tools (umu, legendary, jadeite, ...) are fetched by the component system. To add one:

1. Add a variant to `SettingsKey` in `omikuji-core/src/components/spec.rs`.

2. Add the download URL to `ComponentsSettings` in `omikuji-core/src/settings.rs` and its `Default`. These are release-latest API URLs (GitHub, Codeberg) or a direct URL.

3. Map the key to the URL in `url_for` in `omikuji-core/src/components/mod.rs`.

4. Add the `ComponentSpec` in `omikuji-core/src/components/specs.rs`:
```rust
ComponentSpec {
    name: "mytool",
    source: Source::GithubRelease { asset_matcher: |n| n.ends_with(".tar.gz") },
    extract: ExtractStrategy::TarGz { inner_path: "mytool" },
    dest: "mytool",
    settings_key: SettingsKey::MyTool,
    trigger: Trigger::OnDemand,
},
```

5. Pick the trigger. `Eager` fetches at boot (only umu uses this). `OnDemand` fetches when something calls `components::ensure(...)`. For `OnDemand`, add that `ensure` call at the point the tool becomes necessary (a store login, a game install). `epic_tools` and `gacha_tools` in `components/mod.rs` are the existing examples.

## A dialog

Dialogs are built on `DialogCard`, which owns the backdrop, dim, click-outside, Esc, shadow, and scrolling. A dialog is a config of its slots.

1. Create `qml/components/dialogs/MyDialog.qml`:
```qml
import QtQuick
import "../widgets"

DialogCard {
    id: root
    title: "Do the thing?"
    maxWidth: 480

    body: Column {
        spacing: theme.space.md
        Text { text: "..."; color: theme.text }
    }

    actions: Row {
        spacing: theme.space.sm
        M3Button { text: "Cancel"; variant: "text"; onClicked: root.close() }
        M3Button { text: "Confirm"; variant: "tonal"; onClicked: { root.close() } }
    }

    onCloseRequested: close()
}
```

2. Register it in `qml_files` in `build.rs`.

3. Instantiate it once where it's used (a page, or `Main.qml`), give it an `id`, and call `.open()` to show it.

The slots take a `Component`, but a plain element works directly. Don't add your own backdrop or scrollbar, `DialogCard` owns those. For a fixed-height list dialog, set `fillHeight: true` and `scrollable: false`.
