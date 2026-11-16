pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.UPower
import Serein.Config
import Serein.I18n
import Serein.Services
import qs.components
import qs.services
import qs.utils

// One thin row: memory, storage, network and battery
StyledRect {
    id: root

    readonly property real storagePerc: Storage.primaryDisk?.perc ?? 0
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery.isLaptopBattery && Config.dashboard.performance.showBattery
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge
    implicitHeight: 64

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    ServiceRef {
        service: NetworkUsage
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.extraLargeIncreased
        anchors.rightMargin: Tokens.padding.extraLargeIncreased
        spacing: Tokens.spacing.extraLarge

        Meter {
            visible: Config.dashboard.performance.showMemory
            Layout.fillWidth: true
            Layout.preferredWidth: 240
            Layout.alignment: Qt.AlignVCenter
            label: Tr.tr("Memory")
            value: Memory.percentage
            detail: Units.formatKibUsage(Memory.used, Memory.total)
        }

        Meter {
            visible: Config.dashboard.performance.showStorage
            Layout.fillWidth: true
            Layout.preferredWidth: 240
            Layout.alignment: Qt.AlignVCenter
            label: Tr.tr("Storage")
            value: root.storagePerc
            detail: Storage.primaryDisk ? Units.formatKibUsage(Storage.primaryDisk.used, Storage.primaryDisk.total) : Tr.tr("No disks detected")
        }

        Row {
            visible: Config.dashboard.performance.showNetwork
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 200
            spacing: Tokens.spacing.large

            Speed {
                icon: "download"
                value: Units.formatBytes(NetworkUsage.downloadSpeed ?? 0, true)
            }

            Speed {
                icon: "upload"
                value: Units.formatBytes(NetworkUsage.uploadSpeed ?? 0, true)
            }
        }

        Row {
            visible: root.hasBattery
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.small

            // Battery drop that fills with the charge
            Item {
                width: 22
                height: 28
                anchors.verticalCenter: parent.verticalCenter

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    scale: 0.35
                    transformOrigin: Item.TopLeft

                    ShapePath {
                        strokeWidth: 0
                        fillGradient: LinearGradient {
                            y1: 3
                            y2: 76

                            GradientStop {
                                position: 0
                                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
                            }
                            GradientStop {
                                position: Math.max(0.01, 1 - root.battery.percentage)
                                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
                            }
                            GradientStop {
                                position: Math.min(0.999, 1 - root.battery.percentage + 0.002)
                                color: Colours.palette.m3primary
                            }
                            GradientStop {
                                position: 1
                                color: Colours.palette.m3primary
                            }
                        }

                        PathSvg {
                            path: "M32 3 C32 3 8 32 8 52 A24 24 0 0 0 56 52 C56 32 32 3 32 3 Z"
                        }
                    }
                }
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(root.battery.percentage * 100)}%${root.charging ? " · " + Tr.tr("charging") : ""}`
                font: Tokens.font.body.small
            }
        }
    }

    component Meter: Item {
        id: meter

        property string label
        property real value
        property string detail

        implicitWidth: 240
        implicitHeight: col.implicitHeight

        Column {
            id: col

            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: Tokens.spacing.extraSmall

            Row {
                width: parent.width

                StyledText {
                    width: parent.width - pct.implicitWidth
                    text: meter.label
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                StyledText {
                    id: pct

                    text: `${Math.round(meter.value * 100)}%`
                    font: Tokens.font.label.small
                }
            }

            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, meter.value))
                    height: parent.height
                    radius: 3
                    color: Colours.palette.m3primary

                    Behavior on width {
                        Anim {}
                    }
                }
            }

            StyledText {
                width: parent.width
                text: meter.detail
                elide: Text.ElideRight
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                opacity: 0.8
            }
        }
    }

    component Speed: Row {
        id: speed

        property string icon
        property string value

        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: speed.icon
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: speed.value
            font: Tokens.font.body.small
        }
    }
}
