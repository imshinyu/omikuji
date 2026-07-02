import QtQuick
import "../widgets"


Item {
    id: root
    width: 180
    clip: true
    property int minWidth: 140
    property int maxWidth: 320
    property int collapseThreshold: 80

    property int currentIndex: 0
    property string currentStore: ""
    property string currentBottom: ""
    property string headerLabel: ""

    property int downloadCount: 0

    property var uiSettings: null

    property bool showSteam: true
    property bool showEpic: true
    property bool showGog: true
    property bool showGachas: true

    signal tabSelected(int index)
    signal storeSelected(string storeName)
    signal downloadsClicked()
    signal settingsClicked()
    signal widthRequested(int value)

    property var tabs: []

    function _loadCategories() {
        if (!uiSettings) return
        let raw = uiSettings.categoriesJson()
        let parsed = []
        try { parsed = JSON.parse(raw) } catch (e) { parsed = [] }
        let next = []
        for (let i = 0; i < parsed.length; i++) {
            let c = parsed[i]
            if (c.enabled === false) continue
            next.push({ label: c.name, icon: c.icon, kind: c.kind, value: c.value || "" })
        }
        root.tabs = next
    }

    onUiSettingsChanged: _loadCategories()
    Component.onCompleted: _loadCategories()

    Connections {
        target: uiSettings
        function onCategoriesChanged() { root._loadCategories() }
    }

    Rectangle {
        anchors.fill: parent
        color: theme.navBg
    }

    Text {
        id: appTitle
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: 20
        text: root.headerLabel
        color: theme.text
        font.pixelSize: 20
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Rectangle {
        id: slidingPill
        x: 10
        width: root.width - 20
        height: 36
        radius: 18
        color: theme.alpha(theme.accent, 0.15)
        z: 0

        property real baseY: {
            if (root.currentBottom === "downloads") return downloadsBtn.y
            if (root.currentBottom === "settings")  return settingsBtn.y
            if (root.currentStore === "Steam")     return navScroll.y + storesList.y + steamItem.y
            if (root.currentStore === "Epic")      return navScroll.y + storesList.y + epicItem.y
            if (root.currentStore === "GOG")       return navScroll.y + storesList.y + gogItem.y
            if (root.currentStore === "HoYo")      return navScroll.y + storesList.y + hoyoItem.y
            return navScroll.y + tabList.y + root.currentIndex * 42
        }

        Behavior on baseY {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }

        y: root.currentBottom !== ""
            ? baseY + 2
            : baseY - navScroll.contentY + 2

        // hide if tracked item is scrolled out of the Flickable viewport
        visible: {
            if (root.currentBottom !== "") return true
            let screenY = baseY - navScroll.contentY
            return screenY + height > navScroll.y && screenY < navScroll.y + navScroll.height
        }
    }

    Flickable {
        id: navScroll
        anchors.top: appTitle.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: downloadsBtn.top
        anchors.bottomMargin: 8
        contentHeight: navContent.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: navContent
            width: navScroll.width
            height: storesList.y + storesList.height + 8

    Text {
        id: libraryHeader
        anchors.top: parent.top
        anchors.topMargin: visible ? 12 : 0
        anchors.left: parent.left
        anchors.leftMargin: 20
        text: qsTr("Library")
        color: theme.textMuted
        font.pixelSize: 12
        font.weight: Font.Medium
        visible: root.tabs.length > 0
        height: visible ? implicitHeight : 0
    }

    Column {
        id: tabList
        anchors.top: libraryHeader.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2
        z: 1

        Repeater {
            model: root.tabs

            Item {
                required property var modelData
                required property int index

                width: root.width
                height: 40

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: 36
                    radius: 18
                    color: tabHover.containsMouse && !(index === root.currentIndex && root.currentStore === "" && root.currentBottom === "")
                        ? theme.alpha(theme.text, 0.06)
                        : "transparent"
                    visible: !(index === root.currentIndex && root.currentStore === "" && root.currentBottom === "")

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    SvgIcon {
                        name: modelData.icon
                        size: 18
                        color: index === root.currentIndex && root.currentStore === "" && root.currentBottom === ""
                            ? theme.accent
                            : theme.icon
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }
                    }

                    Text {
                        text: modelData.label
                        color: theme.text
                        font.pixelSize: 13
                        font.weight: (index === root.currentIndex && root.currentStore === "" && root.currentBottom === "") ? Font.DemiBold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: tabHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index
                        root.currentStore = ""
                        root.tabSelected(index)
                    }
                }
            }
        }
    }

    Text {
        id: storesHeader
        anchors.top: tabList.bottom
        anchors.topMargin: visible ? 24 : 0
        anchors.left: parent.left
        anchors.leftMargin: 20
        text: qsTr("Stores")
        color: theme.textMuted
        font.pixelSize: 12
        font.weight: Font.Medium
        visible: root.showSteam || root.showEpic || root.showGog || root.showGachas
        height: visible ? implicitHeight : 0
    }

    Column {
        id: storesList
        anchors.top: storesHeader.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2
        z: 1

        Item {
            id: steamItem
            width: root.width
            height: visible ? 40 : 0
            visible: root.showSteam

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 20
                height: 36
                radius: 18
                color: steamHover.containsMouse && (root.currentStore !== "Steam" || root.currentBottom !== "")
                    ? theme.alpha(theme.text, 0.06)
                    : "transparent"
                visible: (root.currentStore !== "Steam" || root.currentBottom !== "")

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                SvgIcon {
                    name: "steam"
                    size: 18
                    color: root.currentStore === "Steam" && root.currentBottom === "" ? theme.accent : theme.icon
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                Text {
                    text: "Steam"
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: root.currentStore === "Steam" && root.currentBottom === "" ? Font.DemiBold : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: steamHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.currentStore = "Steam"
                    root.storeSelected("Steam")
                }
            }
        }

        Item {
            id: epicItem
            width: root.width
            height: visible ? 40 : 0
            visible: root.showEpic

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 20
                height: 36
                radius: 18
                color: epicHover.containsMouse && (root.currentStore !== "Epic" || root.currentBottom !== "")
                    ? theme.alpha(theme.text, 0.06)
                    : "transparent"
                visible: (root.currentStore !== "Epic" || root.currentBottom !== "")

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                SvgIcon {
                    name: "shield_moon"
                    size: 18
                    color: root.currentStore === "Epic" && root.currentBottom === "" ? theme.accent : theme.icon
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                Text {
                    text: "Epic Games"
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: root.currentStore === "Epic" && root.currentBottom === "" ? Font.DemiBold : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: epicHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.currentStore = "Epic"
                    root.storeSelected("Epic")
                }
            }
        }

        Item {
            id: gogItem
            width: root.width
            height: visible ? 40 : 0
            visible: root.showGog

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 20
                height: 36
                radius: 18
                color: gogHover.containsMouse && (root.currentStore !== "GOG" || root.currentBottom !== "")
                    ? theme.alpha(theme.text, 0.06)
                    : "transparent"
                visible: (root.currentStore !== "GOG" || root.currentBottom !== "")

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                SvgIcon {
                    name: "gog"
                    size: 18
                    color: root.currentStore === "GOG" && root.currentBottom === "" ? theme.accent : theme.icon
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                Text {
                    text: "GOG"
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: root.currentStore === "GOG" && root.currentBottom === "" ? Font.DemiBold : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: gogHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.currentStore = "GOG"
                    root.storeSelected("GOG")
                }
            }
        }

        Item {
            id: hoyoItem
            width: root.width
            height: visible ? 40 : 0
            visible: root.showGachas

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 20
                height: 36
                radius: 18
                color: hoyoHover.containsMouse && (root.currentStore !== "HoYo" || root.currentBottom !== "")
                    ? theme.alpha(theme.text, 0.06)
                    : "transparent"
                visible: (root.currentStore !== "HoYo" || root.currentBottom !== "")

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                SvgIcon {
                    name: "local_activity"
                    size: 18
                    color: root.currentStore === "HoYo" && root.currentBottom === "" ? theme.accent : theme.icon
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                Text {
                    text: qsTr("Gachas")
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: root.currentStore === "HoYo" && root.currentBottom === "" ? Font.DemiBold : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: hoyoHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.currentStore = "HoYo"
                    root.storeSelected("HoYo")
                }
            }
        }
    }
        }
    }

    Item {
        id: downloadsBtn
        anchors.bottom: settingsBtn.top
        anchors.bottomMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 20
            height: 36
            radius: 18
            color: downloadsHover.containsMouse && root.currentBottom !== "downloads"
                ? theme.alpha(theme.text, 0.06)
                : "transparent"
            visible: root.currentBottom !== "downloads"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            z: 1

            Item {
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                SvgIcon {
                    anchors.fill: parent
                    name: "download"
                    size: 18
                    color: root.currentBottom === "downloads" ? theme.accent : theme.icon
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: theme.accent
                    border.width: 2
                    border.color: theme.navBg
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: -2
                    anchors.topMargin: -2
                    visible: root.downloadCount > 0
                    scale: visible ? 1.0 : 0.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                }
            }

            Text {
                text: root.downloadCount > 0 ? qsTr("Downloads (%1)").arg(root.downloadCount) : qsTr("Downloads")
                color: theme.text
                font.pixelSize: 13
                font.weight: root.currentBottom === "downloads" ? Font.DemiBold : Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: downloadsHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.downloadsClicked()
        }
    }

    Item {
        id: settingsBtn
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 20
            height: 36
            radius: 18
            color: settingsHover.containsMouse && root.currentBottom !== "settings"
                ? theme.alpha(theme.text, 0.06)
                : "transparent"
            visible: root.currentBottom !== "settings"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            z: 1

            SvgIcon {
                name: "settings"
                size: 18
                color: root.currentBottom === "settings" ? theme.accent : theme.icon
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Text {
                text: qsTr("Settings")
                color: theme.text
                font.pixelSize: 13
                font.weight: root.currentBottom === "settings" ? Font.DemiBold : Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: settingsHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.settingsClicked()
        }
    }

    MouseArea {
        id: resizer
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 6
        cursorShape: Qt.SizeHorCursor
        hoverEnabled: true
        z: 99

        property int startWidth: 0
        property real startGlobalX: 0

        onPressed: (mouse) => {
            startWidth = root.width
            startGlobalX = mapToGlobal(mouse.x, 0).x
        }
        onPositionChanged: (mouse) => {
            if (!pressed) return
            const globalX = mapToGlobal(mouse.x, 0).x
            const raw = startWidth + (globalX - startGlobalX)
            if (raw < root.collapseThreshold) {
                root.widthRequested(0)
            } else {
                root.widthRequested(Math.max(root.minWidth, Math.min(root.maxWidth, raw)))
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: theme.accent
            opacity: resizer.pressed ? 0.7 : (resizer.containsMouse ? 0.35 : 0)
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

}
