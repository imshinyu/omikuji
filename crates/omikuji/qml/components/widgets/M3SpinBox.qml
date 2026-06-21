import QtQuick

Item {
    id: root

    property int from: 0
    property int to: 100
    property int stepSize: 1
    property int value: 0
    property string zeroPlaceholder: ""

    signal moved(int value)

    implicitWidth: boxRow.implicitWidth
    implicitHeight: 36

    function _clamp(v) { return Math.max(root.from, Math.min(root.to, v)) }
    function _bump(delta) {
        let next = _clamp(root.value + delta * root.stepSize)
        if (next === root.value) return
        root.value = next
        root.moved(next)
    }

    Row {
        id: boxRow
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: minusBtn
            width: 36
            height: parent.height
            radius: theme.radius.sm
            color: minusArea.containsPress
                ? theme.alpha(theme.text, 0.14)
                : (minusArea.containsMouse
                    ? theme.alpha(theme.text, 0.08)
                    : theme.alpha(theme.text, 0.04))
            opacity: root.value > root.from ? 1 : 0.4

            Behavior on color { ColorAnimation { duration: 100 } }

            SvgIcon {
                anchors.centerIn: parent
                name: "remove"
                size: 16
                color: theme.text
            }

            MouseArea {
                id: minusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.value > root.from ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root._bump(-1)
                onPressAndHold: holdTimer.startWith(-1)
                onReleased: holdTimer.stop()
                onExited: holdTimer.stop()
            }
        }

        Item {
            width: 64
            height: parent.height

            TextInput {
                id: valueInput
                anchors.fill: parent
                text: (root.zeroPlaceholder !== "" && root.value === 0) ? root.zeroPlaceholder : root.value
                color: theme.text
                font.pixelSize: 14
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: root.from; top: root.to }
                onEditingFinished: {
                    let parsed = parseInt(text, 10)
                    if (isNaN(parsed)) parsed = root.from
                    let clamped = root._clamp(parsed)
                    if (clamped !== root.value) {
                        root.value = clamped
                        root.moved(clamped)
                    }
                    text = (root.zeroPlaceholder !== "" && root.value === 0) ? root.zeroPlaceholder : root.value
                }
                Keys.onUpPressed: root._bump(1)
                Keys.onDownPressed: root._bump(-1)
            }
        }

        Rectangle {
            id: plusBtn
            width: 36
            height: parent.height
            radius: theme.radius.sm
            color: plusArea.containsPress
                ? theme.alpha(theme.text, 0.14)
                : (plusArea.containsMouse
                    ? theme.alpha(theme.text, 0.08)
                    : theme.alpha(theme.text, 0.04))
            opacity: root.value < root.to ? 1 : 0.4

            Behavior on color { ColorAnimation { duration: 100 } }

            SvgIcon {
                anchors.centerIn: parent
                name: "add"
                size: 16
                color: theme.text
            }

            MouseArea {
                id: plusArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.value < root.to ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root._bump(1)
                onPressAndHold: holdTimer.startWith(1)
                onReleased: holdTimer.stop()
                onExited: holdTimer.stop()
            }
        }
    }

    Timer {
        id: holdTimer
        property int direction: 0
        interval: 80
        repeat: true
        onTriggered: root._bump(direction)
        function startWith(d) { direction = d; start() }
    }
}
