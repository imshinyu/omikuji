import QtQuick
import QtQuick.Layouts
import "../widgets"

DialogCard {
    id: root

    property string gameId: ""
    property string appId: ""
    property string displayName: ""
    property string fromVersion: ""
    property string toVersion: ""
    property real downloadBytes: 0
    property bool canDiff: true
    property bool deltaSupported: true

    signal updateRequested(string gameId, string appId, string fromVersion)
    signal runAnywayRequested(string gameId)
    signal dismissed(string gameId)

    maxWidth: 460

    function show(payload) {
        if (payload) {
            gameId = payload.gameId || ""
            appId = payload.appId || ""
            displayName = payload.displayName || ""
            fromVersion = payload.fromVersion || ""
            toVersion = payload.toVersion || ""
            downloadBytes = payload.downloadBytes || 0
            canDiff = payload.canDiff === undefined ? true : payload.canDiff
            deltaSupported = payload.deltaSupported === undefined ? true : payload.deltaSupported
        }
        open()
    }
    function hide() { close() }

    function formatBytes(b) {
        if (b >= 1024 * 1024 * 1024) return (b / (1024 * 1024 * 1024)).toFixed(2) + " GB"
        if (b >= 1024 * 1024) return (b / (1024 * 1024)).toFixed(1) + " MB"
        if (b >= 1024) return (b / 1024).toFixed(1) + " KB"
        return b + " B"
    }

    onCloseRequested: { root.dismissed(root.gameId); root.close() }

    body: ColumnLayout {
        width: parent.width
        spacing: theme.space.lg

        RowLayout {
            Layout.fillWidth: true
            spacing: theme.space.sm

            Rectangle {
                width: 36; height: 36; radius: 18
                color: theme.alpha(theme.accent, 0.15)
                Text {
                    anchors.centerIn: parent
                    text: "↻"
                    color: theme.accent
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: "Update available"
                    color: theme.text
                    font.pixelSize: theme.type.title.size
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                }
                Text {
                    Layout.fillWidth: true
                    text: root.displayName
                    color: theme.textMuted
                    font.pixelSize: theme.type.caption.size
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: theme.radius.md
            color: theme.alpha(theme.text, 0.04)
            implicitHeight: versionCol.implicitHeight + theme.space.lg

            ColumnLayout {
                id: versionCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: theme.space.md
                spacing: theme.space.sm

                RowLayout {
                    Layout.fillWidth: true
                    spacing: theme.space.sm
                    Text { text: root.fromVersion || "?"; color: theme.textMuted; font.pixelSize: 14; font.family: "monospace" }
                    Text { text: "→"; color: theme.textMuted; font.pixelSize: 14 }
                    Text { text: root.toVersion || "?"; color: theme.accent; font.pixelSize: 14; font.family: "monospace"; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        if (root.canDiff) {
                            return root.downloadBytes > 0
                                ? ("Delta update · " + root.formatBytes(root.downloadBytes))
                                : "Delta update"
                        }
                        let name = root.displayName || "the game"
                        if (!root.deltaSupported) {
                            return "Seems there's an update for " + name + ", however, it doesn't handle delta patches. Wanna reinstall the game to update?"
                        }
                        return "Your install is too old for a delta patch. Reinstall " + name + " to update?"
                    }
                    color: theme.textMuted
                    font.pixelSize: theme.type.caption.size
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    actions: Row {
        spacing: theme.space.sm

        M3Button {
            text: "Cancel"
            variant: "text"
            onClicked: { root.dismissed(root.gameId); root.close() }
        }
        M3Button {
            text: "Run anyway"
            variant: "tonal"
            onClicked: { root.runAnywayRequested(root.gameId); root.close() }
        }
        M3Button {
            text: root.canDiff ? "Update" : "Reinstall"
            variant: "filled"
            onClicked: {
                root.updateRequested(root.gameId, root.appId, root.fromVersion)
                root.close()
            }
        }
    }
}
