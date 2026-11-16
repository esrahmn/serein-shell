pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Serein.Components
import Serein.Config
import Serein.I18n
import Serein.Services
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.utils

// Now playing, with the cat sitting on the top edge of the card
Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? (active.position % active.length) / active.length : 0;
    }

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    Behavior on playerProgress {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    AnimatedImage {
        id: cat

        anchors.right: parent.right
        anchors.rightMargin: Tokens.padding.large
        anchors.bottom: parent.top
        anchors.bottomMargin: root.anchors.margins - 8
        width: 76
        height: 56

        playing: Players.active?.isPlaying ?? false
        // The beat tracker reports 0 BPM until it locks onto a beat, which would freeze the GIF
        speed: Math.max(80, Math.min(180, Audio.beatTracker.bpm || 120)) / Config.general.mediaGifSpeedAdjustment // qmllint disable unresolved-type
        source: Paths.absolutePath(Config.paths.mediaGif)
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }

    CoverArt {
        id: cover

        anchors.left: parent.left
        anchors.top: parent.top
        implicitWidth: 64
        implicitHeight: 64
    }

    Column {
        anchors.left: cover.right
        anchors.leftMargin: Tokens.spacing.large
        anchors.right: parent.right
        anchors.verticalCenter: cover.verticalCenter
        spacing: 2

        StyledText {
            width: parent.width
            animate: true
            text: (Players.active?.trackTitle ?? Tr.tr("No media")) || Tr.tr("Unknown title")
            elide: Text.ElideRight
            font: Tokens.font.title.small
        }

        StyledText {
            width: parent.width
            animate: true
            text: (Players.active?.trackArtist ?? Tr.tr("No media")) || Tr.tr("Unknown artist")
            elide: Text.ElideRight
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    WavyBar {
        id: bar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: cover.bottom
        anchors.topMargin: Tokens.spacing.small
        value: root.playerProgress
        running: Players.active?.isPlaying ?? false
    }

    // Transport pill: previous, play (a cookie while playing) and next
    StyledRect {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -Tokens.spacing.small
        implicitWidth: transport.implicitWidth + Tokens.padding.small * 2
        implicitHeight: 40
        radius: Tokens.rounding.full
        color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.5)

        Row {
            id: transport

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            TransportButton {
                icon: "skip_previous"
                enabled: Players.active?.canGoPrevious ?? false
                onClicked: Players.active?.previous()
            }

            MaterialShape {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 32
                shape: Players.active?.isPlaying ? MaterialShape.Cookie9Sided : MaterialShape.Circle
                color: Colours.palette.m3primary
                animationEasing: Tokens.anim.expressiveDefaultSpatial
                animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

                MaterialIcon {
                    anchors.centerIn: parent
                    text: Players.active?.isPlaying ? "pause" : "play_arrow"
                    fill: 1
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: Players.active?.canTogglePlaying ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Players.active?.togglePlaying()
                }
            }

            TransportButton {
                icon: "skip_next"
                enabled: Players.active?.canGoNext ?? false
                onClicked: Players.active?.next()
            }
        }
    }

    component TransportButton: Item {
        id: tb

        property string icon

        signal clicked

        implicitWidth: 30
        implicitHeight: 30
        opacity: enabled ? 1 : 0.4

        StateLayer {
            radius: Tokens.rounding.full
            onClicked: tb.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: tb.icon
            fill: 1
            fontStyle: Tokens.font.icon.medium
            color: Colours.palette.m3onSurface
        }
    }
}
