import QtQuick
import Serein.Config
import Serein.I18n
import qs.components
import qs.services
import qs.utils

// CPU or GPU: icon and name, temperature chip, a big percentage and its history graph
StyledRect {
    id: root

    required property string icon
    required property string label
    required property string subLabel
    required property real usage
    required property real temperature
    property color accent: Colours.palette.m3primary

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge
    implicitHeight: 136

    Row {
        id: head

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: chip.left
        anchors.margins: Tokens.padding.large
        anchors.leftMargin: Tokens.padding.extraLargeIncreased
        spacing: Tokens.spacing.small
        clip: true

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            fill: 1
            color: root.accent
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font: Tokens.font.title.small
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, head.width - x)
            text: root.subLabel
            elide: Text.ElideRight
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }
    }

    StyledRect {
        id: chip

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.extraLargeIncreased
        implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.temperature > 90 ? "thermometer_alert" : "thermometer"
                color: root.temperature > 90 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: isNaN(root.temperature) ? "--" : Units.formatSensorTemp(root.temperature)
                font: Tokens.font.label.small
            }
        }
    }

    StyledText {
        id: big

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.padding.extraLargeIncreased
        anchors.bottomMargin: Tokens.padding.large
        text: isNaN(root.usage) ? "--" : `${Math.round(root.usage * 100)}%`
        font: Tokens.font.headline.builders.large.scale(1.5).weight(Font.Medium).build()
    }

    HistoryGraph {
        anchors.left: big.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.extraLargeIncreased
        anchors.bottomMargin: Tokens.padding.large
        height: 58
        value: root.usage
        colour: root.accent
    }
}
