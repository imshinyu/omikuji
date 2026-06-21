import QtQuick
import QtQuick.Layouts

import "."
import "../widgets"

Item {
    id: root

    property var componentsBridge: null
    property var archiveManager: null
    // snapshot of in-flight install keys, kept live through close and reopen so Working survives navigation
    property var activeInstalls: ({})

    signal manageRequested(string category, string source, string kind)

    readonly property var runtimeMeta: ({
        "umu-run":   { label: "umu-run",    desc: "Launcher wrapper needed for Proton." },
        "hpatchz":   { label: "HPatchZ",    desc: "Binary patch tool. Required for gacha diff updates." },
        "legendary": { label: "Legendary",  desc: "Epic Games CLI binary." },
        "jadeite":   { label: "Jadeite",    desc: "Compatibility shim for Honkai: Star Rail." },
        "egl-dummy": { label: "EGL dummy",  desc: "Dummy EpicGamesLauncher.exe needed for Epic Games imports." }
    })

    property var runtimeStatuses: ({})

    function refreshRuntime() {
        if (!componentsBridge) return
        try {
            runtimeStatuses = JSON.parse(componentsBridge.statusJson()) || ({})
        } catch (e) {
            runtimeStatuses = ({})
        }
    }

    onComponentsBridgeChanged: {
        if (!componentsBridge) return
        componentsBridge.refresh()
        refreshRuntime()
    }

    Connections {
        target: componentsBridge
        enabled: componentsBridge !== null
        function onComponentStarted(name)                 { root.refreshRuntime() }
        function onComponentProgress(name, phase, percent){ root.refreshRuntime() }
        function onComponentCompleted(name, version)      { root.refreshRuntime() }
        function onComponentFailed(name, error)           { root.refreshRuntime() }
    }

    Timer {
        interval: 500
        repeat: true
        running: componentsBridge && componentsBridge.inProgress
        onTriggered: root.refreshRuntime()
    }

    property var runners: []
    property var dllPacks: []
    property var installedCounts: ({})
    property var installedVersions: ({})
    property var activeVersions: ({})

    function loadSources() {
        if (!archiveManager) return
        try { runners = JSON.parse(archiveManager.listRunners()) || [] }
        catch (e) { runners = [] }
        try { dllPacks = JSON.parse(archiveManager.listDllPacks()) || [] }
        catch (e) { dllPacks = [] }
        refreshInstalledCounts()
    }

    function refreshInstalledCounts() {
        if (!archiveManager) return
        let counts = ({})
        let versions = ({})
        let active = ({})
        for (let i = 0; i < runners.length; i++) {
            let r = runners[i]
            try {
                let list = JSON.parse(archiveManager.listInstalled("runners", r.name)) || []
                counts["runners/" + r.name] = list.length
                versions["runners/" + r.name] = list.slice().reverse()
            } catch (e) {
                counts["runners/" + r.name] = 0
                versions["runners/" + r.name] = []
            }
        }
        for (let i = 0; i < dllPacks.length; i++) {
            let d = dllPacks[i]
            try {
                let list = JSON.parse(archiveManager.listInstalled("dll_packs", d.name)) || []
                counts["dll_packs/" + d.name] = list.length
                versions["dll_packs/" + d.name] = list.slice().reverse()
            } catch (e) {
                counts["dll_packs/" + d.name] = 0
                versions["dll_packs/" + d.name] = []
            }
            active[d.name] = archiveManager.dllPackActiveVersion(d.name)
        }
        installedCounts = counts
        installedVersions = versions
        activeVersions = active
    }

    onArchiveManagerChanged: loadSources()

    Connections {
        target: archiveManager
        enabled: archiveManager !== null
        function onInstallCompleted(category, source, tag, dir) { root.refreshInstalledCounts() }
        function onInstallFailed(category, source, tag, err)   { root.refreshInstalledCounts() }
    }

    // polls for manual deletions and external edits without waiting for an install event, only runs while this tab is loaded
    Timer {
        interval: 2000
        repeat: true
        running: archiveManager !== null
        onTriggered: root.refreshInstalledCounts()
    }

    implicitHeight: content.height

    Column {
        id: content
        width: parent.width
        spacing: 20

        SettingsSection {
            label: "Translation Layers"
            width: parent.width

            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.dllPacks

                    delegate: ArchiveSourceRow {
                        required property int index
                        required property var modelData
                        width: parent.width
                        sourceName: modelData.name
                        sourceKind: modelData.kind
                        installedCount: root.installedCounts["dll_packs/" + modelData.name] || 0
                        showAutoInject: true
                        installedVersions: root.installedVersions["dll_packs/" + modelData.name] || []
                        activeVersion: root.activeVersions[modelData.name] || ""
                        onManageClicked: root.manageRequested("dll_packs", sourceName, sourceKind)
                        onAutoInjectChanged: (tag) => {
                            archiveManager.setDllPackActiveVersion(sourceName, tag)
                            root.refreshInstalledCounts()
                        }
                    }
                }

                Text {
                    visible: root.dllPacks.length === 0
                    text: "No DLL packs configured. Add [[dll_packs]] entries to settings.toml."
                    color: theme.textSubtle
                    font.pixelSize: 12
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }
        }

        SettingsSection {
            label: "Runners"
            width: parent.width

            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.runners

                    delegate: ArchiveSourceRow {
                        required property int index
                        required property var modelData
                        width: parent.width
                        sourceName: modelData.name
                        sourceKind: modelData.kind
                        installedCount: root.installedCounts["runners/" + modelData.name] || 0
                        onManageClicked: root.manageRequested("runners", sourceName, sourceKind)
                    }
                }

                Text {
                    visible: root.runners.length === 0
                    text: "No runners configured. Add [[runners]] entries to settings.toml."
                    color: theme.textSubtle
                    font.pixelSize: 12
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }
        }

        SettingsSection {
            label: "Runtime"
            width: parent.width

            Text {
                text: "External tools omikuji downloads on first run. Reinstall if a version is stale or corrupted."
                color: theme.textSubtle
                font.pixelSize: 12
                width: parent.width
                wrapMode: Text.WordWrap
                bottomPadding: 8
            }

            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: ["umu-run", "hpatchz", "legendary", "jadeite", "egl-dummy"]

                    delegate: Item {
                        required property string modelData
                        readonly property var meta: root.runtimeMeta[modelData] || ({ label: modelData, desc: "" })
                        readonly property var status: root.runtimeStatuses[modelData] || ({ status: "missing", version: "", percent: 0, error: "" })
                        readonly property bool busy: status.status === "installing"
                            || status.status === "downloading"
                            || status.status === "extracting"
                            || status.status === "resolving"

                        width: parent.width
                        height: 56

                        Rectangle {
                            anchors.fill: parent
                            color: theme.cardBg
                            radius: 10
                            border.width: 1
                            border.color: theme.surfaceBorder
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.right: actionBtn.left
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                anchors.verticalCenter: parent.verticalCenter
                                color: status.status === "completed" ? theme.success
                                    : status.status === "failed" ? theme.error
                                    : busy ? theme.accent
                                    : theme.textFaint
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                width: parent.width - 10 - 14

                                Row {
                                    spacing: 10
                                    Text {
                                        text: meta.label
                                        color: theme.text
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        visible: status.version && status.version.length > 0
                                        text: status.version
                                        color: theme.textMuted
                                        font.pixelSize: 12
                                        font.family: "monospace"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        visible: busy
                                        text: status.status === "downloading"
                                            ? "downloading " + Math.round(status.percent) + "%"
                                            : status.status
                                        color: theme.accent
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    text: status.status === "failed" && status.error ? status.error : meta.desc
                                    color: status.status === "failed" ? theme.error : theme.textSubtle
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        Rectangle {
                            id: actionBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            // hug the label and animate width so Install to Working to Reinstall reads as intentional
                            width: btnLabel.implicitWidth + 28
                            height: 32
                            radius: theme.radius.lg
                            Behavior on width {
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }

                            readonly property string kind: busy ? "muted"
                                : (componentsBridge && componentsBridge.inProgress) ? "muted"
                                : status.status === "completed" ? "ghost"
                                : status.status === "failed" ? "danger"
                                : "primary"

                            color: {
                                if (kind === "muted") return "transparent"
                                if (kind === "ghost") return btnArea.containsMouse
                                    ? theme.alpha(theme.text, 0.08)
                                    : "transparent"
                                if (kind === "primary") return btnArea.containsMouse
                                    ? Qt.darker(theme.accent, 1.1)
                                    : theme.accent
                                if (kind === "danger") return btnArea.containsMouse
                                    ? Qt.darker(theme.error, 1.1)
                                    : theme.error
                                return "transparent"
                            }
                            border.width: kind === "ghost" || kind === "muted" ? 1 : 0
                            border.color: kind === "muted" ? theme.textFaint : theme.surfaceBorder

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: btnLabel
                                anchors.centerIn: parent
                                text: actionBtn.kind === "ghost" ? "Reinstall"
                                    : actionBtn.kind === "danger" ? "Retry"
                                    : actionBtn.kind === "muted" ? "Working…"
                                    : "Install"
                                color: actionBtn.kind === "primary" ? theme.accentOn
                                    : actionBtn.kind === "danger" ? "white"
                                    : actionBtn.kind === "muted" ? theme.textFaint
                                    : theme.text
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: btnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: actionBtn.kind === "muted" ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (actionBtn.kind === "muted") return
                                    componentsBridge.reinstallComponent(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
