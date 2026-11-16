pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Serein's own UI preferences. Settings that are not part of the plugin's config schema (like the bar position and the
// lock rain) live in their own small JSON file next to the shell state.
Singleton {
    id: root

    // "left" | "right" | "top" | "bottom"
    readonly property string barPosition: ["left", "right", "top", "bottom"].includes(adapter.barPosition) ? adapter.barPosition : "left"
    readonly property bool barOnLeft: barPosition === "left"
    readonly property bool barOnRight: barPosition === "right"
    readonly property bool barOnTop: barPosition === "top"
    readonly property bool barOnBottom: barPosition === "bottom"
    readonly property bool barHorizontal: barOnTop || barOnBottom

    // Falling rain over the lock screen background
    // "weather" (only while it rains outside), "always" or "off"
    readonly property string rainMode: ["weather", "always", "off"].includes(adapter.rainMode) ? adapter.rainMode : "weather"
    readonly property bool lockRain: rainMode !== "off"
    readonly property bool rainVisible: rainMode === "always" || (rainMode === "weather" && Weather.raining)
    // Dashboard tab with live workspace previews
    readonly property bool dashboardOverview: adapter.dashboardOverview

    // Alpha of the bar and panel surface when transparency is on (0.3 to 1)
    readonly property real surfaceOpacity: Math.max(0.3, Math.min(1, adapter.surfaceOpacity))

    function setSurfaceOpacity(value: real): void {
        adapter.surfaceOpacity = Math.max(0.3, Math.min(1, Math.round(value * 100) / 100));
    }

    // "phosphor" (Mac-like line icons) or "material"
    readonly property string iconStyle: ["phosphor", "material"].includes(adapter.iconStyle) ? adapter.iconStyle : "phosphor"

    function setIconStyle(style: string): void {
        if (["phosphor", "material"].includes(style))
            adapter.iconStyle = style;
    }

    function setRainMode(mode: string): void {
        if (["weather", "always", "off"].includes(mode))
            adapter.rainMode = mode;
    }

    function setLockRain(enabled: bool): void {
        adapter.rainMode = enabled ? (rainMode === "off" ? "weather" : rainMode) : "off";
    }

    function setDashboardOverview(enabled: bool): void {
        adapter.dashboardOverview = enabled;
    }

    function setBarPosition(pos: string): void {
        if (["left", "right", "top", "bottom"].includes(pos))
            adapter.barPosition = pos;
    }

    FileView {
        path: `${Paths.state}/serein-ui.json`
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: adapter

            property string barPosition: "left"
            property bool lockRain: true
            property string rainMode: "weather"
            property bool dashboardOverview: true
            property real surfaceOpacity: 0.7
            property string iconStyle: "phosphor"
        }
    }
}
