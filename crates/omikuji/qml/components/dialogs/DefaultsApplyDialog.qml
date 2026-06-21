import QtQuick
import QtQuick.Layouts
import "../widgets"

DialogCard {
    id: root

    property var defaults: null
    property var gameModel: null

    property var sectionLabels: ({
        "wine": "Wine (version, architecture)",
        "sync": "Sync (esync, fsync, ntsync)",
        "translation_layers": "Translation Layers (DXVK, VKD3D, …)",
        "compatibility": "Compatibility (BattlEye, EAC, FSR)",
        "display": "Display (DPI scaling)",
        "drivers": "Drivers (audio, graphics)",
        "dll_overrides": "DLL Overrides",
        "launch": "Launch (command prefix)",
        "environment": "Environment Variables",
        "graphics": "Graphics (MangoHUD, GPU)",
        "gamescope": "Gamescope",
        "performance": "Performance (gamemode, CPU limit)",
        "audio": "Audio (Pulse latency)",
        "power": "Power (prevent sleep)"
    })

    property var availableSections: []
    property var checkedSections: []
    property bool replaceMaps: false

    maxWidth: 520

    function show() {
        if (!defaults) return
        try { root.availableSections = JSON.parse(defaults.populatedSectionsJson()) }
        catch (e) { root.availableSections = [] }
        root.checkedSections = root.availableSections.slice()
        root.replaceMaps = false
        open()
    }

    function hide() { close() }

    function _toggle(sec) {
        let cur = root.checkedSections.slice()
        let idx = cur.indexOf(sec)
        if (idx === -1) cur.push(sec)
        else cur.splice(idx, 1)
        root.checkedSections = cur
    }

    function _apply() {
        if (!gameModel || root.checkedSections.length === 0) {
            close()
            return
        }
        let csv = root.checkedSections.join(",")
        gameModel.applyDefaultsToExistingGames(csv, root.replaceMaps)
        close()
    }

    onCloseRequested: root.close()

    body: ColumnLayout {
        width: parent.width
        spacing: theme.space.sm

        Text {
            text: "Apply defaults to existing games"
            color: theme.text
            font.pixelSize: theme.type.title.size
            font.weight: Font.DemiBold
        }

        Text {
            Layout.fillWidth: true
            text: "Sections you tick will be written to every game's TOML, overwriting their current values for those fields. Untouched sections stay as they are per-game."
            color: theme.textMuted
            font.pixelSize: 12
            wrapMode: Text.Wrap
            lineHeight: 1.35
        }

        Text {
            Layout.fillWidth: true
            text: "Nothing to apply — set some fields in the Defaults tab first."
            color: theme.textSubtle
            font.pixelSize: 13
            wrapMode: Text.Wrap
            visible: root.availableSections.length === 0
        }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(secList.height, 360)
            contentHeight: secList.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            visible: root.availableSections.length > 0

            Column {
                id: secList
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.availableSections

                    Item {
                        required property var modelData

                        width: parent.width
                        height: 40

                        readonly property bool selected: root.checkedSections.indexOf(modelData) !== -1

                        Rectangle {
                            anchors.fill: parent
                            radius: theme.radius.sm
                            color: rowHover.containsMouse
                                ? theme.alpha(theme.text, 0.06)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: theme.space.md

                            SvgIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: selected ? "check_box" : "check_box_outline_blank"
                                size: 20
                                color: selected ? theme.accent : theme.alpha(theme.text, 0.55)
                            }

                            Text {
                                text: root.sectionLabels[modelData] || modelData
                                color: theme.text
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._toggle(modelData)
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            visible: root.availableSections.length > 0
                && (root.checkedSections.indexOf("environment") !== -1
                 || root.checkedSections.indexOf("dll_overrides") !== -1)

            Rectangle {
                anchors.fill: parent
                radius: theme.radius.sm
                color: replaceHover.containsMouse
                    ? theme.alpha(theme.text, 0.06)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: theme.space.md

                SvgIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.replaceMaps ? "check_box" : "check_box_outline_blank"
                    size: 20
                    color: root.replaceMaps ? theme.accent : theme.alpha(theme.text, 0.55)
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        text: "Replace env / DLL tables"
                        color: theme.text
                        font.pixelSize: 13
                    }
                    Text {
                        text: root.replaceMaps
                            ? "wipes the game's keys, then writes the global ones"
                            : "merges global keys into the game (game keys win on conflict)"
                        color: theme.textSubtle
                        font.pixelSize: 11
                    }
                }
            }

            MouseArea {
                id: replaceHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.replaceMaps = !root.replaceMaps
            }
        }

    }

    footerLeft: Text {
        height: 36
        verticalAlignment: Text.AlignVCenter
        text: root.gameModel ? "Affects " + root.gameModel.count + " game" + (root.gameModel.count === 1 ? "" : "s") : ""
        color: theme.textSubtle
        font.pixelSize: 12
        visible: text.length > 0
    }

    actions: Row {
        spacing: theme.space.sm

        M3Button {
            text: "Cancel"
            variant: "text"
            onClicked: root.close()
        }

        M3Button {
            text: "Apply"
            variant: "filled"
            enabled: root.checkedSections.length > 0
            onClicked: root._apply()
        }
    }
}
