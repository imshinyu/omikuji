import QtQuick
import QtQuick.Layouts
import "../widgets"

DialogCard {
    id: root

    signal saved(var entry, int index)
    signal closed()

    property int _editingIndex: -1

    property string formName: ""
    property string formIcon: "star"
    property string formKind: "tag"
    property string formValue: ""

    readonly property var kindOptions: [
        { label: "All games",  value: "all" },
        { label: "Favourites", value: "favourite" },
        { label: "Recent",     value: "recent" },
        { label: "Runner",     value: "runner" },
        { label: "Tag",        value: "tag" }
    ]

    readonly property var runnerOptions: [
        { label: "Wine / Proton", value: "wine" },
        { label: "Native",        value: "native" },
        { label: "Steam",         value: "steam" },
        { label: "Flatpak",       value: "flatpak" }
    ]

    readonly property bool _valueNeeded: formKind === "runner" || formKind === "tag"

    maxWidth: 480

    function showAdd() {
        _editingIndex = -1
        formName = ""
        formIcon = "star"
        formKind = "tag"
        formValue = ""
        _syncKindIndex()
        _syncRunnerIndex()
        open()
    }

    function showEdit(index, entry) {
        _editingIndex = index
        formName = entry.name || ""
        formIcon = entry.icon || "star"
        formKind = entry.kind || "tag"
        formValue = entry.value || ""
        _syncKindIndex()
        _syncRunnerIndex()
        open()
    }

    function hide() { root.closed(); close() }

    function _syncKindIndex() {
        for (let i = 0; i < kindOptions.length; i++) {
            if (kindOptions[i].value === formKind) {
                kindDropdown.currentIndex = i
                return
            }
        }
        kindDropdown.currentIndex = 0
    }

    function _syncRunnerIndex() {
        for (let i = 0; i < runnerOptions.length; i++) {
            if (runnerOptions[i].value === formValue) {
                runnerDropdown.currentIndex = i
                return
            }
        }
        runnerDropdown.currentIndex = 0
    }

    function _buildEntry() {
        let v = ""
        if (formKind === "runner") v = runnerOptions[runnerDropdown.currentIndex].value
        else if (formKind === "tag") v = formValue.trim()
        return {
            enabled: true,
            name: formName.trim(),
            icon: formIcon,
            kind: formKind,
            value: v
        }
    }

    onCloseRequested: { root.closed(); root.close() }

    body: ColumnLayout {
        width: parent.width
        spacing: theme.space.md

        Text {
            text: root._editingIndex === -1 ? "Add category" : "Edit category"
            color: theme.text
            font.pixelSize: theme.type.title.size
            font.weight: Font.DemiBold
        }

        M3TextField {
            id: nameField
            Layout.fillWidth: true
            label: "Name"
            text: root.formName
            onTextEdited: (t) => root.formName = t
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Icon"
                color: theme.textMuted
                font.pixelSize: theme.type.body.size
                font.weight: Font.Medium
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: theme.space.md

                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 10
                    color: theme.alpha(theme.text, 0.06)
                    border.width: 1
                    border.color: theme.alpha(theme.text, 0.12)

                    SvgIcon {
                        anchors.centerIn: parent
                        name: root.formIcon
                        size: 22
                        color: theme.icon
                    }
                }

                M3Button {
                    text: "Change"
                    variant: "tonal"
                    onClicked: iconPicker.show(root.formIcon)
                }

                Item { Layout.fillWidth: true }
            }
        }

        M3Dropdown {
            id: kindDropdown
            Layout.fillWidth: true
            label: "Kind"
            options: root.kindOptions
            onSelected: (value) => root.formKind = value
        }

        M3TextField {
            id: tagValueField
            Layout.fillWidth: true
            visible: root.formKind === "tag"
            label: "Tag value"
            placeholder: "e.g. anime, speedrun"
            text: root.formValue
            onTextEdited: (t) => root.formValue = t
        }

        M3Dropdown {
            id: runnerDropdown
            Layout.fillWidth: true
            visible: root.formKind === "runner"
            label: "Runner"
            options: root.runnerOptions
        }
    }

    actions: Row {
        spacing: theme.space.sm

        M3Button {
            text: "Cancel"
            variant: "text"
            onClicked: { root.closed(); root.close() }
        }

        M3Button {
            text: "Save"
            variant: "filled"
            enabled: root.formName.trim().length > 0
            onClicked: {
                root.saved(root._buildEntry(), root._editingIndex)
                root.closed()
                root.close()
            }
        }
    }

    IconPickerPopup {
        id: iconPicker
        anchors.fill: parent
        onPicked: (name) => root.formIcon = name
    }
}
