pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Serein.Config
import Serein.I18n
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

// Everything that is specific to Serein, in one place
PageBase {
    id: root

    title: Tr.tr("Serein")

    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: Tr.tr("Left")
            icon: "dock_to_left"
            value: "left"
        },
        MenuItem {
            text: Tr.tr("Right")
            icon: "dock_to_right"
            value: "right"
        },
        MenuItem {
            text: Tr.tr("Top")
            icon: "dock_to_bottom"
            value: "top"
        },
        MenuItem {
            text: Tr.tr("Bottom")
            icon: "dock_to_bottom"
            value: "bottom"
        }
    ]

    readonly property list<MenuItem> rainItems: [
        MenuItem {
            text: Tr.tr("When it rains")
            icon: "rainy"
            value: "weather"
        },
        MenuItem {
            text: Tr.tr("Always")
            icon: "water_drop"
            value: "always"
        },
        MenuItem {
            text: Tr.tr("Never")
            icon: "clear_day"
            value: "off"
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Look")
        }

        SliderRow {
            first: true
            icon: "opacity"
            label: Tr.tr("Bar and panel opacity")
            valueLabel: Strings.percentOne(UiPrefs.surfaceOpacity)
            value: (UiPrefs.surfaceOpacity - 0.3) / 0.7
            enabled: Colours.transparency.enabled
            onMoved: v => UiPrefs.setSurfaceOpacity(0.3 + v * 0.7)
        }

        ToggleRow {
            last: true
            text: Tr.tr("Line icons")
            subtext: Tr.tr("Thin Phosphor icons instead of Material Symbols")
            checked: UiPrefs.iconStyle === "phosphor"
            onToggled: UiPrefs.setIconStyle(checked ? "phosphor" : "material")
        }

        SectionHeader {
            text: Tr.tr("Taskbar")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Screen edge")
            subtext: Tr.tr("Which side of the screen the bar sits on")
            menuItems: root.positionItems
            active: root.positionItems.find(i => i.value === UiPrefs.barPosition)
            onSelected: item => UiPrefs.setBarPosition(item.value)
        }

        SectionHeader {
            text: Tr.tr("Rain")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Falling rain")
            subtext: Tr.tr("On the lock screen and in the control center")
            menuItems: root.rainItems
            active: root.rainItems.find(i => i.value === UiPrefs.rainMode)
            onSelected: item => UiPrefs.setRainMode(item.value)
        }

        SectionHeader {
            text: Tr.tr("Dashboard")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Workspaces tab")
            subtext: Tr.tr("Live previews of your workspaces; drag windows between them")
            checked: UiPrefs.dashboardOverview
            onToggled: UiPrefs.setDashboardOverview(checked)
        }
    }
}
