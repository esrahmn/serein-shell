import QtQuick
import Serein.Config
import qs.components
import qs.services

// A moon disc lit by `illumination` (0 to 1); `waxing` puts the lit side on the right
StyledClippingRect {
    id: root

    property real illumination: 0.5
    property bool waxing: true
    property color lit: Colours.palette.m3primary
    property color shade: Colours.palette.m3surfaceContainer

    implicitWidth: 16
    implicitHeight: 16
    radius: width / 2
    color: lit

    Rectangle {
        // The shadow slides off the disc as it fills up: left for a waxing moon, right for a waning one
        x: (root.waxing ? -1 : 1) * root.illumination * root.width * 1.05
        width: root.width
        height: root.height
        radius: width / 2
        color: root.shade
    }
}
