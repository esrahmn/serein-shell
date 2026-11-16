pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import M3Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Serein.Config
import Serein.I18n
import qs.components
import qs.services
import qs.utils

// Serein control center: a bento card opened by clicking the status pill in the bar.
// Brightness (moon phase), Wi-Fi / Bluetooth / Quiet tiles, wavy volume, battery drop, power mode.
Item {
    id: root

    required property PopoutState popouts

    readonly property var monitor: Brightness.getMonitorForScreen(QsWindow.window?.screen ?? null)
    readonly property real brightness: monitor?.brightness ?? 0.5
    readonly property real tileGap: Tokens.spacing.medium
    readonly property real tileRadius: Tokens.rounding.extraLarge
    readonly property color tileColour: Colours.layer(Colours.palette.m3surfaceContainer, 2)
    readonly property color activeTileColour: Colours.palette.m3secondaryContainer
    readonly property color mutedColour: Colours.palette.m3onSurfaceVariant
    readonly property color accent: Colours.palette.m3primary

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool onBattery: battery.isLaptopBattery
    readonly property real batteryLevel: Math.max(0, Math.min(1, battery.percentage))
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged

    readonly property var connectedBt: Bluetooth.devices.values.filter(d => d.connected) // qmllint disable unresolved-type

    function formatTime(s: int): string {
        const h = Math.floor(s / 3600);
        const m = Math.floor(s / 60) % 60;
        return h > 0 ? Tr.tr("%1 h %2 min").arg(h).arg(m) : Tr.tr("%1 min").arg(m);
    }

    function cycleProfile(): void {
        const p = PowerProfiles.profile;
        if (p === PowerProfile.Balanced)
            PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
        else if (p === PowerProfile.Performance)
            PowerProfiles.profile = PowerProfile.PowerSaver;
        else
            PowerProfiles.profile = PowerProfile.Balanced;
    }

    function profileName(p: int): string {
        switch (p) {
        case PowerProfile.Performance:
            return Tr.trCtx("Performance", "power profile");
        case PowerProfile.PowerSaver:
            return Tr.trCtx("Power saver", "power profile");
        default:
            return Tr.trCtx("Balanced", "power profile");
        }
    }

    function profileIcon(p: int): string {
        switch (p) {
        case PowerProfile.Performance:
            return "bolt";
        case PowerProfile.PowerSaver:
            return "eco";
        default:
            return "balance";
        }
    }

    implicitWidth: 340
    implicitHeight: column.implicitHeight

    Column {
        id: column

        width: parent.width
        spacing: root.tileGap

        // Hero: brightness as a moon phase
        StyledClippingRect {
            id: hero

            width: parent.width
            height: 128
            radius: root.tileRadius
            color: root.tileColour

            // Faint rain
            Repeater {
                model: 9

                Rectangle {
                    required property int index

                    x: 14 + index * 38
                    y: (index % 3) * 22 - 6
                    width: 2
                    height: 34
                    radius: 1
                    rotation: 14
                    color: root.accent
                    opacity: 0.07 + (index % 3) * 0.02
                }
            }

            // Moon
            StyledClippingRect {
                id: moon

                readonly property real size: 64

                x: Tokens.padding.large + 4
                y: Tokens.padding.large + 4
                width: size
                height: size
                radius: size / 2
                color: root.accent

                Rectangle {
                    // The shadow slides off the disc as brightness goes up
                    x: root.brightness * (moon.size * 1.1)
                    width: moon.size
                    height: moon.size
                    radius: moon.size / 2
                    color: hero.color

                    Behavior on x {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }
                }
            }

            Rectangle {
                x: moon.x
                y: moon.y
                width: moon.size
                height: moon.size
                radius: moon.size / 2
                color: "transparent"
                border.width: 2
                border.color: Qt.alpha(root.accent, 0.35)
            }

            Column {
                anchors.left: moon.right
                anchors.leftMargin: Tokens.padding.large
                anchors.verticalCenter: moon.verticalCenter
                spacing: 2

                StyledText {
                    text: Tr.tr("Brightness · moon phase")
                    color: root.mutedColour
                    font: Tokens.font.body.small
                }

                StyledText {
                    animate: true
                    text: `${Math.round(root.brightness * 100)}%`
                    font: Tokens.font.headline.medium
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.large + 4
                text: Tr.trCtx("up %1", "system uptime").arg(SysInfo.uptimeShort)
                color: root.mutedColour
                font: Tokens.font.body.small
            }

            // Power button
            Rectangle {
                id: powerBtn

                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.large
                width: 44
                height: 44
                radius: width / 2
                color: Qt.alpha(Colours.palette.m3error, powerArea.containsPress ? 0.35 : 0.22)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "power_settings_new"
                    color: Colours.palette.m3error
                    fontStyle: Tokens.font.icon.medium
                }

                MouseArea {
                    id: powerArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const s = ShellState.forActive();
                        if (s) {
                            root.popouts.hasCurrent = false;
                            s.session = true;
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: powerBtn.width + Tokens.padding.large * 2
                cursorShape: Qt.SizeHorCursor
                preventStealing: true
                onPressed: event => set(event.x)
                onPositionChanged: event => {
                    if (pressed)
                        set(event.x);
                }

                function set(x: real): void {
                    root.monitor?.setBrightness(Math.max(0, Math.min(1, x / hero.width)));
                }
            }
        }

        // Shape tiles
        Row {
            width: parent.width
            spacing: root.tileGap

            ShapeTile {
                icon: Nmcli.wifiEnabled ? "wifi" : "wifi_off"
                label: "Wi-Fi"
                sub: !Nmcli.wifiEnabled ? Tr.tr("Off") : (Nmcli.active?.ssid ?? Tr.tr("Not connected"))
                checked: Nmcli.wifiEnabled
                activeShape: MaterialShape.Cookie9Sided
                onClicked: Nmcli.toggleWifi()
                onRightClicked: root.popouts.currentName = "network" // network list
            }

            ShapeTile {
                icon: Bluetooth.defaultAdapter?.enabled ? "bluetooth" : "bluetooth_disabled" // qmllint disable unresolved-type
                label: "Bluetooth"
                sub: !Bluetooth.defaultAdapter?.enabled ? Tr.tr("Off") : (root.connectedBt.length > 0 ? root.connectedBt[0].name : Tr.tr("On")) // qmllint disable unresolved-type
                checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                activeShape: MaterialShape.Clover4Leaf
                onRightClicked: root.popouts.currentName = "bluetooth" // device list
                onClicked: {
                    const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                    if (adapter)
                        adapter.enabled = !adapter.enabled;
                }
            }

            ShapeTile {
                icon: Notifs.dnd ? "notifications_off" : "notifications"
                label: Tr.tr("Quiet")
                sub: Notifs.dnd ? Tr.tr("On") : Tr.tr("Off")
                checked: Notifs.dnd
                activeShape: MaterialShape.SoftBurst
                onClicked: Notifs.dnd = !Notifs.dnd
            }
        }

        // Wavy volume
        StyledRect {
            id: volume

            width: parent.width
            height: 84
            radius: root.tileRadius
            color: root.tileColour

            StyledText {
                x: Tokens.padding.large + 4
                y: Tokens.padding.large
                text: Tr.tr("Volume · %1").arg(Audio.sink?.description ?? Audio.sink?.nickname ?? Tr.tr("No output"))
                color: root.mutedColour
                font: Tokens.font.body.small
                width: parent.width - x * 2 - volValue.width
                elide: Text.ElideRight
            }

            StyledText {
                id: volValue

                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.large + 4
                y: Tokens.padding.large
                text: Audio.muted ? Tr.tr("Muted") : `${Math.round(Audio.volume * 100)}%`
                font: Tokens.font.body.medium
            }

            Item {
                id: wave

                readonly property real amp: 4.5
                readonly property real wavelength: 30
                readonly property real progress: Math.max(0, Math.min(1, Audio.volume))
                readonly property real edge: width * progress
                property real phase: 0

                x: Tokens.padding.large + 4
                y: 40
                width: parent.width - x * 2
                height: 32

                NumberAnimation on phase {
                    running: root.visible && !Audio.muted
                    from: 0
                    to: Math.PI * 2
                    duration: 1800
                    loops: Animation.Infinite
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: 5
                        strokeColor: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        startX: wave.edge
                        startY: wave.height / 2

                        PathLine {
                            x: wave.width
                            y: wave.height / 2
                        }
                    }

                    ShapePath {
                        strokeWidth: 5
                        strokeColor: Audio.muted ? root.mutedColour : root.accent
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        PathPolyline {
                            path: {
                                const pts = [];
                                const e = wave.edge;
                                const n = Math.max(2, Math.ceil(e / 3));
                                for (let i = 0; i <= n; i++) {
                                    const px = e * i / n;
                                    const fade = Math.min(1, px / 14);
                                    const py = wave.height / 2 + Math.sin(px / wave.wavelength * Math.PI * 2 - wave.phase) * wave.amp * fade;
                                    pts.push(Qt.point(px, py));
                                }
                                return pts;
                            }
                        }
                    }
                }

                Rectangle {
                    x: wave.edge - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 28
                    radius: 3
                    color: root.accent
                }

                MouseArea {
                    id: waveArea

                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onPressed: event => set(event.x)
                    onPositionChanged: event => {
                        if (pressed)
                            set(event.x);
                    }

                    function set(mx: real): void {
                        Audio.setVolume(Math.max(0, Math.min(1, (mx + anchors.margins) / wave.width)));
                    }
                }
            }
        }

        // Battery drop + power mode
        Row {
            width: parent.width
            spacing: root.tileGap

            StyledRect {
                width: (parent.width - root.tileGap) / 2
                height: 128
                radius: root.tileRadius
                color: root.tileColour

                Item {
                    id: drop

                    x: Tokens.padding.large + 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    height: 66

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        scale: 0.82
                        transformOrigin: Item.TopLeft

                        ShapePath {
                            strokeWidth: 2
                            strokeColor: Qt.alpha(root.accent, 0.4)
                            fillGradient: LinearGradient {
                                y1: 3
                                y2: 76

                                GradientStop {
                                    position: 0
                                    color: Qt.alpha(root.accent, 0.08)
                                }
                                GradientStop {
                                    position: Math.max(0.01, 1 - root.batteryLevel)
                                    color: Qt.alpha(root.accent, 0.08)
                                }
                                GradientStop {
                                    position: Math.min(0.999, 1 - root.batteryLevel + 0.002)
                                    color: root.accent
                                }
                                GradientStop {
                                    position: 1
                                    color: root.accent
                                }
                            }

                            PathSvg {
                                path: "M32 3 C32 3 8 32 8 52 A24 24 0 0 0 56 52 C56 32 32 3 32 3 Z"
                            }
                        }
                    }
                }

                Column {
                    anchors.left: drop.right
                    anchors.leftMargin: Tokens.padding.small
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.padding.large
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: root.onBattery ? `${Math.round(root.batteryLevel * 100)}%` : "AC"
                        font: Tokens.font.headline.medium
                    }

                    StyledText {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        color: root.mutedColour
                        font: Tokens.font.body.small
                        text: {
                            if (!root.onBattery)
                                return Tr.tr("No battery");
                            if (root.battery.state === UPowerDeviceState.FullyCharged)
                                return Tr.tr("Fully charged");
                            if (root.charging && root.battery.timeToFull > 0)
                                return Tr.tr("Charging · full in %1").arg(root.formatTime(root.battery.timeToFull));
                            if (root.charging)
                                return Tr.tr("Charging");
                            if (root.battery.timeToEmpty > 0)
                                return Tr.tr("%1 left").arg(root.formatTime(root.battery.timeToEmpty));
                            return Tr.tr("On battery");
                        }
                    }
                }
            }

            StyledRect {
                id: mode

                width: (parent.width - root.tileGap) / 2
                height: 128
                radius: root.tileRadius
                color: modeArea.containsPress ? Qt.darker(root.activeTileColour, 1.1) : root.activeTileColour

                Behavior on color {
                    CAnim {}
                }

                MaterialIcon {
                    x: Tokens.padding.large + 4
                    y: Tokens.padding.large + 4
                    text: root.profileIcon(PowerProfiles.profile)
                    color: Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                    fill: 1
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.padding.large + 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Tokens.padding.large + 2
                    spacing: 2

                    StyledText {
                        text: Tr.tr("Power mode")
                        color: Qt.alpha(Colours.palette.m3onSecondaryContainer, 0.7)
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        animate: true
                        text: root.profileName(PowerProfiles.profile)
                        color: Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.title.small
                    }
                }

                MouseArea {
                    id: modeArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleProfile()
                }
            }
        }
    }

    component ShapeTile: StyledRect {
        id: tile

        property string icon
        property string label
        property string sub
        property bool checked
        property int activeShape: MaterialShape.Cookie9Sided

        signal clicked
        signal rightClicked

        width: (parent.width - root.tileGap * 2) / 3
        height: 120
        radius: root.tileRadius
        color: checked ? root.activeTileColour : root.tileColour

        Behavior on color {
            CAnim {}
        }

        MaterialShape {
            id: badge

            x: Tokens.padding.large
            y: Tokens.padding.large
            implicitSize: 40
            shape: tile.checked ? tile.activeShape : MaterialShape.Circle
            color: tile.checked ? root.accent : Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
            animationEasing: Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: tile.icon
                color: tile.checked ? Colours.palette.m3onPrimary : root.mutedColour
                fontStyle: Tokens.font.icon.medium
                fill: tile.checked ? 1 : 0
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.large
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.small
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Tokens.padding.large - 2
            spacing: 1

            StyledText {
                width: parent.width
                text: tile.label
                elide: Text.ElideRight
                font: Tokens.font.body.medium
                color: tile.checked ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            }

            StyledText {
                width: parent.width
                text: tile.sub
                elide: Text.ElideRight
                font: Tokens.font.body.small
                color: tile.checked ? Qt.alpha(Colours.palette.m3onSecondaryContainer, 0.75) : root.mutedColour
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: event => event.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
        }
    }
}
