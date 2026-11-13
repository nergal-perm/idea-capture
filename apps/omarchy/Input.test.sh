#!/usr/bin/env bash
set -euo pipefail
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
shell_dir="${CAPTURE_OMARCHY_SHELL:-${OMARCHY_PATH:?Set OMARCHY_PATH or CAPTURE_OMARCHY_SHELL}/shell}"
ln -s "$shell_dir/Commons" "$fixture/Commons"
ln -s "$shell_dir/Ui" "$fixture/Ui"
ln -s "$source_dir" "$fixture/CapturePlugin"
mkdir -p "$fixture/home"
cat > "$fixture/slow-codex" <<'MODEL'
#!/usr/bin/env python3
import time
print('started', flush=True)
time.sleep(4)
MODEL
chmod +x "$fixture/slow-codex"
cat > "$fixture/shell.qml" <<'QML'
//@ pragma OmarchyLoadPatch
import QtQuick
import QtTest
import qs.Commons
import "CapturePlugin" as Plugin
Item {
    Plugin.Capture { id: capture }
    TestCase { id: keyboard; when: false }
    property var editor
    property var viewport
    property var categoryDropdown
    property real initialHeight
    property int step: 0
    property double submittedAt: 0
    function find(node, predicate, visited) {
        if (!node || visited.indexOf(node) >= 0) return null
        visited.push(node)
        if (predicate(node)) return node
        var lists = [node.children || [], node.data || [], node.contentItem ? [node.contentItem] : []]
        for (var l = 0; l < lists.length; l++) for (var i = 0; i < lists[l].length; i++) {
            var result = find(lists[l][i], predicate, visited)
            if (result) return result
        }
        return null
    }
    function check(ok, message) { if (!ok) throw new Error(message) }
    Component.onCompleted: capture.open('{"date":"2027-01-01","category":"idea"}')
    Timer {
        interval: 120
        repeat: true
        running: true
        onTriggered: {
            try {
                if (step === 0) {
                    categoryDropdown = find(capture, n => n.label === "Category", [])
                    check(categoryDropdown !== null, "category dropdown must exist")
                    editor = find(capture, n => n.maximumLength === 8000, [])
                    check(editor !== null, "editor must exist")
                    check(editor.font.pixelSize < Style.font.heading, "input font must be smaller than heading")
                    viewport = find(capture, n => n.objectName === "captureEditorViewport", [])
                    check(viewport !== null, "growing viewport must exist")
                    initialHeight = viewport.height
                    editor.text = Array(45).join("Длинная мысль ")
                } else if (step === 1) {
                    check(viewport.height > initialHeight * 2, "wrapped text must grow the input")
                    check(editor.text.indexOf("\n") < 0, "visual wrapping must not insert newlines")
                    editor.text = Array(9000).join("я")
                    editor.cursorPosition = editor.length
                } else if (step === 2) {
                    check(editor.length === 8000, "pasted text must retain the existing length limit")
                    check(viewport.contentHeight > viewport.height, "long text must scroll within bounded input")
                    check(viewport.contentY > 0, "cursor at end must remain visible")
                    check(viewport.height < viewport.Window.window.height, "input must fit the screen")
                    editor.text = "Первая"
                    editor.cursorPosition = editor.length
                } else if (step === 3) {
                    check(viewport.height === initialHeight, "deleting text must shrink the input")
                    keyboard.parent = editor
                    editor.forceActiveFocus()
                    keyboard.keyClick(Qt.Key_Tab)
                } else if (step === 4) {
                    keyboard.keyClick(Qt.Key_Down, Qt.AltModifier)
                } else if (step === 5) {
                    if (!categoryDropdown.popupOpen) return
                    keyboard.keyClick(Qt.Key_Up)
                    keyboard.keyClick(Qt.Key_Up)
                    keyboard.keyClick(Qt.Key_Return)
                } else if (step === 6) {
                    check(capture.category === "fact", "keyboard selection must choose fact")
                    check(editor.activeFocus, "closing category popup must return focus to the editor")
                    keyboard.keyClick(Qt.Key_Return, Qt.ShiftModifier)
                    check(editor.text === "Первая\n" && !capture.busy, "Shift+Enter must insert a newline without saving")
                    editor.insert(editor.length, "Вторая")
                    submittedAt = Date.now()
                    keyboard.keyClick(Qt.Key_Return)
                    check(capture.busy, "Enter must submit the multiline text")
                } else if (step === 7) {
                    check(Date.now() - submittedAt < 700, "slow inference must not keep the form open")
                    if (capture.busy) return
                    check(capture.lastResult === "saved" && !capture.opened, "successful save must close capture")
                    console.log("PASS: smaller font, wrapping, growth, shrinking, scroll, cursor, length limit and multiline keys")
                    Qt.quit()
                }
                step++
            } catch (error) { console.error("FAIL: " + error); Qt.quit() }
        }
    }
    Timer { interval: 7000; running: true; onTriggered: { console.error("FAIL: timeout"); Qt.quit() } }
}
QML
CAPTURE_CONFIG="$fixture/config.toml" CAPTURE_INBOX=inbox CAPTURE_LOCK_FILE="$fixture/capture.lock" CAPTURE_VAULT="$fixture/home" CAPTURE_CODEX="$fixture/slow-codex" CAPTURE_TITLE_TIMEOUT=1 HOME="$fixture/home" QT_QPA_PLATFORMTHEME=generic QT_STYLE_OVERRIDE=Basic QT_QUICK_BACKEND=software timeout 10s quickshell -p "$fixture/shell.qml" --no-duplicate > "$fixture/log" 2>&1 || { cat "$fixture/log"; exit 1; }
cat "$fixture/log"
rg -q 'PASS: smaller font' "$fixture/log"
! rg -q 'FAIL:' "$fixture/log"
python3 - "$fixture/home" <<'VERIFY'
from pathlib import Path
import sys
vault = Path(sys.argv[1])
notes = list((vault / 'inbox').glob('*.md'))
assert len(notes) == 1
text = notes[0].read_text()
assert 'category: "fact"' in text
assert text.split('## Исходная формулировка\n\n', 1)[1] == 'Первая\nВторая'
assert not (vault / 'private/daily').exists()
VERIFY
