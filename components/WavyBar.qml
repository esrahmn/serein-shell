import QtQuick
import QtQuick.Shapes
import Serein.Config
import qs.components
import qs.services

// Progress bar whose filled part is a sine wave (like the volume slider in the control center).
// `running` moves the wave; `interactive` lets the user drag it and emits `moved`.
Item {
    id: root

    property real value: 0
    property bool running: true
    property bool interactive: false
    property real amplitude: 4
    property real wavelength: 30
    property color colour: Colours.palette.m3primary
    property color trackColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)

    property real dragValue
    readonly property bool dragging: area.pressed
    readonly property real progress: Math.max(0, Math.min(1, dragging ? dragValue : value))
    readonly property real edge: width * progress
    property real phase: 0

    signal moved(real value)
    // Emitted when the user lets go after dragging
    signal committed(real value)

    implicitHeight: 22

    FrameAnimation {
        running: root.running && root.visible && root.width > 0
        onTriggered: root.phase = (root.phase + frameTime * 3) % (Math.PI * 2)
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 4
            strokeColor: root.trackColour
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: root.edge
            startY: root.height / 2

            PathLine {
                x: root.width
                y: root.height / 2
            }
        }

        ShapePath {
            strokeWidth: 4
            strokeColor: root.colour
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: {
                    const pts = [];
                    const e = root.edge;
                    const n = Math.max(2, Math.ceil(e / 4));
                    for (let i = 0; i <= n; i++) {
                        const x = e * i / n;
                        const fade = Math.min(1, x / 14);
                        pts.push(Qt.point(x, root.height / 2 + Math.sin(x / root.wavelength * Math.PI * 2 - root.phase) * root.amplitude * fade));
                    }
                    return pts;
                }
            }
        }
    }

    Rectangle {
        x: root.edge - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: root.height - 2
        radius: 3
        color: root.colour
    }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -8
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: event => {
            root.dragValue = Math.max(0, Math.min(1, (event.x - 8) / root.width));
            root.moved(root.dragValue);
        }
        onPositionChanged: event => {
            if (pressed) {
                root.dragValue = Math.max(0, Math.min(1, (event.x - 8) / root.width));
                root.moved(root.dragValue);
            }
        }
        onReleased: root.committed(root.dragValue)
    }
}
