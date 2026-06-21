import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "../widgets"

// this is such a mess sned help

Window {
    id: logWindow

    property string gameId: ""
    property string gameName: ""
    property var gameModel: null
    property var theme: null
    property bool autoScroll: true
    property bool justSaved: false
    property bool searchExpanded: false
    property string rawLog: ""

    signal windowClosed()

    width: 860
    height: 520
    minimumWidth: 420
    minimumHeight: 280
    title: "omikuji · " + (gameName || gameId) + " logs"
    color: theme ? theme.bg : "#0a0a0a"

    function refresh() {
        if (!gameModel) return
        logWindow.rawLog = gameModel.game_log(gameId)
        updateDisplay()
    }

    function updateDisplay() {
        textArea.text = rawLog
        if (!searchExpanded || searchInput.text.length === 0) {
            if (autoScroll) {
                textArea.cursorPosition = textArea.length
            }
        }
    }

    Connections {
        target: gameModel
        function onGameLogAppended(id) {
            if (id === logWindow.gameId) {
                let wasAtBottom = scroll.contentItem ? scroll.contentItem.atYEnd : true
                logWindow.rawLog = gameModel.game_log(gameId)
                updateDisplay()
                if (wasAtBottom || logWindow.autoScroll) {
                    timerScroll.start()
                }
            }
        }
    }

    Timer {
        id: timerScroll
        interval: 50
        onTriggered: textArea.cursorPosition = textArea.length
    }

    Component.onCompleted: {
        visible = true
        refresh()
        raise()
        requestActivate()
    }

    onClosing: windowClosed()

    Shortcut {
        sequence: StandardKey.Cancel
        context: Qt.WindowShortcut
        onActivated: logWindow.close()
    }

    Shortcut {
        sequence: "Ctrl+F"
        context: Qt.WindowShortcut
        onActivated: {
            logWindow.searchExpanded = !logWindow.searchExpanded
            if (logWindow.searchExpanded) {
                Qt.callLater(() => {
                    searchInput.forceActiveFocus()
                    floatingBar.updateMatches()
                })
            } else {
                textArea.select(0, 0)
                logWindow.forceActiveFocus()
            }
        }
    }

    component HeaderButton: Item {
        id: btn
        property string label: ""
        property color labelColor: logWindow.theme.text
        property color borderColor: logWindow.theme.surfaceBorder
        property color hoverColor: Qt.rgba(logWindow.theme.text.r, logWindow.theme.text.g, logWindow.theme.text.b, 0.08)
        signal clicked()

        implicitWidth: btnText.implicitWidth + 24
        implicitHeight: 28

        Rectangle {
            anchors.fill: parent
            radius: theme.radius.xs
            color: btnArea.containsMouse ? btn.hoverColor : "transparent"
            border.width: 1
            border.color: btn.borderColor
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Text {
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            color: btn.labelColor
            font.pixelSize: 12
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: logWindow.theme.bgAlt

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: logWindow.gameName
                    color: logWindow.theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Item {
                    Layout.preferredWidth: followRow.implicitWidth + 12
                    Layout.preferredHeight: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: theme.radius.xs
                        color: followArea.containsMouse
                            ? Qt.rgba(logWindow.theme.text.r, logWindow.theme.text.g, logWindow.theme.text.b, 0.08)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    Row {
                        id: followRow
                        anchors.centerIn: parent
                        spacing: 8

                        SvgIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: logWindow.autoScroll ? "check_box" : "check_box_outline_blank"
                            size: 18
                            color: logWindow.autoScroll ? logWindow.theme.accent : logWindow.theme.textMuted
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Follow"
                            color: logWindow.theme.text
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: followArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: logWindow.autoScroll = !logWindow.autoScroll
                    }
                }

                HeaderButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    label: "Clear"
                    onClicked: {
                        if (gameModel) {
                            gameModel.clear_game_log(logWindow.gameId)
                            logWindow.refresh()
                        }
                    }
                }

                HeaderButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    label: "Copy all"
                    onClicked: {
                        textArea.selectAll()
                        textArea.copy()
                        textArea.deselect()
                    }
                }

                HeaderButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    label: logWindow.justSaved ? "Saved ✓" : "Save"
                    labelColor: logWindow.justSaved ? logWindow.theme.success : logWindow.theme.text
                    borderColor: logWindow.justSaved
                        ? Qt.rgba(logWindow.theme.success.r, logWindow.theme.success.g, logWindow.theme.success.b, 0.5)
                        : logWindow.theme.surfaceBorder
                    hoverColor: logWindow.justSaved
                        ? Qt.rgba(logWindow.theme.success.r, logWindow.theme.success.g, logWindow.theme.success.b, 0.18)
                        : Qt.rgba(logWindow.theme.text.r, logWindow.theme.text.g, logWindow.theme.text.b, 0.08)
                    onClicked: {
                        if (!gameModel) return
                        let path = gameModel.save_game_log(logWindow.gameId)
                        if (path && path.length > 0) {
                            logWindow.justSaved = true
                            savedRevertTimer.restart()
                        }
                    }
                }

                Timer {
                    id: savedRevertTimer
                    interval: 2000
                    repeat: false
                    onTriggered: logWindow.justSaved = false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: logWindow.theme.surfaceBorder
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: textArea
                readOnly: true
                wrapMode: TextArea.Wrap
                selectByMouse: true
                color: logWindow.theme.text
                font.family: "monospace"
                font.pixelSize: 14
                leftPadding: 14
                rightPadding: 14
                topPadding: 10
                bottomPadding: 10
                background: Rectangle { color: logWindow.theme.bg }
                text: ""
            }
        }
    }

    Rectangle {
        id: floatingBar
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        height: 40
        width: logWindow.searchExpanded ? searchRow.implicitWidth + 32 : 40
        radius: 20
        color: logWindow.theme.bgAlt
        border.width: 1
        border.color: logWindow.theme.surfaceBorder
        clip: true

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        property var matchPositions: []
        property int matchCount: 0
        property int currentMatchIndex: -1

        function updateMatches() {
            matchPositions = []
            matchCount = 0
            currentMatchIndex = -1
            if (searchInput.text.length === 0) return

            let content = logWindow.rawLog.toLowerCase()
            let query = searchInput.text.toLowerCase()
            let pos = content.indexOf(query)
            while (pos !== -1) {
                matchPositions.push(pos)
                pos = content.indexOf(query, pos + 1)
            }
            matchCount = matchPositions.length
            if (matchCount > 0) {
                jumpToMatch(0)
            } else {
                textArea.select(0, 0)
            }
        }

        function jumpToMatch(index) {
            if (matchCount === 0) return
            if (index < 0) index = matchCount - 1
            if (index >= matchCount) index = 0
            currentMatchIndex = index
            let pos = matchPositions[index]
            textArea.cursorPosition = pos
            textArea.select(pos, pos + searchInput.text.length)
        }

        SvgIcon {
            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            size: 18
            color: logWindow.theme.text
            opacity: logWindow.searchExpanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !logWindow.searchExpanded
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                logWindow.searchExpanded = true
                Qt.callLater(() => {
                    searchInput.forceActiveFocus()
                    floatingBar.updateMatches()
                })
            }
        }

        Row {
            id: searchRow
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            opacity: logWindow.searchExpanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            SvgIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                size: 16
                color: logWindow.theme.textMuted
            }

            TextInput {
                id: searchInput
                anchors.verticalCenter: parent.verticalCenter
                width: 160
                enabled: logWindow.searchExpanded
                color: logWindow.theme.text
                font.pixelSize: 14
                clip: true
                selectionColor: logWindow.theme.accent
                selectedTextColor: logWindow.theme.accentText
                selectByMouse: true

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "Search..."
                    color: logWindow.theme.textSubtle
                    font.pixelSize: 14
                    visible: !searchInput.text && !searchInput.activeFocus
                }

                onTextChanged: floatingBar.updateMatches()
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 50
                horizontalAlignment: Text.AlignHCenter
                text: floatingBar.matchCount > 0 ? (floatingBar.currentMatchIndex + 1) + "/" + floatingBar.matchCount : "0/0"
                color: logWindow.theme.textSubtle
                font.pixelSize: 13
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                IconButton {
                    icon: "chevron_up"
                    size: 24
                    blocked: floatingBar.matchCount === 0
                    onClicked: floatingBar.jumpToMatch(floatingBar.currentMatchIndex - 1)
                }
                IconButton {
                    icon: "chevron_up"
                    size: 24
                    rotation: 180
                    blocked: floatingBar.matchCount === 0
                    onClicked: floatingBar.jumpToMatch(floatingBar.currentMatchIndex + 1)
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 20
                color: logWindow.theme.surfaceBorder
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "close"
                size: 24
                onClicked: {
                    logWindow.searchExpanded = false
                    textArea.select(0, 0)
                    logWindow.forceActiveFocus()
                }
            }
        }
    }
}
