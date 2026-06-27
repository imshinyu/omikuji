#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRATE="$SCRIPT_DIR/../crates/omikuji"
I18N="$CRATE/i18n"

lupdate_bin="$(command -v lupdate6 || command -v lupdate || true)"
lrelease_bin="$(command -v lrelease6 || command -v lrelease || true)"
if [ -z "$lupdate_bin" ] || [ -z "$lrelease_bin" ]; then
    echo "need lupdate + lrelease (qt6 linguist tools: e.g. qt6-tools / qt6-linguist / qttools5-dev-tools)" >&2
    exit 1
fi

mkdir -p "$I18N"

if [ "$#" -gt 0 ]; then
    langs=("$@")
else
    langs=()
    for f in "$I18N"/omikuji_*.ts; do
        [ -e "$f" ] || continue
        base="$(basename "$f" .ts)"
        langs+=("${base#omikuji_}")
    done
fi

if [ "${#langs[@]}" -eq 0 ]; then
    echo "no languages yet. add one: $0 <code> [code...]   (e.g. $0 it ja)"
    exit 0
fi

ts_args=()
for lang in "${langs[@]}"; do
    ts_args+=("-ts" "$I18N/omikuji_$lang.ts")
done

"$lupdate_bin" "$CRATE/qml" "$CRATE/src/tray_native.cpp" "${ts_args[@]}"

for lang in "${langs[@]}"; do
    "$lrelease_bin" "$I18N/omikuji_$lang.ts" -qm "$I18N/omikuji_$lang.qm"
done

echo "done: ${langs[*]}"
