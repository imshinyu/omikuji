import QtQuick
import ".."

Row {
    id: bar

    property real uiScale: 1.0
    property string controllerKind: "xbox"
    readonly property real _scale: Math.max(0.85, Math.min(uiScale, 1.5))

    readonly property var _glyphTables: ({
        "xbox":     { "south": "A", "east": "B", "west": "X", "north": "Y" },
        "ps":       { "south": "✕", "east": "○", "west": "□", "north": "△" },
        "nintendo": { "south": "B", "east": "A", "west": "Y", "north": "X" },
        "steam":    { "south": "A", "east": "B", "west": "X", "north": "Y" }
    })

    readonly property var _g: _glyphTables[controllerKind] || _glyphTables.xbox

    readonly property var hints: [
        { glyph: _g.south, label: "Launch" },
        { glyph: _g.east,  label: "Back" },
        { glyph: _g.north, label: "Search" },
        { glyph: "✥",      label: "Navigate" }
    ]

    spacing: 28 * _scale

    Repeater {
        model: bar.hints
        delegate: Row {
            id: hint
            required property var modelData
            spacing: 8 * bar._scale

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 28 * bar._scale
                height: 28 * bar._scale

                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(width * 2, height * 2)

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: theme.surface
                    border.width: 1
                    border.color: theme.alpha(theme.text, 0.15)
                    antialiasing: true
                }

                Text {
                    anchors.fill: parent
                    text: hint.modelData.glyph
                    color: theme.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14 * bar._scale
                    font.weight: Font.Bold
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: hint.modelData.label
                color: theme.textMuted
                font.pixelSize: 14 * bar._scale
                font.weight: Font.Medium
            }
        }
    }
}
