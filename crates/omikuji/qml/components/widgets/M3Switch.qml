import QtQuick

Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 44
    implicitHeight: 26

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? theme.accent : "transparent"
        border.width: 2
        border.color: root.checked ? theme.accent : theme.alpha(theme.text, 0.25)

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }

    Rectangle {
        id: thumb
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property int pad: 3
        readonly property int offSize: 14
        readonly property int onSize: 20
        readonly property real travel: (parent.width - onSize) / 2 - pad

        anchors.horizontalCenterOffset: root.checked ? travel : -travel
        width: mouseArea.pressed ? 22 : (root.checked ? onSize : offSize)
        height: width
        radius: width / 2
        color: root.checked ? theme.accentText : theme.alpha(theme.text, 0.45)

        Behavior on anchors.horizontalCenterOffset {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
