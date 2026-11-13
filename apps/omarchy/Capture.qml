import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui
import "Capture.js" as Capture

Item {
    id: root
    property var shell: null
    property var manifest: null
    property bool opened: false
    property alias category: categorySelector.value
    property string targetDate: ""
    readonly property string previewText: root.category === "event" ? Capture.bullet(input.text, "event") : ""
    readonly property string eventWarning: root.category === "event" && Capture.eventInput(input.text).invalidTime ? "Time not recognized · saved as text" : ""
    readonly property var categoryOptions: Capture.categoryOptions
    property string errorText: ""
    property string lastResult: ""
    property bool busy: false
    property string helperPath: decodeURIComponent(Qt.resolvedUrl("capture.py").toString().replace(/^file:\/\//, ""))
    property string pendingPayload: ""
    property string submissionSignature: ""
    property string submissionId: ""
    property string submissionRequestId: ""
    property string submissionTimestamp: ""
    property int submissionAttempts: 0
    readonly property var borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))

    function open(payloadJson) {
        if (root.busy)
            return false;
        var payload;
        try {
            payload = JSON.parse(payloadJson || "{}");
            if (!payload || typeof payload !== "object" || Array.isArray(payload))
                throw new Error("Invalid capture request");
            var date = payload.date === undefined ? Capture.localDate(new Date()) : payload.date;
            if (!Capture.validDate(date))
                throw new Error("Invalid capture date");
        } catch (error) {
            root.lastResult = "invalid-request";
            return false;
        }
        root.targetDate = date;
        if (payload.category !== undefined)
            root.category = Capture.normalizedCategory(payload.category);
        root.errorText = "";
        root.opened = true;
        Qt.callLater(function () {
            input.forceActiveFocus();
        });
        return true;
    }
    function close() {
        root.opened = false;
    }
    function dismiss() {
        hideOverlay();
    }
    function hideOverlay() {
        root.close();
        if (root.shell)
            root.shell.hide("eugene.daily-capture");
    }
    function submit() {
        if (root.busy)
            return;
        if (!input.text.trim())
            return;
        var signature = JSON.stringify({text: input.text, category: root.category, date: root.targetDate});
        if (signature !== root.submissionSignature) {
            var now = new Date();
            root.submissionId = Capture.captureId(now);
            root.submissionAttempts = 0;
            root.submissionRequestId = Capture.newRequestId();
            root.submissionTimestamp = now.toISOString();
            root.submissionSignature = signature;
        }
        var createdAt = new Date(root.submissionTimestamp);
        var payload = Capture.request(input.text, root.category, createdAt, root.targetDate, root.submissionId, root.submissionRequestId);
        var command = Capture.saveCommand(input.text, root.category, createdAt, root.targetDate, root.submissionId, root.helperPath, root.submissionRequestId);
        if (!command.length)
            return;
        payload.retry = root.submissionAttempts > 0;
        root.submissionAttempts++;
        root.pendingPayload = JSON.stringify(payload);
        root.errorText = "";
        launcher.command = command;
        root.busy = true;
        launcher.running = true;
    }

    Process {
        id: launcher
        stdinEnabled: true
        onStarted: write(root.pendingPayload + "\n")
        stdout: StdioCollector { id: saveOutput; waitForEnd: true }
        onExited: function (code) {
            root.busy = false;
            var result = null;
            try { result = JSON.parse(saveOutput.text); } catch (error) {}
            if (code === 0 && result && result.requestId === root.submissionRequestId && /^\d{12}$/.test(result.id) && typeof result.path === "string") {
                root.lastResult = "saved";
                input.text = "";
                root.category = "";
                root.pendingPayload = "";
                root.submissionSignature = "";
                root.submissionId = "";
                root.submissionRequestId = "";
                root.submissionTimestamp = "";
                root.submissionAttempts = 0;
                root.hideOverlay();
            } else {
                root.lastResult = "failed";
                root.errorText = "Could not save the capture. Your text is still here; press Enter to retry.";
                Qt.callLater(function () {
                    input.forceActiveFocus();
                });
            }
        }
    }
    IpcHandler {
        target: "eugene.daily-capture"
        function formatPreview(): string {
            return Capture.bullet("Example");
        }
        function status(): string {
            return JSON.stringify({
                opened: root.opened,
                writeMode: "inbox",
                titleMode: "background",
                busy: root.busy,
                date: root.targetDate,
                category: root.category,
                lastResult: root.lastResult
            });
        }
    }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        WlrLayershell.namespace: "omarchy-daily-capture"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: Color.menu.scrim
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }

        BorderSurface {
            id: card
            anchors.centerIn: parent
            width: Math.min(Style.space(460), panel.width - Style.gapsOut * 2)
            height: card.contentTopInset + card.contentBottomInset + form.implicitHeight
            radius: Style.cornerRadius
            color: Color.menu.background
            borderSpec: root.borderSpec
            padding: Style.spacing.panelPadding
            MouseArea {
                anchors.fill: parent
                onClicked: input.forceActiveFocus()
            }

            Column {
                id: form
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: card.contentTopInset
                anchors.leftMargin: card.contentLeftInset
                anchors.rightMargin: card.contentRightInset
                spacing: Style.spacing.controlGap

                Text {
                    id: dateLabel
                    width: parent.width
                    text: "Capture · " + root.targetDate
                    textFormat: Text.PlainText
                    color: Color.menu.text
                    font.family: Style.font.menuFamily
                    font.pixelSize: Style.font.body
                }

                Flickable {
                    id: editorViewport
                    objectName: "captureEditorViewport"
                    width: parent.width
                    readonly property real minimumHeight: Style.space(34)
                    readonly property real maximumHeight: Math.max(minimumHeight, panel.height - Style.gapsOut * 2 - card.contentTopInset - card.contentBottomInset - dateLabel.implicitHeight - controls.implicitHeight - form.spacing * 2)
                    height: Math.min(maximumHeight, Math.max(minimumHeight, input.contentHeight))
                    contentWidth: width
                    contentHeight: input.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height
                    function revealCursor() {
                        var cursor = input.cursorRectangle;
                        if (cursor.y < contentY)
                            contentY = cursor.y;
                        else if (cursor.y + cursor.height > contentY + height)
                            contentY = cursor.y + cursor.height - height;
                        contentY = Math.max(0, Math.min(contentY, contentHeight - height));
                    }
                    onHeightChanged: Qt.callLater(revealCursor)
                    Controls.ScrollBar.vertical: Controls.ScrollBar {}

                    TextEdit {
                        id: input
                        width: editorViewport.width - Style.space(12)
                        height: Math.max(editorViewport.minimumHeight, contentHeight)
                        activeFocusOnTab: true
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.body
                        color: Color.menu.text
                        selectionColor: Color.menu.border
                        selectedTextColor: Color.menu.text
                        clip: true
                        selectByMouse: true
                        textFormat: TextEdit.PlainText
                        wrapMode: TextEdit.Wrap
                        readOnly: root.busy
                        readonly property int maximumLength: 8000
                        onTextChanged: {
                            if (length > maximumLength)
                                remove(maximumLength, length);
                            Qt.callLater(editorViewport.revealCursor);
                        }
                        onCursorRectangleChanged: editorViewport.revealCursor()
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                root.dismiss();
                            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                event.accepted = true;
                                nextItemInFocusChain(event.key !== Qt.Key_Backtab && !(event.modifiers & Qt.ShiftModifier)).forceActiveFocus(Qt.TabFocusReason);
                            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier) && !inputMethodComposing) {
                                event.accepted = true;
                                root.submit();
                            }
                        }

                        Text {
                            objectName: "capturePlaceholder"
                            anchors.fill: parent
                            text: root.busy ? "Saving…" : root.category === "event" ? "19:30 Event · optional time" : "Capture a thought…"
                            textFormat: Text.PlainText
                            font: input.font
                            color: Color.menu.text
                            opacity: 0.58
                            visible: !input.text
                        }
                    }
                }

                Column {
                    id: controls
                    width: parent.width
                    spacing: form.spacing
                    Dropdown {
                        id: categorySelector
                        width: parent.width
                        label: "Category"
                        options: root.categoryOptions
                        onChanged: function (value) {
                            Qt.callLater(function () {
                                input.forceActiveFocus();
                            });
                        }
                    }

                    Text {
                        objectName: "eventPreview"
                        width: parent.width
                        text: root.previewText
                        textFormat: Text.PlainText
                        color: Color.menu.text
                        opacity: 0.65
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.bodySmall
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: !!text
                    }

                    Text {
                        width: parent.width
                        text: root.eventWarning
                        textFormat: Text.PlainText
                        color: Color.menu.text
                        opacity: 0.65
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.bodySmall
                        wrapMode: Text.WordWrap
                        visible: !!text
                    }

                    Text {
                        width: parent.width
                        text: "Enter — save · Shift+Enter — new line"
                        textFormat: Text.PlainText
                        color: Color.menu.text
                        opacity: 0.65
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.bodySmall
                        wrapMode: Text.Wrap
                    }

                    Text {
                        id: errorLabel
                        width: parent.width
                        text: root.errorText
                        textFormat: Text.PlainText
                        color: Color.menu.text
                        font.family: Style.font.menuFamily
                        font.pixelSize: Style.font.body
                        wrapMode: Text.WordWrap
                        visible: !!root.errorText
                    }
                }
            }
        }
    }
}
