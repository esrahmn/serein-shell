pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness
    // Gap between the panels and each window edge: the border, or the bar when it sits on that edge
    readonly property real leftSide: panels.barLeft ? bar.clampedSize : clampedThickness
    readonly property real rightSide: panels.barRight ? bar.clampedSize : clampedThickness
    readonly property real topSide: panels.barTop ? bar.clampedSize : clampedThickness
    readonly property real bottomSide: panels.barBottom ? bar.clampedSize : clampedThickness
    readonly property real rightExtra: panels.barRight ? 0 : borderThickness
    readonly property real rightInset: panels.barRight ? bar.size : 0

    x: leftSide + win.dragMaskPadding
    y: topSide + win.dragMaskPadding
    width: win.width - leftSide - rightSide - win.dragMaskPadding * 2
    height: win.height - topSide - bottomSide - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + root.panels.insetTop
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.panels.insetBottom
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width - root.rightInset
        width: panel.width * (1 - root.panels.session.offsetScale) + root.rightExtra + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width - root.rightInset
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.rightExtra
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width - root.rightInset
        width: panel.width * (1 - root.panels.osd.offsetScale) + root.rightExtra + sessionRegion.width
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.panels.insetTop
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.panels.insetBottom
    }

    R {
        panel: root.panels.popoutsWrapper
        width: root.bar.horizontal ? panel.width : panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
        height: root.bar.horizontal ? panel.height * (1 - root.panels.popoutsWrapper.offsetScale) : panel.height
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.panels.insetLeft
        y: panel.y + root.panels.insetTop
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
