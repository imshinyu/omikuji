import QtQuick
import ".."

Item {
    id: btn

    property bool isRunning: false
    property real uiScale: 1.0

    signal playClicked()
    signal stopClicked()

    readonly property color bgColor: isRunning ? theme.error : theme.accent
    readonly property color textColor: isRunning ? "#ffffff" : theme.accentOn

    implicitWidth: Math.max(180 * uiScale, label.implicitWidth + 56 * uiScale)
    implicitHeight: 60 * uiScale

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 16 * btn.uiScale
        color: mouse.containsMouse ? Qt.lighter(btn.bgColor, 1.12) : btn.bgColor

        scale: mouse.containsPress ? 0.96 : (mouse.containsMouse ? 1.04 : 1.0)
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.isRunning ? qsTr("Stop") : qsTr("Play")
        color: btn.textColor
        font.pixelSize: 22 * btn.uiScale
        font.weight: Font.Bold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.isRunning ? btn.stopClicked() : btn.playClicked()
    }
}
