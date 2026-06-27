# Translations

omikuji's UI strings are wrapped in Qt's `qsTr()`. A `QTranslator` loads a compiled `.qm` at startup and resolves them; an unwrapped or untranslated string falls back to its English source. Translations live in `crates/omikuji/i18n/`, one editable `.ts` and one compiled `.qm` per language. The scope is the QML UI: the CLI and the Rust backend stay in English (aint doing allat).

## Prerequisites

The Qt Linguist tools, `lupdate` and `lrelease`. On Arch they ship in `qt6-tools` (as `lupdate6` / `lrelease6`), idk other distros. `scripts/update-translations.sh` accepts either the suffixed or the plain name.

## Adding a language

As an example, for Italian (`it`):

1. `./scripts/update-translations.sh it` harvests every `qsTr`/`tr` string into `crates/omikuji/i18n/omikuji_it.ts` and compiles a first `omikuji_it.qm`.

2. Then, you translate `omikuji_it.ts`, in either any text editor, by filling the `<translation>` elements, or `QtLinguistic` if you're sane. The file name carries the locale code Qt expects (`omikuji_it.ts`, `omikuji_pt_BR.ts`, `omikuji_ja.ts`).

3. Once done translating, run `./scripts/update-translations.sh it` again to recompile `omikuji_it.qm` from the finished strings.

4. Build. `build.rs` embeds the `.qm` into the binary, and the language appears in the picker at Settings > Interface under its own native name.

5. Commit both `omikuji_it.ts` and `omikuji_it.qm`.

## Updating a language

After UI strings change, refresh the catalogs:

`./scripts/update-translations.sh` with no arguments re-harvests and recompiles every language already in `i18n/`. New strings land in the `.ts` marked unfinished; translate them and run it again. Commit the updated `.ts` and `.qm`.

The build embeds the committed `.qm` and never runs `lrelease`, so both files are committed. The script produces both.

## Wrapping a new UI string

Any user-visible literal in a `.qml` file goes through `qsTr`:

```qml
text: qsTr("Play")
```

Text combined with data uses placeholders, not concatenation, because word order differs between languages:

```qml
text: qsTr("%1 left").arg(formatEta(secs))
text: qsTr("%n game(s)", "", count)
```

`%n` picks the plural form for the count.

Left unwrapped: icon names (`name:`, `icon:`), color tokens, runner and kind values (`"wine"`, `"native"`, `"steam"`), any literal used in a comparison, config keys, paths, and bare brand names (Steam, Epic Games, GOG, Proton, DXVK). A brand inside a sentence stays literal while the sentence is wrapped, as in `qsTr("Run with Omikuji")`.
