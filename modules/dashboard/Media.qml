pragma ComponentBehavior: Bound

import "media"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import M3Shapes
import Serein.Config
import Serein.I18n
import Serein.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

// Media tab: lyrics take the stage, the cover (with the cava ring) sits top left, controls in a bar at the bottom
Item {
    id: root

    required property ScreenState screenState

    readonly property bool hasUnknownLength: (Players.active?.length ?? 0) > 2147483647

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth
    implicitHeight: 440

    BackgroundShapes {
        anchors.fill: parent
    }

    // Fine rain over the background while it rains outside
    Rain {
        anchors.fill: parent
        count: 60
        colour: Colours.palette.m3primary
        opacity: UiPrefs.rainVisible ? 0.5 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        // Fast polling keeps the lyrics in step with the singing (the default 500 ms made them lag half a second)
        interval: Math.min(GlobalConfig.dashboard.mediaUpdateInterval, 250)
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    // Nothing playing
    Item {
        id: noMedia

        anchors.fill: parent
        opacity: Players.active ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialShape {
                Layout.topMargin: (pathBounds().height - implicitSize) / 2
                Layout.bottomMargin: (pathBounds().height - implicitSize) / 2 + Tokens.spacing.small
                Layout.alignment: Qt.AlignHCenter
                color: Colours.palette.m3primaryContainer
                implicitSize: icon.implicitHeight + Tokens.padding.extraLarge * 2
                shape: MaterialShape.ClamShell

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: "queue_music"
                    fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                    color: Colours.palette.m3onPrimaryContainer
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Nothing playing")
                font: Tokens.font.headline.medium
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Play something for it to show up here!")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.large
            }
        }
    }

    Item {
        id: content

        anchors.fill: parent
        opacity: Players.active ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        // Header: cover with the cava ring, title and artist
        CoverVisualiser {
            id: cover

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            implicitWidth: 132
            implicitHeight: 132
            coverSize: 78
        }

        Column {
            anchors.left: cover.right
            anchors.leftMargin: Tokens.spacing.large
            anchors.right: selector.left
            anchors.rightMargin: Tokens.spacing.large
            anchors.verticalCenter: cover.verticalCenter
            spacing: 2

            StyledText {
                width: parent.width
                text: Players.active?.trackTitle ?? ""
                font: Tokens.font.title.large
                elide: Text.ElideRight
                animate: true
            }

            StyledText {
                width: parent.width
                text: [Players.active?.trackArtist || Tr.tr("Unknown artist"), Players.active?.trackAlbum || Tr.tr("Unknown album")].join(" · ")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.title.small
                elide: Text.ElideRight
                animate: true
            }
        }

        // Player selector and lyrics source
        Row {
            id: selector

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            anchors.topMargin: Tokens.padding.large + 8
            spacing: Tokens.spacing.small

            SplitButton {
                type: SplitButton.Tonal
                disabled: !Players.list.length
                active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0] ?? null
                menu.onItemSelected: item => Players.manualActive = (item as PlayerItem).modelData

                menuItems: playerList.instances
                fallbackIcon: "music_off"
                fallbackText: Tr.trCtx("No players", "no media players active")

                minLeftWidth: 150
                label.Layout.maximumWidth: 130
                label.elide: Text.ElideRight

                stateLayer.disabled: true

                Variants {
                    id: playerList

                    model: Players.list

                    PlayerItem {}
                }
            }

            LyricsInfo {
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        LyricList {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: cover.bottom
            anchors.bottom: controlBar.top
            anchors.leftMargin: 120
            anchors.rightMargin: 120
            anchors.topMargin: Tokens.spacing.small
            anchors.bottomMargin: Tokens.spacing.small
            karaoke: true
        }

        // Controls: transport pill, wavy seek bar, shuffle and repeat chips
        StyledRect {
            id: controlBar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.padding.large
            implicitHeight: 58
            radius: Tokens.rounding.large * 1.4
            color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.4)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.large
                spacing: Tokens.spacing.large

                // Transport: previous, play (a cookie while playing) and next in one pill
                StyledRect {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: transport.implicitWidth + Tokens.padding.small * 2
                    implicitHeight: 44
                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.5)

                    Row {
                        id: transport

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        TransportButton {
                            icon: "skip_previous"
                            enabled: Players.active?.canGoPrevious ?? false
                            onClicked: Players.active?.previous()
                        }

                        MaterialShape {
                            id: play

                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 38
                            shape: Players.active?.isPlaying ? MaterialShape.Cookie9Sided : MaterialShape.Circle
                            color: Colours.palette.m3primary
                            animationEasing: Tokens.anim.expressiveDefaultSpatial
                            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: Players.active?.isPlaying ? "pause" : "play_arrow"
                                fontStyle: Tokens.font.icon.medium
                                fill: 1
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

                // Seek
                StyledText {
                    text: root.lengthStr(seek.dragging ? seek.dragValue * (Players.active?.length ?? 0) : (Players.active?.position ?? -1))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                WavyBar {
                    id: seek

                    Layout.fillWidth: true
                    implicitHeight: 22
                    amplitude: 3
                    value: Players.active ? Players.active.position / (Players.active.length || 1) : 0
                    running: Players.active?.isPlaying ?? false
                    interactive: (Players.active?.canSeek ?? false) && !root.hasUnknownLength
                    onCommitted: value => {
                        const active = Players.active;
                        if (active?.canSeek && active?.positionSupported)
                            active.position = value * active.length;
                    }
                }

                StyledText {
                    text: root.hasUnknownLength ? "--:--" : root.lengthStr(Players.active?.length ?? -1)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                // Shuffle and repeat as labelled chips
                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Tokens.spacing.small

                    ModeChip {
                        icon: "shuffle"
                        label: Tr.tr("Shuffle")
                        checked: Players.active?.shuffle ?? false
                        enabled: Players.active?.shuffleSupported ?? false
                        onClicked: Players.active.shuffle = !Players.active?.shuffle
                    }

                    ModeChip {
                        icon: Players.active?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                        label: Tr.tr("Repeat")
                        checked: Players.active?.loopState === MprisLoopState.Track || Players.active?.loopState === MprisLoopState.Playlist
                        enabled: Players.active?.loopSupported ?? false
                        onClicked: {
                            const state = Players.active.loopState;
                            if (state === MprisLoopState.None)
                                Players.active.loopState = MprisLoopState.Track;
                            else if (state === MprisLoopState.Track)
                                Players.active.loopState = MprisLoopState.Playlist;
                            else
                                Players.active.loopState = MprisLoopState.None;
                        }
                    }
                }
            }
        }
    }

    component PlayerItem: MenuItem {
        required property MprisPlayer modelData

        icon: modelData === Players.active ? "check" : ""
        text: Players.getIdentity(modelData)
        activeIcon: "animated_images"
    }

    component TransportButton: Item {
        id: tb

        property string icon

        signal clicked

        implicitWidth: 34
        implicitHeight: 34
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

    component ModeChip: StyledRect {
        id: chip

        property string icon
        property string label
        property bool checked

        signal clicked

        implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: 30
        radius: Tokens.rounding.full
        color: checked ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.85) : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.5)
        opacity: enabled ? 1 : 0.4

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon
                fill: chip.checked ? 1 : 0
                fontStyle: Tokens.font.icon.small
                color: chip.checked ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.label
                font: Tokens.font.label.small
                color: chip.checked ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
            }
        }

        StateLayer {
            radius: Tokens.rounding.full
            onClicked: chip.clicked()
        }
    }
}
