import QtQuick

Item {
    id: root

    property var gameModel: null

    // forwarded to TabRunnerOptions so the runner dropdown refreshes after an install without restart
    property int runnersVersion: 0

    property var config: ({})

    // set by save() on success so saveAndPlay can locate the new game
    property string newGameId: ""

    readonly property bool canSave: (config["meta.name"] || "").trim().length > 0

    readonly property string modalTitle: "New Game"
    readonly property string modalSubtitle: ""
    readonly property string primaryLabel: "Create & Play"
    readonly property string secondaryLabel: "Create"
    readonly property bool primaryEnabled: canSave
    readonly property bool secondaryEnabled: canSave

    signal gameCreated(string gameId)
    signal gameCreatedAndPlay(string gameId)

    property var tabs: {
        let base = [
            { label: "Game Info", kind: "info",   icon: "sports_esports" },
            { label: "Runner",    kind: "runner", icon: "wine_bar" }
        ]
        let isFlatpakLauncher = gameModel ? gameModel.is_flatpak() : false
        let isSteamGame = root.config["runner.type"] === "steam"
        if (!(isFlatpakLauncher && isSteamGame)) {
            base.push({ label: "System", kind: "system", icon: "terminal" })
        }
        return base
    }
    property int currentTabIndex: 0
    readonly property string currentKind:
        tabs[currentTabIndex] ? tabs[currentTabIndex].kind : "info"

    onTabsChanged: if (currentTabIndex >= tabs.length) currentTabIndex = 0

    Component.onCompleted: startDraft()

    function startDraft() {
        if (!gameModel) return
        config = gameModel.begin_new_game()
    }

    function updateField(key, value) {
        if (!gameModel) return
        let strVal = String(value)
        if (gameModel.update_draft_field(key, strVal)) {
            let next = gameModel.get_draft_config()
            if (key === "launch.args") next["launch.args"] = strVal
            config = next
        }
    }

    // returns new game id or empty on validation failure, draft is presevred
    function save() {
        if (!gameModel) return ""
        let id = gameModel.commit_new_game()
        if (id && id.length > 0) {
            newGameId = id
            root.gameCreated(id)
            return id
        }
        return ""
    }

    function saveAndPlay() {
        let id = save()
        if (id && id.length > 0) {
            root.gameCreatedAndPlay(id)
        }
    }

    function primaryAction() { saveAndPlay() }
    function secondaryAction() { save() }
    function closeAction() { if (gameModel) gameModel.discard_draft() }

    implicitHeight: contentCol.implicitHeight

    Column {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // all three stay active so field state survives tab switches, a fresh Loader would lose user input
        Loader {
            width: parent.width
            active: true
            visible: root.currentKind === "info"
            source: "../settings/TabGameInfo.qml"
            onLoaded: {
                item.config = Qt.binding(() => root.config)
                item.updateField = root.updateField
                item.gameModel = root.gameModel
            }
        }

        Loader {
            width: parent.width
            active: true
            visible: root.currentKind === "runner"
            source: "../settings/TabRunnerOptions.qml"
            onLoaded: {
                item.config = Qt.binding(() => root.config)
                item.updateField = root.updateField
                item.gameModel = root.gameModel
                item.runnersVersion = Qt.binding(() => root.runnersVersion)
            }
        }

        Loader {
            width: parent.width
            active: true
            visible: root.currentKind === "system"
            source: "../settings/TabSystem.qml"
            onLoaded: {
                item.config = Qt.binding(() => root.config)
                item.updateField = root.updateField
                item.gameModel = root.gameModel
            }
        }
    }
}
