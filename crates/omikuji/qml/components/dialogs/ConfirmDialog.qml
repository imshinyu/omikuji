import QtQuick
import "../widgets"

DialogCard {
    id: root

    property string message: ""
    property string confirmText: qsTr("Confirm")
    property string cancelText: qsTr("Cancel")
    property bool destructive: false
    property var payload: null

    signal confirmed(var payload)
    signal cancelled(var payload)

    maxWidth: 420

    function show(payload_) {
        payload = payload_ === undefined ? null : payload_
        open()
    }
    function hide() { close() }

    onCloseRequested: { root.cancelled(root.payload); root.close() }

    body: Text {
        width: parent.width
        text: root.message
        color: theme.textMuted
        font.pixelSize: theme.type.body.size
        wrapMode: Text.Wrap
        visible: text.length > 0
    }

    actions: Row {
        spacing: theme.space.sm

        M3Button {
            text: root.cancelText
            variant: "text"
            onClicked: { root.cancelled(root.payload); root.close() }
        }
        M3Button {
            text: root.confirmText
            variant: "filled"
            danger: root.destructive
            onClicked: { root.confirmed(root.payload); root.close() }
        }
    }
}
