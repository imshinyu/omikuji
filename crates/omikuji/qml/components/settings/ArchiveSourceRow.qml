import QtQuick

import "../widgets"
import "../dialogs"

Item {
    id: root

    property string sourceName: ""
    property string sourceKind: ""
    property int    installedCount: 0

    property bool   showAutoInject: false
    property var    installedVersions: []
    property string activeVersion: ""

    signal manageClicked()
    signal autoInjectChanged(string tag)

    height: showAutoInject ? 100 : 56

    Rectangle {
        anchors.fill: parent
        color: theme.cardBg
        radius: 10
        border.width: 1
        border.color: theme.surfaceBorder
    }

    Item {
        id: topRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: manageBtn.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Row {
                    spacing: 8
                    Text {
                        text: root.sourceName
                        color: theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        height: 16
                        width: kindLabel.width + 12
                        radius: theme.radius.sm
                        color: theme.alpha(theme.accent, 0.13)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            id: kindLabel
                            anchors.centerIn: parent
                            text: root.sourceKind
                            color: theme.accent
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 0.6
                        }
                    }
                }

                Text {
                    text: root.installedCount === 0
                        ? "No versions installed"
                        : root.installedCount === 1
                            ? "1 version installed"
                            : root.installedCount + " versions installed"
                    color: root.installedCount > 0 ? theme.success : theme.textSubtle
                    font.pixelSize: 12
                }
            }
        }

        Rectangle {
            id: manageBtn
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: manageLabel.implicitWidth + 28
            height: 32
            radius: theme.radius.lg
            color: btnArea.containsMouse
                ? theme.alpha(theme.text, 0.08)
                : "transparent"
            border.width: 1
            border.color: theme.surfaceBorder

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: manageLabel
                anchors.centerIn: parent
                text: "Manage"
                color: theme.text
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            MouseArea {
                id: btnArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.manageClicked()
            }
        }
    }

    Rectangle {
        visible: root.showAutoInject
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: topRow.bottom
        height: 1
        color: theme.separator
    }

    Item {
        id: autoInjectRow
        visible: root.showAutoInject
        anchors.top: topRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Text {
            id: autoInjectLabel
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Auto install on prefix"
            color: theme.text
            font.pixelSize: 13
        }

        Rectangle {
            id: picker
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            // max 240 so long tags elide instead of pushing off-screen, no min so short values shrink naturally
            width: Math.min(240, pickerRow.implicitWidth + 20)
            height: 32
            radius: theme.radius.lg
            color: pickerArea.containsMouse
                ? theme.alpha(theme.text, 0.08)
                : "transparent"
            border.width: 1
            border.color: theme.surfaceBorder

            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: pickerRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    id: pickerLabel
                    text: root.activeVersion === "" ? "Disabled" : root.activeVersion
                    color: root.activeVersion === "" ? theme.textMuted : theme.text
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 200)
                    anchors.verticalCenter: parent.verticalCenter
                }

                SvgIcon {
                    id: chevron
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron_left"
                    size: 14
                    color: theme.textMuted
                    rotation: menu.visible ? 90 : -90
                    Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
            }

            MouseArea {
                id: pickerArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // debounce becuase CloseOnPressOutside eats the click before this fires and would instantly reopen
                    if (Date.now() - menu.lastClosedAt < 150) return
                    menu.items = root._buildMenuItems()
                    menu.minWidth = picker.width - 16
                    menu.openBelow(picker)
                }
            }
        }

        ContextMenu {
            id: menu
            onItemClicked: (action) => {
                if (action !== root.activeVersion) root.autoInjectChanged(action)
            }
        }
    }

    function _buildMenuItems() {
        let items = [{ text: "Disabled", action: "" }]
        for (let i = 0; i < installedVersions.length; i++) {
            let tag = installedVersions[i]
            items.push({ text: tag, action: tag })
        }
        return items
    }
}
