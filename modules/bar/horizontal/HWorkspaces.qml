pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Horizontal workspace indicator for a top/bottom bar. Same display options as the vertical one
// (shapes, text or icon rules, window icons, occupied background, active indicator), laid out along x.
StyledRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property int activeWsId: monitor.activeWorkspace?.id ?? 1
    readonly property int shown: Math.max(1, Config.bar.workspaces.shown)
    readonly property int cell: Tokens.sizes.bar.innerWidth - Tokens.padding.small
    readonly property int pad: Tokens.padding.extraSmall
    readonly property bool onSpecial: (monitor?.lastIpcObject.specialWorkspace?.name ?? "") !== ""

    readonly property var wsIds: {
        if (Config.bar.workspaces.showUnoccupied) {
            const offset = Math.floor((activeWsId - 1) / shown) * shown;
            return Array.from({
                length: shown
            }, (_, i) => offset + i + 1);
        }

        const allMonitors = !Config.bar.workspaces.perMonitor;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const workspaces = Hypr.workspaces.values.filter(w => w.id > 0 && (allMonitors || w.monitor === root.monitor) && (w.id === activeWsId || w.toplevels.values.some(t => !Hypr.isToplevelIgnored(t, ignoredTags))));
        const currentIdx = workspaces.findIndex(w => w.id === activeWsId);
        if (currentIdx < 0)
            return [];

        const end = CUtils.clamp(currentIdx + 1, Math.min(shown, workspaces.length), workspaces.length);
        const start = Math.max(0, end - shown);
        return workspaces.slice(start, end).map(w => w.id);
    }

    readonly property int activeIdx: wsIds.indexOf(activeWsId)
    readonly property Item activeCell: {
        repeater.count; // re-evaluate when cells are (re)created
        return activeIdx >= 0 ? repeater.itemAt(activeIdx) as Item : null;
    }

    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: Tokens.sizes.bar.innerWidth

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    opacity: onSpecial ? 0.5 : 1

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    // Highlight behind the focused workspace
    StyledRect {
        visible: Config.bar.workspaces.activeIndicator && root.activeCell !== null
        x: root.pad + (root.activeCell?.x ?? 0)
        y: root.pad
        width: root.activeCell?.width ?? 0
        height: root.height - root.pad * 2
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary

        Behavior on x {
            Anim {}
        }

        Behavior on width {
            Anim {}
        }
    }

    Row {
        id: row

        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: repeater

            model: ScriptModel {
                values: root.wsIds
            }

            Item {
                id: ws

                required property int modelData

                readonly property var wsObj: Hypr.workspaces.values.find(w => w.id === modelData) ?? null
                readonly property list<HyprlandToplevel> toplevels: Hypr.toplevelsForWs(modelData, GlobalConfig.bar.workspaces.ignoredTags)
                readonly property bool occupied: toplevels.length > 0
                readonly property bool focused: modelData === root.activeWsId
                readonly property bool onOtherMonitor: {
                    if (Config.bar.workspaces.perMonitor)
                        return false;
                    const mon = wsObj?.monitor;
                    return !!mon && mon !== root.monitor;
                }
                readonly property color fg: {
                    if (onOtherMonitor)
                        return Colours.palette.m3outlineVariant;
                    if (focused && Config.bar.workspaces.activeIndicator)
                        return Colours.palette.m3onPrimary;
                    if (focused || occupied || Config.bar.workspaces.occupiedBg)
                        return Colours.palette.m3onSurface;
                    return Colours.layer(Colours.palette.m3outlineVariant, 2);
                }
                readonly property string iconName: Icons.matchIconRuleList(Hypr.trimWsName(wsObj?.name ?? ""), GlobalConfig.bar.workspaces.workspaceIcons)
                readonly property bool hasWindows: occupied && Config.bar.workspaces.showWindows && Config.bar.workspaces.maxWindowIcons > 0

                readonly property string label: {
                    if (focused && Config.bar.workspaces.activeLabel)
                        return Config.bar.workspaces.activeLabel;
                    if ((focused || occupied) && Config.bar.workspaces.occupiedLabel)
                        return Config.bar.workspaces.occupiedLabel;
                    if (Config.bar.workspaces.label)
                        return Config.bar.workspaces.label;

                    const name = !wsObj || wsObj.name == modelData ? modelData : Hypr.trimWsName(wsObj.name)[0];
                    const cap = Config.bar.workspaces.capitalisation;
                    if (cap === BarWorkspaceCapitalisation.Upper)
                        return String(name).toUpperCase();
                    if (cap === BarWorkspaceCapitalisation.Lower)
                        return String(name).toLowerCase();
                    return String(name);
                }

                width: root.cell + (hasWindows ? windowRow.implicitWidth + Tokens.spacing.extraSmall : 0)
                height: root.height - root.pad * 2

                Behavior on width {
                    Anim {}
                }

                // Occupied background, shown behind workspaces that have windows
                StyledRect {
                    anchors.fill: parent
                    visible: Config.bar.workspaces.occupiedBg
                    radius: Tokens.rounding.full
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                    opacity: ws.occupied ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                // Workspace indicator: shape, text label or icon rule
                Item {
                    id: indicator

                    width: root.cell
                    height: parent.height

                    MaterialShape {
                        visible: Config.bar.workspaces.displayType === BarWorkspaceDisplay.Shapes || (Config.bar.workspaces.displayType === BarWorkspaceDisplay.Icons && ws.iconName === "")
                        anchors.centerIn: parent
                        implicitSize: root.cell
                        shape: ws.occupied || ws.focused ? MaterialShape.Square : MaterialShape.Circle
                        color: ws.fg
                        scale: ws.focused ? 2 / 3 : ws.occupied ? 1 / 3 : 1 / 4

                        Behavior on scale {
                            Anim {}
                        }

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    MaterialIcon {
                        visible: Config.bar.workspaces.displayType === BarWorkspaceDisplay.Icons && ws.iconName !== ""
                        anchors.centerIn: parent
                        fill: 1
                        grade: 25
                        text: ws.iconName
                        color: ws.fg
                    }

                    StyledText {
                        visible: Config.bar.workspaces.displayType === BarWorkspaceDisplay.Text
                        anchors.centerIn: parent
                        animate: true
                        text: ws.label
                        color: ws.fg
                        font.family: Tokens.font.workspaces
                    }
                }

                // Icons of the windows on this workspace
                Row {
                    id: windowRow

                    visible: ws.hasWindows
                    anchors.left: indicator.right
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: ScriptModel {
                            values: {
                                const max = ws.Config.bar.workspaces.maxWindowIcons; // via an Item: ScriptModel has no screen
                                return max > 0 ? ws.toplevels.slice(0, max) : ws.toplevels;
                            }
                        }

                        MaterialIcon {
                            required property var modelData

                            grade: 0
                            text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                            color: ws?.focused && Config.bar.workspaces.activeIndicator ? Colours.palette.m3onPrimary : ws?.onOtherMonitor ? Colours.palette.m3outlineVariant : Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: event => {
            const px = event.x - root.pad;
            for (let i = 0; i < repeater.count; i++) {
                const it = repeater.itemAt(i);
                if (px >= it.x && px <= it.x + it.width) {
                    const id = root.wsIds[i];
                    if (Hypr.activeWsId !== id)
                        Hypr.focusWorkspace(id);
                    else
                        Hypr.toggleSpecial("special");
                    return;
                }
            }
        }
    }
}
