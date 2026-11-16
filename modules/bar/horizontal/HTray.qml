pragma ComponentBehavior: Bound

import "../components"
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

// Horizontal system tray for a top/bottom bar. In compact mode the icons stay hidden behind an
// expand arrow until the pointer reaches it (same as the vertical tray).
StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.large : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall
    readonly property bool compact: Config.bar.tray.compact

    property bool expanded

    // Width the tray wants, ignoring any running animation
    readonly property real nonAnimWidth: {
        if (items.count === 0)
            return 0;
        if (!compact)
            return layout.implicitWidth + padding * 2;
        const arrow = expandIcon.implicitWidth + padding;
        return expanded ? arrow + layout.implicitWidth + spacing + padding : Math.max(Config.bar.tray.background ? height : 0, arrow + padding);
    }

    clip: true
    visible: width > 0

    implicitWidth: nonAnimWidth
    implicitHeight: Tokens.sizes.bar.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Row {
        id: layout

        x: root.compact ? root.padding : (root.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.small

        opacity: root.expanded || !root.compact ? 1 : 0

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => i.status !== Status.Passive && !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        anchors.right: parent.right
        anchors.rightMargin: Config.bar.tray.background ? Tokens.padding.small : 0
        anchors.verticalCenter: parent.verticalCenter

        active: root.compact && items.count > 0

        sourceComponent: MaterialIcon {
            text: "chevron_left"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            rotation: root.expanded ? 180 : 0

            Behavior on rotation {
                Anim {}
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }
}
