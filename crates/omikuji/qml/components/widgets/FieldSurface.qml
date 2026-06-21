import QtQuick

Rectangle {
    property bool focused: false

    radius: theme.radius.sm
    color: theme.fillFields ? (focused ? theme.fieldBgFocus : theme.fieldBg) : "transparent"
    border.width: theme.fillFields ? 0 : 1
    border.color: theme.outline

    Behavior on color { ColorAnimation { duration: theme.dur.fast } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 2
        border.color: theme.accent
        opacity: parent.focused ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: theme.dur.fast } }
    }
}
