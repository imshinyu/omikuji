import QtQuick
import QtQuick.Controls

import "../widgets"

Item {
    id: root

    property string currentTabLabel: ""
    property bool showAddButton: true
    property bool showSearch: true
    property bool showDisplayOptions: false
    property real zoomValue: 1.0
    property int spacingValue: 16
    property alias searchText: searchInput.text

    signal addClicked()
    signal zoomMoved(real value)
    signal spacingMoved(int value)
    signal consoleModeClicked()

    height: 54

    function defocusSearch() {
        searchInput.focus = false
    }

    // opaque fill becuase witout it lower-z dropdown popups bleed through the empty bar areas
    Rectangle {
        anchors.fill: parent
        color: theme.navBg
    }

    Text {
        id: titleText
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.width * 0.5)
        text: root.currentTabLabel
        color: theme.text
        font.pixelSize: 20
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    FieldSurface {
        id: searchBar
        anchors.centerIn: parent
        width: Math.min(360, parent.width * 0.4)
        height: 34
        radius: 17
        focused: searchInput.activeFocus
        visible: root.showSearch

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            SvgIcon {
                name: "search"
                size: 16
                color: theme.textSubtle
                anchors.verticalCenter: parent.verticalCenter
            }

            TextInput {
                id: searchInput
                width: searchBar.width - 44
                color: theme.text
                font.pixelSize: 14
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                selectionColor: theme.accent
                selectedTextColor: theme.accentText

                Text {
                    anchors.fill: parent
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search games..."
                    color: theme.textSubtle
                    font.pixelSize: 14
                    visible: !searchInput.text && !searchInput.activeFocus
                }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        IconButton {
            id: consoleBtn
            icon: "sports_esports"
            size: 32
            rounded: true
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.consoleModeClicked()

            Tooltip {
                text: "Console Mode"
                tipVisible: consoleBtn.hovered
                y: parent.height + 8
            }
        }

        IconButton {
            id: displayBtn
            icon: "tune"
            size: 32
            rounded: true
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showDisplayOptions
            onClicked: displayPopup.visible ? displayPopup.close() : displayPopup.open()
        }

        IconButton {
            icon: "add"
            size: 32
            rounded: true
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showAddButton
            onClicked: root.addClicked()
        }
    }

    DisplayOptionsPopup {
        id: displayPopup
        parent: displayBtn
        x: displayBtn.width - width
        y: displayBtn.height + 8

        zoomValue: root.zoomValue
        spacingValue: root.spacingValue
        onZoomMoved: (v) => root.zoomMoved(v)
        onSpacingMoved: (v) => root.spacingMoved(v)
    }
}
