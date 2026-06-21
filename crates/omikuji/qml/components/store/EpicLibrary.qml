import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import omikuji 1.0
import "../widgets"

Item {
    id: root

    property var epicModel: null
    property real cardZoom: 1.0
    property int cardSpacing: 16
    property bool cardElevation: false
    property string searchText: ""
    property string cardFlow: "center"
    property var activeDownloads: ({})

    signal backClicked()
    signal gameImported()
    signal installRequested(int index)
    signal importRequested(int index)

    function _maybeRefresh() {
        if (epicModel && epicModel.isLoggedIn) {
            epicModel.refresh()
        }
    }
    Component.onCompleted: _maybeRefresh()
    onVisibleChanged: if (visible) _maybeRefresh()

    readonly property bool isLoggedIn: epicModel && epicModel.isLoggedIn
    readonly property bool isRefreshing: epicModel && epicModel.isRefreshing === true

    CardGrid {
        id: cardGrid
        anchors.fill: parent
        visible: root.isLoggedIn
        enabled: visible

        model: epicModel
        cardZoom: root.cardZoom
        cardSpacing: root.cardSpacing
        cardFlow: root.cardFlow

        headerComponent: Component {
            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "Logged in as: " + (epicModel ? epicModel.displayName : "")
                    color: theme.textMuted
                    font.pixelSize: 13
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    icon: "sync"
                    size: 32
                    onClicked: epicModel.refresh()
                }

                IconButton {
                    icon: "logout"
                    size: 32
                    onClicked: epicModel.logout()
                }
            }
        }

        delegate: BaseCard {
            id: epicCard
            required property var modelData
            required property int index

            width: 180 * root.cardZoom
            height: 240 * root.cardZoom
            elevation: root.cardElevation

            property bool isInstalled: modelData.isInstalled
            property bool hasLibraryEntry: modelData.hasLibraryEntry === true
            property bool isDownloading: root.activeDownloads[modelData.appName] !== undefined
            property string cardState: !isInstalled ? "uninstalled"
                : (hasLibraryEntry ? "imported" : "needs-import")

            title: modelData.title
            imageSource: modelData.coverart || ""
            imageOpacity: isInstalled ? 1.0 : 0.6
            leftIconName: "shield_moon"
            leftIconSize: 20
            selected: isInstalled
            clickable: false
            cardVisible: root.searchText === ""
                || (modelData.title || "").toLowerCase().includes(root.searchText.toLowerCase())

            actionComponent: Component {
                StoreCardAction {
                    icon: {
                        if (epicCard.cardState === "uninstalled") return "add"
                        if (epicCard.cardState === "needs-import") return "download"
                        return "check_circle"
                    }
                    visible: !epicCard.isDownloading
                    primary: epicCard.cardState !== "imported"
                    onClicked: {
                        if (epicCard.cardState === "uninstalled") {
                            root.installRequested(epicCard.index)
                        } else if (epicCard.cardState === "needs-import") {
                            root.importRequested(epicCard.index)
                        }
                    }
                }
            }

            overlayComponent: Component {
                Item {
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 4
                        height: 24
                        radius: 10
                        color: theme.alpha(theme.accent, 0.9)
                        visible: epicCard.isDownloading

                        Text {
                            anchors.centerIn: parent
                            text: {
                                let dl = root.activeDownloads[epicCard.modelData.appName]
                                if (!dl) return ""
                                if (dl.status === "Downloading") return dl.progress.toFixed(0) + "%"
                                return dl.status
                            }
                            color: theme.accentOn
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }
    }

    Item {
        id: loadingOverlay
        anchors.fill: parent
        visible: root.isLoggedIn && root.isRefreshing && cardGrid.count === 0
        z: 90

        LoadingDots {
            anchors.centerIn: parent
            text: "Loading library"
            running: loadingOverlay.visible
        }
    }

    Item {
        id: emptyOverlay
        anchors.fill: parent
        visible: root.isLoggedIn && !root.isRefreshing && cardGrid.count === 0
        z: 90

        Column {
            anchors.centerIn: parent
            spacing: 10

            SvgIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "shield_moon"
                size: 48
                color: theme.textFaint
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No games in this store"
                color: theme.textMuted
                font.pixelSize: 16
                font.weight: Font.Medium
            }
        }
    }

    Item {
        id: loginOverlay
        anchors.fill: parent
        visible: epicModel && !epicModel.isLoggedIn
        z: 100

        Column {
            anchors.centerIn: parent
            width: 400
            spacing: 24

            SvgIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "shield_moon"
                size: 64
                color: theme.text
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Login to Epic Games"
                color: theme.text
                font.pixelSize: 20
                font.weight: Font.Bold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                text: "To sync your Epic library, you need to provide an authorization code from Epic's website."
                color: theme.textMuted
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Text {
                id: epicLoginLink
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Open Login Page"
                color: linkMouseArea.containsMouse ? Qt.lighter(theme.accent, 1.1) : theme.accent
                font.pixelSize: 14
                font.weight: Font.DemiBold
                Behavior on color { ColorAnimation { duration: 100 } }

                MouseArea {
                    id: linkMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://legendary.gl/epiclogin")
                }
            }

            M3TextField {
                id: loginCodeField
                width: parent.width
                placeholder: "Paste authorization code here..."
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 140
                height: 42
                enabled: loginCodeField.text.length > 0
                opacity: enabled ? 1.0 : 0.5

                Rectangle {
                    anchors.fill: parent
                    radius: 21
                    color: theme.accent
                    opacity: loginMouseArea.containsPress ? 0.8 : (loginMouseArea.containsMouse ? 0.95 : 0.9)
                    scale: loginMouseArea.containsPress ? 0.97 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Login"
                    color: theme.accentOn
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: loginMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        epicModel.login(loginCodeField.text)
                        loginCodeField.text = ""
                    }
                }
            }
        }
    }
}
