pragma ComponentBehavior: Bound

import QtQuick
import Serein.Config
import Serein.I18n
import Serein.Services
import qs.components
import qs.components.effects
import qs.services
import qs.utils

// The dashboard's hero: moon, clock, weather and the system waves over a rainy night sky
StyledClippingRect {
    id: root

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge * 1.5
    implicitHeight: 250

    Rain {
        anchors.fill: parent
        count: 50
        colour: Colours.palette.m3primary
        opacity: UiPrefs.rainVisible ? 0.6 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    NightWaves {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 100
    }

    MoonDisc {
        x: Tokens.padding.extraLargeIncreased
        y: Tokens.padding.extraLargeIncreased
        implicitWidth: 84
        implicitHeight: 84
        illumination: Moon.illumination
        waxing: Moon.waxing
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Tokens.padding.extraLargeIncreased
        spacing: Tokens.spacing.small

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            animate: true
            text: `${Time.hourStr}:${Time.minuteStr}`
            font: Tokens.font.headline.builders.medium.scale(2.3).weight(Font.Medium).build()
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `${Time.format("dddd, d MMMM")} · ${Moon.name}`
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
        }
    }

    Column {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.extraLargeIncreased
        spacing: 2

        MaterialIcon {
            anchors.right: parent.right
            animate: true
            text: Weather.icon
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()
        }

        StyledText {
            anchors.right: parent.right
            animate: true
            text: Weather.temp
            font: Tokens.font.title.large
        }

        StyledText {
            anchors.right: parent.right
            animate: true
            text: Weather.description
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.padding.extraLargeIncreased
        anchors.bottomMargin: Tokens.padding.large
        spacing: Tokens.spacing.small

        Chip {
            text: `CPU ${Math.round(Cpu.percentage * 100)}%`
        }

        Chip {
            text: `RAM ${Math.round(Memory.percentage * 100)}%`
        }

        Chip {
            text: `${Tr.tr("Disk")} ${Math.round(Storage.percentage * 100)}%`
        }
    }

    component Chip: StyledRect {
        property alias text: label.text

        implicitWidth: label.implicitWidth + Tokens.padding.large * 2
        implicitHeight: label.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

        StyledText {
            id: label

            anchors.centerIn: parent
            font: Tokens.font.label.small
        }
    }
}
