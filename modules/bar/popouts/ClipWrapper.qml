pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness

    readonly property alias content: content
    readonly property bool horizontal: UiPrefs.barHorizontal
    readonly property bool onRight: UiPrefs.barOnRight
    readonly property bool onBottom: UiPrefs.barOnBottom
    // How far the panel is moved away from the bar edge (towards screen centre) while detached
    property real detachShift: {
        if (!content.isDetached)
            return 0;
        if (horizontal)
            return (parent.height - content.nonAnimHeight) / 2 * (onBottom ? -1 : 1);
        return (parent.width - content.nonAnimWidth) / 2 * (onRight ? -1 : 1);
    }
    property real offsetScale: Math.abs(detachShift) > 0.01 || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    // The panel grows out of the bar: along x for a left/right bar, along y for a top/bottom bar
    implicitWidth: horizontal ? content.implicitWidth : content.implicitWidth * (1 - offsetScale)
    implicitHeight: horizontal ? content.implicitHeight * (1 - offsetScale) : content.implicitHeight

    // Position across the bar edge hugs the bar; position along the bar follows the hovered icon
    x: {
        if (horizontal) {
            if (content.isDetached)
                return (parent.width - content.nonAnimWidth) / 2;

            const off = content.currentCenter - borderThickness - content.nonAnimWidth / 2;
            const diff = parent.width - Math.floor(off + content.nonAnimWidth);
            if (diff < 0)
                return off + diff;
            return Math.max(off, 0);
        }
        return (onRight ? parent.width - width : 0) + detachShift;
    }
    y: {
        if (horizontal)
            return (onBottom ? parent.height - height : 0) + detachShift;

        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;

        const off = content.currentCenter - borderThickness - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on detachShift {
        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on x {
        enabled: root.horizontal && root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: !root.horizontal && root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    // Unless the bar is on the left, the popout can sit over other panels (sidebar, notifications,
    // utilities, ...), so give it an opaque backdrop to keep their contents from showing through.
    StyledRect {
        anchors.fill: content
        visible: !UiPrefs.barOnLeft
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainer
        opacity: (1 - root.offsetScale) * (content.isDetached ? 0 : 1)
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        // Slides out past the edge nearest the bar as the panel closes
        x: root.horizontal ? (root.width - width) / 2 : root.onRight ? root.width - width + (implicitWidth + 5) * root.offsetScale : (-implicitWidth - 5) * root.offsetScale
        y: root.horizontal ? (root.onBottom ? root.height - height + (implicitHeight + 5) * root.offsetScale : (-implicitHeight - 5) * root.offsetScale) : (root.height - height) / 2
    }
}
