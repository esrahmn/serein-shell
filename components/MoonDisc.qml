import QtQuick
import QtQuick.Shapes
import Serein.Config
import qs.components
import qs.services

// A moon disc lit by `illumination` (0 to 1); `waxing` puts the lit side on the right.
// The dark part is drawn dim (earthshine), so it works on any background.
Item {
    id: root

    property real illumination: 0.5
    property bool waxing: true
    property color lit: Colours.palette.m3primary

    readonly property real r: width / 2 - 1
    // Distance between the lit disc and the shadow disc; at 2r or more the moon is full
    readonly property real d: Math.min(2 * r, illumination * 2.1 * r)
    readonly property real h: Math.sqrt(Math.max(0, r * r - d * d / 4))

    implicitWidth: 16
    implicitHeight: 16

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.alpha(root.lit, 0.16)
        border.width: 1.5
        border.color: Qt.alpha(root.lit, 0.4)
    }

    // Full moon
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.lit
        visible: root.d >= 2 * root.r - 0.5
    }

    // Crescent or gibbous: the lit disc minus the shadow disc
    Shape {
        anchors.fill: parent
        visible: root.d < 2 * root.r - 0.5
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            origin.x: root.width / 2
            xScale: root.waxing ? 1 : -1
        }

        ShapePath {
            strokeWidth: 0
            fillColor: root.lit
            startX: root.width / 2 - root.d / 2
            startY: root.height / 2 - root.h

            PathArc {
                x: root.width / 2 - root.d / 2
                y: root.height / 2 + root.h
                radiusX: root.r
                radiusY: root.r
                direction: PathArc.Clockwise
                useLargeArc: root.d > 0
            }

            PathArc {
                x: root.width / 2 - root.d / 2
                y: root.height / 2 - root.h
                radiusX: root.r
                radiusY: root.r
                direction: PathArc.Counterclockwise
                useLargeArc: false
            }
        }
    }
}
