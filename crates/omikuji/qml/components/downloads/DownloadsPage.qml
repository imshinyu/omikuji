import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "."
import "../widgets"

Item {
    id: root

    property var downloadModel: null
    property var componentsBridge: null

    // paused when off-screen so the wave bar doesnt run the scene graph hot at 60fps behind a hidden panel (thanks for having me to do this manually. fabolous.)
    property bool pageVisible: true

    // bubbled to main so the confirm dialog dims the whole window not just this pane
    signal cancelRequested(string id, string displayName)

    // patched row-by-row so we dont reparse the full json on every progress tick
    property var componentStatuses: ({})
    readonly property var componentOrder: ["umu-run", "hpatchz", "legendary", "jadeite", "egl-dummy"]
    readonly property bool componentsVisible: {
        if (!componentsBridge) return false
        if (componentsBridge.inProgress) return true
        if (componentsBridge.pendingCount > 0) return true
        for (let k in componentStatuses) {
            if (componentStatuses[k] && componentStatuses[k].status === "failed") return true
        }
        return false
    }

    function syncComponentStatuses() {
        if (!componentsBridge) return
        try {
            componentStatuses = JSON.parse(componentsBridge.statusJson())
        } catch (e) {
            console.warn("[downloads] bad components statusJson:", e)
        }
    }

    Component.onCompleted: syncComponentStatuses()

    Connections {
        target: componentsBridge
        function onComponentStarted(name) { root.syncComponentStatuses() }
        function onComponentProgress(name, phase, percent) {
            let s = root.componentStatuses[name] || {}
            s.status = phase
            s.percent = percent
            let next = Object.assign({}, root.componentStatuses)
            next[name] = s
            root.componentStatuses = next
        }
        function onComponentCompleted(name, version) { root.syncComponentStatuses() }
        function onComponentFailed(name, error) { root.syncComponentStatuses() }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 24
        visible: (!downloadModel || downloadModel.count === 0) && !componentsVisible

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                name: "download"
                size: 48
                color: theme.textFaint
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No active downloads")
                color: theme.textMuted
                font.pixelSize: 16
                font.weight: Font.Medium
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Install a game from one of the connected stores to see it here.")
                color: theme.textFaint
                font.pixelSize: 13
            }
        }
    }

    Flickable {
        id: listFlick
        anchors.fill: parent
        anchors.margins: 24
        clip: true
        contentHeight: listCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 3000
        visible: (downloadModel && downloadModel.count > 0) || root.componentsVisible

        ColumnLayout {
            id: listCol
            width: parent.width
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.componentsVisible

                Text {
                    text: qsTr("Runtime components")
                    color: theme.textMuted
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    textFormat: Text.PlainText
                }

                Repeater {
                    model: root.componentOrder
                    delegate: ComponentRow {
                        required property string modelData
                        Layout.fillWidth: true
                        name: modelData
                        entry: root.componentStatuses[modelData] || ({})
                        onRetryRequested: {
                            if (root.componentsBridge) root.componentsBridge.installAll()
                        }
                    }
                }
            }

            // active downloads only, completed rows split into their own section so the in-progress list stays readable
            ColumnLayout {
                id: activeBox
                Layout.fillWidth: true
                spacing: 10
                visible: downloadModel && (downloadModel.count - downloadModel.completedCount) > 0

                Text {
                    text: qsTr("Downloads")
                    color: theme.textMuted
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    visible: root.componentsVisible
                }

                Repeater {
                    model: root.downloadModel
                    delegate: DownloadRow {
                        Layout.fillWidth: true
                        downloadModel: root.downloadModel
                        pageVisible: root.pageVisible
                        visible: status !== "Completed"
                        onCancelRequested: (id, displayName) => root.cancelRequested(id, displayName)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: downloadModel && downloadModel.completedCount > 0
                Layout.topMargin: {
                    let viewport = listFlick.height
                    let above = activeBox.visible ? activeBox.implicitHeight + listCol.spacing : 0
                    return Math.max(20, viewport * 0.4 - above)
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: theme.alpha(theme.text, 0.08)
                }

                Text {
                    text: qsTr("Completed")
                    color: theme.text
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.downloadModel
                    delegate: DownloadRow {
                        Layout.fillWidth: true
                        downloadModel: root.downloadModel
                        pageVisible: root.pageVisible
                        visible: status === "Completed"
                        onCancelRequested: (id, displayName) => root.cancelRequested(id, displayName)
                    }
                }
            }
        }
    }
}
