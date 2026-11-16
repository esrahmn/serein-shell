pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Horizontal clock for a top/bottom bar: [icon] [Mon 16] [07:28[:ss]] [pm]
StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.large : Tokens.padding.small
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: Tokens.sizes.bar.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            visible: Config.bar.clock.showIcon
            text: "calendar_month"
            color: root.colour
        }

        StyledText {
            visible: Config.bar.clock.showDate
            text: Time.format("ddd d")
            font: Tokens.font.body.builders.small.scale(0.95).build()
            color: root.colour
        }

        StyledText {
            text: Time.hourStr + ":" + Time.minuteStr + (Config.bar.clock.showSeconds ? ":" + Time.format("ss") : "")
            font: root.font.build()
            color: root.colour
        }

        StyledText {
            visible: Units.twelveHourClock
            text: Time.amPmStr.toLowerCase()
            font: Tokens.font.body.builders.small.scale(0.9).build()
            color: root.colour
        }
    }
}
