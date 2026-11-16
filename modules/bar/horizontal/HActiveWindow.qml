pragma ComponentBehavior: Bound

import QtQuick
import Serein.Config
import Serein.I18n
import qs.components
import qs.services
import qs.utils

// Horizontal active window (icon + title) for a top/bottom bar
Item {
    id: root

    required property var bar
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return Tr.trCtx("Desktop", "shown when no window is focused");
        if (Config.bar.activeWindow.compact) {
            const parts = title.split(/\s+[\-–—]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    // Width left for the title: it stops before the centred clock
    readonly property real maxWidth: Math.max(0, bar.width / 2 - bar.clockWidth / 2 - Tokens.spacing.large - (parent?.x ?? 0) - icon.implicitWidth - Tokens.spacing.small)

    clip: true
    implicitWidth: icon.implicitWidth + Tokens.spacing.small + title.implicitWidth
    implicitHeight: Math.max(icon.implicitHeight, title.implicitHeight)

    Behavior on implicitWidth {
        Anim {}
    }

    Loader {
        asynchronous: true
        anchors.fill: parent
        // See ActiveWindow.qml: with the hover popout off, a click opens the detached window info panel
        active: !Config.bar.activeWindow.showOnHover || !Config.bar.popouts.activeWindow

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (!root.Config.bar.popouts.activeWindow) {
                    popouts.detach("winfo");
                } else if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.mapToItem(root.bar, root.implicitWidth / 2, 0).x;
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    StyledText {
        id: title

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Tokens.spacing.small

        animate: true
        text: metrics.elidedText
        font: metrics.font
        color: root.colour
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: root.Tokens.font.body.builders.small.letterSpacing(1.4).build()
        elide: Qt.ElideRight
        elideWidth: root.maxWidth
    }
}
