import QtQuick
import QtQuick.Layouts
import Quickshell
import Serein.Components
import Serein.Config
import Serein.I18n
import qs.components
import qs.components.controls
import qs.components.images
import qs.services

StyledClippingRect {
    id: root

    required property var lock

    readonly property string title: (Players.active?.trackTitle ?? Tr.tr("Nothing playing")) || Tr.tr("Unknown track")
    readonly property string artist: (Players.active?.trackArtist ?? Tr.tr("Try playing some music!")) || Tr.tr("Unknown artist")

    // The full (stacked) layout wants this much; when the lock column squeezes the card below it,
    // `compact` switches to a single row (title and artist on the left, controls on the right)
    readonly property real fullHeight: layout.implicitHeight + layout.anchors.margins * 2
    readonly property bool compact: height < fullHeight - 1

    implicitHeight: fullHeight
    Layout.minimumHeight: compactLayout.implicitHeight + compactLayout.anchors.margins * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    FadeImage {
        anchors.fill: parent
        source: Players.getArtUrl(Players.active)

        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: {
            const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
            return Qt.size(width * dpr, height * dpr);
        }

        layer.enabled: true
        opacity: status === Image.Ready ? 1 : 0

        StyledRect {
            anchors.fill: parent
            color: Colours.palette.m3surface
            opacity: 0.7
        }

        Behavior on opacity {
            Anim {
                type: Anim.StandardExtraLarge
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.extraSmall

        visible: !root.compact

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: root.title
            color: Colours.palette.m3primary
            horizontalAlignment: Text.AlignHCenter
            font: Tokens.font.title.medium
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: root.artist
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }

        Controls {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium
        }
    }

    RowLayout {
        id: compactLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        visible: root.compact

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: root.title
                color: Colours.palette.m3primary
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: root.artist
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        Controls {}
    }

    component Controls: ButtonRow {
        spacing: Tokens.spacing.extraSmall

        IconButton {
            type: IconButton.Tonal
            icon: "skip_previous"
            isRound: true
            shapeMorph: true
            disabled: !Players.active?.canGoPrevious
            onClicked: Players.active?.previous()
        }

        IconButton {
            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            isRound: true
            shapeMorph: true
            checked: Players.active?.isPlaying ?? false
            disabled: !Players.active?.canTogglePlaying
            onClicked: Players.active?.togglePlaying()
            implicitWidth: implicitHeight + Tokens.padding.largeIncreased * 2
        }

        IconButton {
            type: IconButton.Tonal
            icon: "skip_next"
            isRound: true
            shapeMorph: true
            disabled: !Players.active?.canGoNext
            onClicked: Players.active?.next()
        }
    }
}
