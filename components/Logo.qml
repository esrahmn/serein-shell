import QtQuick
import qs.services

// Static serein logo. Moon uses bottomColour, rain (and stars) use topColour,
// so it follows the theme unless a caller overrides them.
Item {
    id: root

    property color topColour: Colours.palette.m3primary
    property color bottomColour: Colours.palette.m3onSurface

    implicitWidth: 128
    implicitHeight: 128

    SereinMark {
        anchors.fill: parent
        moonColour: root.bottomColour
        rainColour: root.topColour
        starColour: Colours.palette.m3tertiary
        // stars turn into noise at bar-icon sizes
        showStars: Math.min(root.width, root.height) >= 56
    }
}
