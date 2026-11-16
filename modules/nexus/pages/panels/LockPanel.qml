pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Lock screen")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Appearance")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Use wallpaper as background")
            subtext: Tr.tr("Blur the wallpaper instead of a snapshot of the screen")
            checked: Config.lock.useWallpaper
            onToggled: GlobalConfig.lock.useWallpaper = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Falling rain")
            subtext: Tr.tr("Fine rain drifting over the lock screen background")
            checked: UiPrefs.lockRain
            onToggled: UiPrefs.setLockRain(checked)
        }
    }
}
