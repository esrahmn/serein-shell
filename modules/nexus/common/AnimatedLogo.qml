pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

Item {
    id: root

    property real blurAmount: skipIntroAnimation ? 0.0 : 1.0
    property bool skipIntroAnimation: false

    property real star1Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star2Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star3Opacity: skipIntroAnimation ? 1.0 : 0.0

    property real star1Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star2Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star3Scale: skipIntroAnimation ? 1.0 : 0.0

    signal animationCompleted

    implicitWidth: 128
    implicitHeight: 128

    Item {
        id: logo

        width: 128
        height: 128
        transformOrigin: Item.Center
        scale: root.skipIntroAnimation ? 1.0 : 0.0
        opacity: root.skipIntroAnimation ? 1.0 : 0.0
        rotation: 0.0

        layer.enabled: root.blurAmount > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }

        SereinMark {
            anchors.fill: parent
            moonColour: Colours.palette.m3onSurface
            rainColour: Colours.palette.m3primary
            animateRain: true
        }
    }

    Item {
        id: star1
        x: 92; y: 22
        width: 8; height: 8
        opacity: root.star1Opacity
        scale: root.star1Scale
        transformOrigin: Item.Center
        Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: Colours.palette.m3tertiary }
    }

    Item {
        id: star2
        x: 103; y: 39
        width: 6; height: 6
        opacity: root.star2Opacity
        scale: root.star2Scale
        transformOrigin: Item.Center
        Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: Colours.palette.m3tertiary }
    }

    Item {
        id: star3
        x: 85; y: 43
        width: 6; height: 6
        opacity: root.star3Opacity
        scale: root.star3Scale
        transformOrigin: Item.Center
        Rectangle { anchors.centerIn: parent; width: 3; height: 3; radius: 1.5; color: Colours.palette.m3tertiary }
    }

    SequentialAnimation {
        running: !root.skipIntroAnimation
        onFinished: root.animationCompleted()

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: logo; property: "scale"; from: 0.0; to: 1.08; duration: 1000; easing.type: Easing.OutCubic }
                NumberAnimation { target: logo; property: "scale"; from: 1.08; to: 0.96; duration: 200; easing.type: Easing.InOutQuad }
                NumberAnimation { target: logo; property: "scale"; from: 0.96; to: 1.0; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
            }

            NumberAnimation { target: logo; property: "opacity"; from: 0.0; to: 1.0; duration: 600; easing.type: Easing.InOutQuad }

            NumberAnimation { target: root; property: "blurAmount"; from: 1.0; to: 0.0; duration: 900; easing.type: Easing.OutCubic }

            SequentialAnimation {
                PauseAnimation { duration: 1100 }
                ParallelAnimation {
                    NumberAnimation { target: root; property: "star1Opacity"; from: 0.0; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                    SequentialAnimation {
                        NumberAnimation { target: root; property: "star1Scale"; from: 0.0; to: 1.08; duration: 500; easing.type: Easing.OutQuad }
                        NumberAnimation { target: root; property: "star1Scale"; from: 1.08; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: 1250 }
                ParallelAnimation {
                    NumberAnimation { target: root; property: "star2Opacity"; from: 0.0; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                    SequentialAnimation {
                        NumberAnimation { target: root; property: "star2Scale"; from: 0.0; to: 1.08; duration: 500; easing.type: Easing.OutQuad }
                        NumberAnimation { target: root; property: "star2Scale"; from: 1.08; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation { duration: 1400 }
                ParallelAnimation {
                    NumberAnimation { target: root; property: "star3Opacity"; from: 0.0; to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
                    SequentialAnimation {
                        NumberAnimation { target: root; property: "star3Scale"; from: 0.0; to: 1.08; duration: 500; easing.type: Easing.OutQuad }
                        NumberAnimation { target: root; property: "star3Scale"; from: 1.08; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }

    // Infinite floating of stars
    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        PauseAnimation { duration: 2500 }

        ParallelAnimation {
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: star1; property: "y"; from: star1.y; to: star1.y - 5; duration: 2500; easing.type: Easing.InOutQuad }
                NumberAnimation { target: star1; property: "y"; from: star1.y - 5; to: star1.y; duration: 2500; easing.type: Easing.InOutQuad }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: star2; property: "y"; from: star2.y; to: star2.y + 5; duration: 3000; easing.type: Easing.InOutQuad }
                NumberAnimation { target: star2; property: "y"; from: star2.y + 5; to: star2.y; duration: 3000; easing.type: Easing.InOutQuad }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: star3; property: "y"; from: star3.y; to: star3.y - 5; duration: 2800; easing.type: Easing.InOutQuad }
                NumberAnimation { target: star3; property: "y"; from: star3.y - 5; to: star3.y; duration: 2800; easing.type: Easing.InOutQuad }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: star1; property: "scale"; from: 1.0; to: 1.08; duration: 2500; easing.type: Easing.InOutQuad }
                NumberAnimation { target: star1; property: "scale"; from: 1.08; to: 1.0; duration: 2500; easing.type: Easing.InOutQuad }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: star2; property: "scale"; from: 1.0; to: 1.12; duration: 3000; easing.type: Easing.InOutQuad }
                NumberAnimation { target: star2; property: "scale"; from: 1.12; to: 1.0; duration: 3000; easing.type: Easing.InOutQuad }
            }
            SequentialAnimation {
                loops: Animation.Infinite
                NumberAnimation { target: star3; property: "scale"; from: 1.0; to: 1.08; duration: 2800; easing.type: Easing.InOutQuad }
                NumberAnimation { target: star3; property: "scale"; from: 1.08; to: 1.0; duration: 2800; easing.type: Easing.InOutQuad }
            }
        }
    }
}
