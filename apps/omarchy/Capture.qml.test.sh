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
python3 - "$fixture/save-without-ack.py" "$source_dir/capture.py" <<'FIXTURE'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text("import subprocess, sys\nsubprocess.run([sys.executable, " + repr(sys.argv[2]) + "], input=sys.stdin.readline(), text=True, stdout=subprocess.DEVNULL, check=True)\nraise SystemExit(1)\n")
FIXTURE
cat > "$fixture/shell.qml" <<'QML'
//@ pragma OmarchyLoadPatch
import QtQuick
import "CapturePlugin" as Plugin
import "CapturePlugin/Capture.js" as Formatter
Item {
    property string savedHelper: ""
    property string firstId: ""
    property bool retrying: false
    Plugin.Capture { id: capture }
    Timer {
        id: saved
        interval: 20
        repeat: true
        property int attempts: 0
        onTriggered: {
            attempts++
            if (capture.busy && attempts < 200) return
            stop()
            if (!retrying) {
                check(capture.lastResult === "failed" && capture.opened, "write failure keeps modal open")
                check(JSON.parse(capture.pendingPayload).id === firstId, "failed save retains identity")
                capture.helperPath = savedHelper
                retrying = true
                capture.submit()
                check(JSON.parse(capture.pendingPayload).id === firstId, "retry reuses identity")
                attempts = 0
                start()
                return
            }
            if (capture.lastResult === "saved" && !capture.opened && capture.category === "")
                console.log("PASS: modal submission saved to inbox and reset; lost save acknowledgement retried with same ID")
            else console.error("FAIL: modal save failed: " + capture.lastResult)
            Qt.quit()
        }
    }
    function find(node, predicate, visited) {
        if (!node || visited.indexOf(node) >= 0) return null
        visited.push(node)
        if (predicate(node)) return node
        var lists = [node.children || [], node.data || [], node.contentItem ? [node.contentItem] : []]
        for (var l = 0; l < lists.length; l++) {
            for (var i = 0; i < lists[l].length; i++) {
                var result = find(lists[l][i], predicate, visited)
                if (result) return result
            }
        }
        return null
    }
    function check(condition, message) { if (!condition) throw new Error(message) }
    Component.onCompleted: Qt.callLater(function() {
        try {
            var dropdown = find(capture, function(node) { return node.label === "Category" }, [])
            check(dropdown !== null, "category dropdown must exist")
            dropdown.value = "idea"
            dropdown.changed("idea")
            check(capture.category === "idea", "selected category must reach save state")
            var now = new Date(2026, 9, 18, 12, 30)
            var request = Formatter.request("Example", capture.category, now, "2026-10-18", Formatter.captureId(now), Formatter.newRequestId())
            check(request.category === "idea" && request.text === "Example", "visible category must reach the capture payload")
            capture.category = ""
            check(dropdown.value === "", "reset after successful save must also reset the visible category")
            request = Formatter.request("Second", capture.category, now, "2026-10-18", Formatter.captureId(now), Formatter.newRequestId())
            check(request.category === "", "reset must produce an uncategorized capture")
            dropdown.value = "fact"
            dropdown.changed("fact")
            capture.close()
            check(capture.category === dropdown.value && capture.category === "fact", "dismissed draft must retain the same visible and saved category")
            check(capture.open('{"date":"2027-01-01","category":"task"}') === true, "dated request must open")
            check(capture.targetDate === "2027-01-01" && dropdown.value === "task", "task request must select date and visible category")
            now = new Date(2027, 0, 2, 0, 1)
            request = Formatter.request("Task", capture.category, now, capture.targetDate, Formatter.captureId(now), Formatter.newRequestId())
            check(request.contextDate === "2027-01-01" && request.capturedAt === now.toISOString(), "submission after midnight must separate context date and actual time")
            capture.close()
            check(capture.open('{"date":"2026-09-30","category":"event"}') === true, "event request must open")
            check(capture.targetDate === "2026-09-30" && dropdown.value === "event", "event request must select date and category")
            capture.close()
            check(capture.open('{"date":"2026-02-30"}') === false && !capture.opened, "invalid date must not open")
            check(capture.open('broken json') === false && !capture.opened, "invalid payload must not open")
            check(capture.open('{"date":"' + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + '"}') === true, "menu request must accept explicit today")
            check(capture.targetDate === Qt.formatDateTime(new Date(), "yyyy-MM-dd"), "menu date must replace calendar date")
            capture.close()
            console.log("PASS: category selection, success reset and draft dismissal stay synchronized")
            capture.open('{"date":"2027-01-01","category":"event"}')
            var input = find(capture, function(node) { return node.maximumLength === 8000 }, [])
            check(input !== null, "capture input must exist")
            input.text = "25:30 Встреча"
            check(capture.eventWarning === "Time not recognized · saved as text", "invalid time needs a non-blocking hint")
            check(capture.previewText === "- [event] 25:30 Встреча", "invalid time must remain in preview")
            input.text = "Встреча"
            check(capture.eventWarning === "" && capture.previewText === "- [event] Встреча", "no time means no timestamp and no warning")
            input.text = "9:30 — Calendar event from modal"
            check(capture.previewText === "- 9:30 [event] Calendar event from modal", "preview must show event start time")
            check(capture.eventWarning === "", "valid time must clear hint")
            var preview = find(capture, function(node) { return node.objectName === "eventPreview" }, [])
            check(preview !== null && preview.text === capture.previewText, "visible preview must use saved format")
            var placeholder = find(capture, function(node) { return node.objectName === "capturePlaceholder" }, [])
            check(placeholder !== null && placeholder.text.indexOf("19:30") >= 0, "event placeholder must explain optional time")
            capture.category = "task"
            check(capture.previewText === "" && placeholder.text === "Capture a thought…", "event hints must disappear for other categories")
            capture.category = "event"
            savedHelper = capture.helperPath
            capture.helperPath = decodeURIComponent(Qt.resolvedUrl("save-without-ack.py").toString().replace(/^file:\/\//, ""))
            capture.submit()
            firstId = JSON.parse(capture.pendingPayload).id
            check(capture.open('{"date":"2026-01-01","category":"task"}') === false, "busy capture must keep the in-flight date")
            saved.start()
            return
        } catch (error) { console.error("FAIL: " + error) }
        Qt.callLater(Qt.quit)
    })
}
QML
CAPTURE_CONFIG="$fixture/config.toml" CAPTURE_INBOX=inbox CAPTURE_LOCK_FILE="$fixture/capture.lock" CAPTURE_VAULT="$fixture/home" CAPTURE_CODEX="$(command -v false)" HOME="$fixture/home" QT_QPA_PLATFORMTHEME=generic QT_STYLE_OVERRIDE=Basic QT_QUICK_BACKEND=software timeout 15s quickshell -p "$fixture/shell.qml" --no-duplicate > "$fixture/log" 2>&1
cat "$fixture/log"
rg -q 'PASS: category selection' "$fixture/log"
! rg -q 'FAIL:' "$fixture/log"
rg -q 'PASS: modal submission' "$fixture/log"
python3 - "$fixture/home" <<'VERIFY'
from pathlib import Path
import sys
vault = Path(sys.argv[1])
notes = list((vault / 'inbox').glob('*.md'))
assert len(notes) == 1
text = notes[0].read_text()
assert 'contextDate: "2027-01-01"' in text
assert 'category: "event"' in text
assert text.endswith('9:30 — Calendar event from modal')
assert not (vault / 'private/daily').exists()
VERIFY
! rg -q 'Binding loop detected' "$fixture/log"
