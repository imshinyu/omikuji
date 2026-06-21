import QtQuick
import QtQuick.Layouts
import "."


// built on ListView so add/remove gives smooth stack shifts, not instant pops
Item {
    id: root

    property int dismissMs: 4500
    property int maxVisible: 5
    readonly property int toastWidth: 340
    readonly property int toastSpacing: 10
    readonly property int toastRadius: 18

    property int nextId: 0

    function show(level, title, message) {
        while (toastModel.count >= root.maxVisible) {
            toastModel.remove(toastModel.count - 1)
        }
        toastModel.insert(0, {
            toastId: root.nextId++,
            level: String(level || "info"),
            title: String(title || ""),
            message: String(message || "")
        })
    }

    ListModel { id: toastModel }

    ListView {
        id: stack
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        width: root.toastWidth
        height: Math.max(40, parent.height - 36)
        spacing: root.toastSpacing
        interactive: false
        clip: false
        model: toastModel

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    properties: "opacity"
                    from: 0; to: 1
                    duration: 220
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    properties: "x"
                    from: stack.width + 24
                    to: 0
                    duration: 260
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.1
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    properties: "opacity"
                    to: 0
                    duration: 180
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    properties: "x"
                    to: stack.width + 24
                    duration: 200
                    easing.type: Easing.InCubic
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        delegate: Rectangle {
            id: toast
            required property int index
            required property int toastId
            required property string level
            required property string title
            required property string message

            width: root.toastWidth
            height: toastCol.implicitHeight + 22
            radius: root.toastRadius
            color: theme.popup
            border.width: 1
            border.color: theme.alpha(theme.text, 0.08)

            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: -3
                radius: parent.radius
                color: "transparent"
                border.width: 0
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: parent.radius + 2
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.rgba(0, 0, 0, 0.08)
                    opacity: 0.5
                }
            }

            Rectangle {
                id: strip
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height - 22
                radius: width / 2
                color: {
                    switch (toast.level) {
                        case "success": return theme.success
                        case "warning": return theme.warning
                        case "error":   return theme.error
                        default:        return theme.accent
                    }
                }
            }

            Column {
                id: toastCol
                anchors.left: strip.right
                anchors.right: closeBtn.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 3

                Text {
                    width: parent.width
                    text: toast.title
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    visible: text.length > 0
                }

                Text {
                    width: parent.width
                    text: toast.message
                    color: theme.textMuted
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    visible: text.length > 0
                }
            }

            Item {
                id: closeBtn
                width: 30
                height: 30
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    color: closeArea.containsMouse
                        ? theme.alpha(theme.text, 0.08)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                SvgIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 14
                    color: closeArea.containsMouse ? theme.text : theme.textSubtle
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toastModel.remove(toast.index)
                }
            }

            // paused while hovered so users can read longer messages
            Timer {
                id: dismissTimer
                interval: root.dismissMs
                running: !hoverArea.containsMouse
                repeat: false
                onTriggered: toastModel.remove(toast.index)
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                anchors.rightMargin: closeBtn.width + 8
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
            }
        }
    }
}
