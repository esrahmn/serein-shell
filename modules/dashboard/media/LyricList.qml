pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Serein.Config
import Serein.I18n
import Serein.Services
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    // Funny binding hack to make lyrics update
    readonly property var _: {
        const p = Players.active;
        if (p)
            Lyrics.setTrack(p.trackArtist, p.trackTitle, p.trackAlbum, p.length);
        else
            Lyrics.clearTrack();
    }

    // Centred lines, the current one big (the media tab); otherwise left aligned and small
    property bool karaoke: false
    readonly property real fadeAmount: 0.1

    // The player only reports its position every so often (and Spotify's is jittery), so the position is
    // re-based on every report and moved forward by the clock in between. The lyrics then follow the singing
    // smoothly instead of in steps tied to the polling.
    property real basePos
    property real baseTime: Date.now()
    property real smoothPos

    function rebase(): void {
        const p = Players.active?.position ?? 0;
        const now = Date.now();
        const expected = basePos + (Players.active?.isPlaying ? (now - baseTime) / 1000 : 0);
        // Ignore small backward jitter while playing; real seeks (bigger jumps) are followed
        if (!Players.active?.isPlaying || Math.abs(p - expected) > 0.35 || p > expected) {
            basePos = p;
            baseTime = now;
        }
        smoothPos = basePos + (Players.active?.isPlaying ? (now - baseTime) / 1000 : 0);
    }

    Connections {
        function onPositionChanged(): void {
            root.rebase();
        }

        function onIsPlayingChanged(): void {
            root.basePos = Players.active?.position ?? 0;
            root.baseTime = Date.now();
            root.rebase();
        }

        target: Players.active
    }

    Connections {
        function onActiveChanged(): void {
            root.basePos = Players.active?.position ?? 0;
            root.baseTime = Date.now();
            root.rebase();
        }

        target: Players
    }

    FrameAnimation {
        running: root.visible && (Players.active?.isPlaying ?? false)
        onTriggered: root.smoothPos = root.basePos + (Date.now() - root.baseTime) / 1000
    }
    property bool flag
    property list<string> lyricList: Lyrics.lyrics

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask

        Rectangle {
            id: mask

            layer.enabled: true
            visible: false
            implicitWidth: root.width
            implicitHeight: root.height

            gradient: Gradient {
                orientation: Gradient.Vertical

                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 0
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 1)
                    position: 1 - root.fadeAmount
                }
                GradientStop {
                    color: Qt.alpha("black", 0)
                    position: 1
                }
            }
        }
    }

    state: {
        flag; // For some reason it doesn't update sometimes, so use this to force an update
        if (Lyrics.hasLyrics)
            return "hasLyrics";
        if (Lyrics.loading)
            return "loading";
        return "noLyrics";
    }

    states: [
        State {
            name: "loading"

            PropertyChanges {
                loadingIndicator.opacity: 1
                lyrics.opacity: 0
                noLyrics.opacity: 0
            }
        },
        State {
            name: "hasLyrics"

            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: 1
                noLyrics.opacity: 0
            }
        },
        State {
            name: "noLyrics"

            PropertyChanges {
                loadingIndicator.opacity: 0
                lyrics.opacity: 0
                noLyrics.opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            from: "loading"

            SequentialAnimation {
                Anim {
                    target: loadingIndicator
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [lyrics, noLyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        },
        Transition {
            from: "hasLyrics"

            SequentialAnimation {
                Anim {
                    target: lyrics
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [loadingIndicator, noLyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        },
        Transition {
            from: "noLyrics"

            SequentialAnimation {
                Anim {
                    target: noLyrics
                    property: "opacity"
                    type: Anim.DefaultEffects
                }
                Anim {
                    targets: [loadingIndicator, lyrics]
                    property: "opacity"
                    type: Anim.SlowEffects
                }
            }
        }
    ]

    Connections {
        function onHasLyricsChanged() {
            root.flag = !root.flag;
        }

        target: Lyrics
    }

    Loader {
        id: loadingIndicator

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.large

            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: shape.implicitSize + Tokens.padding.medium * 2
                implicitHeight: shape.implicitSize + Tokens.padding.medium * 2
                color: Colours.palette.m3primaryContainer
                radius: Tokens.rounding.full

                LoadingIndicator {
                    id: shape

                    anchors.centerIn: parent
                    implicitSize: Math.round(Tokens.sizes.dashboard.mediaSectionWidth / 5)
                    containsIcon: true // This removes the pentagon, which is not centered
                }
            }

            StyledText {
                text: Tr.tr("Loading lyrics...")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.title.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: noLyrics

        anchors.centerIn: parent
        asynchronous: true
        active: opacity > 0
        opacity: 0

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "sentiment_sad"
                fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                color: Colours.palette.m3outline
            }

            StyledText {
                text: Tr.tr("No lyrics found")
                color: Colours.palette.m3outline
                font: Tokens.font.title.medium
            }
        }
    }

    StyledListView {
        id: lyrics

        anchors.fill: parent
        anchors.topMargin: parent.height * root.fadeAmount / 2
        anchors.bottomMargin: parent.height * root.fadeAmount / 2

        displayMarginBeginning: anchors.topMargin
        displayMarginEnd: anchors.bottomMargin

        model: root.lyricList
        Component.onCompleted: {
            currentIndex = Qt.binding(() => {
                model; // Force update when lyrics change
                return Lyrics.indexForTime(root.smoothPos);
            });
            positionViewAtIndex(currentIndex, ListView.Center);
        }
        onModelChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Center))

        // The list scrolls itself: the current line is eased to the middle whenever it changes (or changes size or
        // position, since the current line is bigger than the rest). The built-in highlight range gave up when the
        // line grew while it was moving.
        function scrollToCurrent(jump: bool): void {
            const item = currentItem;
            if (!item)
                return;
            const target = Math.max(originY, item.y + item.height / 2 - height / 2);
            scrollAnim.stop();
            if (jump || Math.abs(target - contentY) > height * 2) {
                contentY = target;
                return;
            }
            scrollAnim.to = target;
            scrollAnim.start();
        }

        onCurrentIndexChanged: Qt.callLater(() => scrollToCurrent(false))
        onHeightChanged: Qt.callLater(() => scrollToCurrent(true))

        Connections {
            function onYChanged(): void {
                Qt.callLater(() => lyrics.scrollToCurrent(false));
            }

            function onHeightChanged(): void {
                Qt.callLater(() => lyrics.scrollToCurrent(false));
            }

            target: lyrics.currentItem
        }

        NumberAnimation {
            id: scrollAnim

            target: lyrics
            property: "contentY"
            duration: Tokens.anim.durations.normal
            easing.type: Easing.OutCubic
        }

        highlightRangeMode: ListView.NoHighlightRange

        spacing: Tokens.spacing.small
        opacity: 0
        enabled: opacity > 0

        delegate: StyledText {
            id: lyric

            required property string modelData
            required property int index
            property real effectScale: ListView.isCurrentItem ? 1 : 0

            anchors.left: lyrics.contentItem.left
            anchors.right: lyrics.contentItem.right

            text: modelData || ". . ."
            color: ListView.isCurrentItem ? Colours.palette.m3primary : mouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font: root.karaoke ? (ListView.isCurrentItem ? Tokens.font.headline.small : Tokens.font.title.small) : Tokens.font.body.medium
            horizontalAlignment: root.karaoke ? Text.AlignHCenter : Text.AlignLeft
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            layer.enabled: effectScale > 0
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Colours.palette.m3primary
                shadowOpacity: 0.5 * lyric.effectScale
                shadowBlur: 0.6 * lyric.effectScale
                blur: 0.4 * lyric.effectScale
            }

            Behavior on effectScale {
                Anim {
                    type: Anim.SlowEffects
                }
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    const p = Players.active;
                    if (p)
                        p.position = Lyrics.timeForIndex(lyric.index);
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Behavior on lyricList {
        SequentialAnimation {
            Anim {
                target: lyrics
                property: "opacity"
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            Anim {
                target: lyrics
                property: "opacity"
                to: 1
                type: Anim.SlowEffects
            }
        }
    }
}
