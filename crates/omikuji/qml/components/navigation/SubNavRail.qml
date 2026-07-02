import QtQuick
import "../widgets"

Item {
    id: root

    property var items: []
    property int currentIndex: 0

    signal itemClicked(int index)

    readonly property int itemHeight: 46
    readonly property int gap: theme.space.xs

    implicitWidth: 200
    implicitHeight: items.length * itemHeight + Math.max(0, items.length - 1) * gap

    Squircle {
        readonly property int inset: theme.space.xs
        x: inset
        width: parent.width - inset * 2
        height: root.itemHeight - inset * 2
        radius: theme.radius.md
        fillColor: theme.alpha(theme.accent, 0.16)
        y: root.currentIndex * (root.itemHeight + root.gap) + inset
        visible: root.currentIndex >= 0 && root.currentIndex < root.items.length

        Behavior on y {
            NumberAnimation { duration: theme.dur.med; easing.type: theme.ease.emphasized; easing.overshoot: theme.ease.overshoot }
        }
    }

    Column {
        width: parent.width
        spacing: root.gap

        Repeater {
            model: root.items

            Item {
                id: rowItem
                required property int index
                required property var modelData
                width: parent.width
                height: root.itemHeight

                readonly property bool selected: index === root.currentIndex

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: theme.space.xs
                    radius: theme.radius.md
                    color: hov.containsMouse && !rowItem.selected ? theme.stateHover : theme.alpha(theme.text, 0)
                    Behavior on color { ColorAnimation { duration: theme.dur.fast } }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: theme.space.md
                    anchors.right: parent.right
                    anchors.rightMargin: theme.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: theme.space.sm + 2

                    SvgIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: rowItem.modelData.icon || ""
                        size: 20
                        color: rowItem.selected ? theme.accent : theme.icon
                        visible: (rowItem.modelData.icon || "") !== ""
                        Behavior on color { ColorAnimation { duration: theme.dur.fast } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (rowItem.modelData.icon ? 30 : 0)
                        text: rowItem.modelData.label || ""
                        color: rowItem.selected ? theme.text : theme.textMuted
                        font.pixelSize: theme.type.label.size
                        font.weight: rowItem.selected ? Font.DemiBold : Font.Medium
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: theme.dur.fast } }
                    }
                }

                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.itemClicked(rowItem.index)
                }
            }
        }
    }
}
