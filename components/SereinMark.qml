pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

// Serein mark (crescent moon + fine rain), drawn as vectors so every part takes a theme colour.
// Geometry is authored on a 128x128 canvas (same as assets/logo.svg) and scaled to fit.
Item {
    id: root

    property color moonColour: "white"
    property color rainColour: "#6ae5e1"
    property color starColour: rainColour
    property bool showStars: false
    // Let the rain fall in a slow loop. Off = the static logo.
    property bool animateRain: false

    // Each drop: line from (x1,y1) to (x2,y2) on the 128 canvas, plus its resting opacity.
    readonly property var drops: [
        { x1: 36, y1: 96, x2: 32, y2: 110, o: 1.0 },
        { x1: 52, y1: 93, x2: 47, y2: 112, o: 1.0 },
        { x1: 69, y1: 98, x2: 65, y2: 111, o: 0.85 },
        { x1: 85, y1: 91, x2: 80, y2: 107, o: 0.7 },
        { x1: 44, y1: 117, x2: 42, y2: 122, o: 0.5 },
        { x1: 77, y1: 115, x2: 75, y2: 121, o: 0.5 },
        { x1: 98, y1: 99, x2: 95, y2: 108, o: 0.45 }
    ]

    implicitWidth: 128
    implicitHeight: 128

    Item {
        id: canvas

        readonly property real fit: Math.min(root.width, root.height) / 128

        x: (root.width - 128) / 2
        y: (root.height - 128) / 2
        width: 128
        height: 128
        scale: fit
        transformOrigin: Item.Center

        // Crescent moon
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.moonColour
                strokeColor: "transparent"
                strokeWidth: 0
                startX: 52.28
                startY: 20.05

                PathArc {
                    x: 83.67
                    y: 63.99
                    radiusX: 32
                    radiusY: 32
                    useLargeArc: true
                    direction: PathArc.Counterclockwise
                }
                PathArc {
                    x: 52.28
                    y: 20.05
                    radiusX: 27
                    radiusY: 27
                    useLargeArc: true
                    direction: PathArc.Clockwise
                }
            }
        }

        // Rain: round-capped strokes (width 4), drawn as rotated rounded rectangles so they can fall
        Repeater {
            model: root.drops

            Rectangle {
                id: drop

                required property var modelData
                required property int index

                // 0 = resting position, 1 = fully fallen
                property real fall: 0

                readonly property real dx: modelData.x2 - modelData.x1
                readonly property real dy: modelData.y2 - modelData.y1
                readonly property real len: Math.hypot(dx, dy)
                readonly property real travel: 24

                width: 4
                height: len + 4
                radius: 2
                color: root.rainColour
                rotation: Math.atan2(-dx, dy) * 180 / Math.PI
                x: (modelData.x1 + modelData.x2) / 2 - width / 2 + fall * travel * dx / len
                y: (modelData.y1 + modelData.y2) / 2 - height / 2 + fall * travel * dy / len
                opacity: modelData.o * (root.animateRain ? Math.min(1, fall / 0.15, (1 - fall) / 0.35) : 1)

                SequentialAnimation {
                    running: root.animateRain && root.visible

                    // stagger so the drops do not fall in lockstep
                    PauseAnimation { duration: drop.index * 340 }
                    NumberAnimation {
                        target: drop
                        property: "fall"
                        from: 0
                        to: 1
                        duration: 2000 + (drop.index % 3) * 350
                        loops: Animation.Infinite
                    }

                    onStopped: drop.fall = 0
                }
            }
        }

        // Static stars (AnimatedLogo draws its own animated ones instead)
        Rectangle {
            visible: root.showStars
            x: 93; y: 23; width: 6; height: 6; radius: 3
            color: root.starColour
        }
        Rectangle {
            visible: root.showStars
            x: 102.4; y: 38.4; width: 3.6; height: 3.6; radius: 1.8
            color: root.starColour
            opacity: 0.7
        }
        Rectangle {
            visible: root.showStars
            x: 85.2; y: 43.2; width: 2.8; height: 2.8; radius: 1.4
            color: root.starColour
            opacity: 0.5
        }
    }
}
