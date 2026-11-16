import "dash"
import "performance"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Serein.Config
import Serein.I18n
import Serein.Services
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: placeholder.active ? Tokens.sizes.dashboard.perfPlaceholderWidth : Tokens.sizes.dashboard.mediaTabWidth + 100
    implicitHeight: placeholder.active ? placeholder.implicitHeight + Tokens.padding.extraLarge * 2 : content.implicitHeight

    Loader {
        id: placeholder

        anchors.centerIn: parent
        active: !Config.dashboard.performance.showCpu && !(Config.dashboard.performance.showGpu && Gpu.type !== GpuType.None) && !Config.dashboard.performance.showMemory && !Config.dashboard.performance.showStorage && !Config.dashboard.performance.showNetwork && !(UPower.displayDevice.isLaptopBattery && Config.dashboard.performance.showBattery)
        asynchronous: true

        sourceComponent: ColumnLayout {
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "tune"
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.topMargin: -Tokens.spacing.small
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("No widgets enabled")
                font: Tokens.font.title.large
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Enable widgets in the dashboard settings")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium
        visible: !placeholder.active

        ColumnLayout {
            id: mainColumn

            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            // System load as layered waves: CPU, memory and disk
            StyledClippingRect {
                Layout.fillWidth: true
                implicitHeight: 124
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surfaceContainer

                NightWaves {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 46
                }

                Column {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: Tokens.padding.extraLargeIncreased
                    anchors.topMargin: Tokens.padding.large

                    StyledText {
                        text: Tr.tr("System load")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }

                    StyledText {
                        text: `${Math.round(Cpu.percentage * 100)}%`
                        font: Tokens.font.headline.builders.medium.scale(1.15).weight(Font.Medium).build()
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: Tokens.padding.extraLargeIncreased
                    anchors.topMargin: Tokens.padding.large
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: [
                            {
                                label: "CPU",
                                value: Cpu.percentage
                            },
                            {
                                label: "RAM",
                                value: Memory.percentage
                            },
                            {
                                label: Tr.tr("Disk"),
                                value: Storage.percentage
                            }
                        ]

                        StyledRect {
                            id: chip

                            required property var modelData

                            implicitWidth: chipLabel.implicitWidth + Tokens.padding.large * 2
                            implicitHeight: chipLabel.implicitHeight + Tokens.padding.small * 2
                            radius: Tokens.rounding.full
                            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                            StyledText {
                                id: chipLabel

                                anchors.centerIn: parent
                                text: `${chip.modelData.label} ${Math.round(chip.modelData.value * 100)}%`
                                font: Tokens.font.label.small
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: Tokens.spacing.medium
                visible: cpuCard.active || gpuCard.active

                WrappedLoader {
                    id: cpuCard

                    active: Config.dashboard.performance.showCpu

                    sourceComponent: BigCard {
                        icon: "memory"
                        label: Tr.tr("CPU")
                        subLabel: Cpu.name
                        usage: Cpu.percentage
                        temperature: Cpu.temperature
                        accent: Colours.palette.m3primary

                        ServiceRef {
                            service: Cpu
                        }
                    }
                }

                WrappedLoader {
                    id: gpuCard

                    active: Config.dashboard.performance.showGpu && Gpu.type !== GpuType.None

                    sourceComponent: BigCard {
                        icon: "desktop_windows"
                        label: Tr.tr("GPU")
                        subLabel: Gpu.name || (Gpu.detecting ? Tr.tr("Detecting GPU...") : Tr.trCtx("None", "GPU name"))
                        usage: Gpu.percentage
                        temperature: Gpu.temperature
                        accent: Colours.palette.m3secondary

                        ServiceRef {
                            service: Gpu
                        }
                    }
                }
            }

            SlimRow {
                Layout.fillWidth: true
                visible: Config.dashboard.performance.showMemory || Config.dashboard.performance.showStorage || Config.dashboard.performance.showNetwork || hasBattery
            }
        }
    }

    component WrappedLoader: Loader {
        Layout.fillWidth: true
        visible: active
    }
}
