import "dash"
import QtQuick
import QtQuick.Layouts
import Serein.Config
import qs.components
import qs.components.filedialog
import qs.services

// Night sky hero on top, three cards below: this week, now playing (with the cat) and you
ColumnLayout {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    spacing: Tokens.spacing.medium

    NightScene {
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        Rect {
            Layout.preferredWidth: 290
            Layout.preferredHeight: 176

            radius: Tokens.rounding.extraLarge

            WeekStrip {}
        }

        Rect {
            Layout.fillWidth: true
            Layout.preferredWidth: 330
            Layout.preferredHeight: 176

            radius: Tokens.rounding.extraLarge

            MediaCard {}
        }

        Rect {
            Layout.preferredWidth: Tokens.sizes.dashboard.userWidth
            Layout.preferredHeight: 176

            radius: Tokens.rounding.extraLarge

            User {
                screenState: root.screenState
                facePicker: root.facePicker
            }
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
