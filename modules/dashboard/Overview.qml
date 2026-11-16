pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Serein.Config
import Serein.I18n
import qs.components
import qs.services
import qs.utils

// Workspace overview: a grid of miniature screens, one per workspace, with live previews of the
// windows on each (screencopy). Click a workspace to switch to it, or a window to focus it.
Item {
    id: root

    required property ScreenState screenState

    readonly property int columns: 5
    readonly property int rows: 2
    readonly property int perGroup: columns * rows
    readonly property int spacing: Tokens.spacing.medium
    readonly property int pad: Tokens.padding.large

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screenState.modelData)
    readonly property var monIpc: monitor?.lastIpcObject ?? null
    // Logical (scaled) monitor size, which is what window positions are expressed in
    readonly property real monW: monIpc ? monIpc.width / (monIpc.scale || 1) : 1600
    readonly property real monH: monIpc ? monIpc.height / (monIpc.scale || 1) : 900
    readonly property real monX: monIpc?.x ?? 0
    readonly property real monY: monIpc?.y ?? 0

    readonly property int activeWsId: Hypr.activeWsId
    // Show the group of workspaces (1-10, 11-20, ...) the active one belongs to
    readonly property int groupOffset: Math.floor((activeWsId - 1) / perGroup) * perGroup

    readonly property real cardWidth: (width - pad * 2 - spacing * (columns - 1)) / columns
    readonly property real cardHeight: cardWidth * monH / monW
    readonly property real scaleFactor: cardWidth / monW

    // Only stream frames while the tab is on screen
    readonly property bool live: screenState.dashboard && visible

    // Workspace card under the pointer while a window is being dragged (0 = none)
    property int dragTargetWs

    // Workspace id of the card at a scene position, or 0
    function wsAt(scenePos: point): int {
        for (let i = 0; i < cards.count; i++) {
            const c = cards.itemAt(i);
            const p = c.mapFromItem(null, scenePos.x, scenePos.y);
            if (p.x >= 0 && p.y >= 0 && p.x <= c.width && p.y <= c.height)
                return c.wsId;
        }
        return 0;
    }

    // Send a window to another workspace without following it
    function moveWindow(toplevel: HyprlandToplevel, ws: int): void {
        const addr = `0x${toplevel.address}`;
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:${addr}", workspace = "${ws}", follow = false })` : `movetoworkspacesilent ${ws},address:${addr}`);
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
    }

    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth + 140
    implicitHeight: pad * 2 + cardHeight * rows + spacing * (rows - 1)

    // Window geometry only refreshes on open/close/move events, so poll while the tab is visible
    Timer {
        interval: 500
        repeat: true
        running: root.live
        onTriggered: Hyprland.refreshToplevels()
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        columns: root.columns
        rowSpacing: root.spacing
        columnSpacing: root.spacing

        Repeater {
            id: cards

            model: root.perGroup

            Item {
                id: card

                required property int index

                readonly property int wsId: root.groupOffset + index + 1
                readonly property bool focused: wsId === root.activeWsId
                readonly property list<HyprlandToplevel> windows: Hypr.toplevelsForWs(wsId, GlobalConfig.bar.workspaces.ignoredTags)

                Layout.preferredWidth: root.cardWidth
                Layout.preferredHeight: root.cardHeight

                // Not clipping, so a window being dragged can leave its card (the card is lifted above
                // its neighbours while that happens)
                StyledRect {
                    id: cardClip

                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    color: card.focused ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : Colours.tPalette.m3surfaceContainer

                    // Highlight the workspace a dragged window would be dropped on
                    Rectangle {
                        anchors.fill: parent
                        color: Colours.palette.m3primary
                        opacity: root.dragTargetWs === card.wsId ? 0.18 : 0

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Hypr.activeWsId !== card.wsId)
                                Hypr.focusWorkspace(card.wsId);
                            root.screenState.dashboard = false;
                        }
                    }

                    // The windows on this workspace, drawn at their real (scaled) position
                    Repeater {
                        model: ScriptModel {
                            // Floating windows on top of tiled ones
                            values: card.windows.slice().sort((a, b) => (a.lastIpcObject.floating ? 1 : 0) - (b.lastIpcObject.floating ? 1 : 0))
                        }

                        WindowThumb {
                            cardItem: cardClip
                        }
                    }
                }

                // Outline for the focused workspace
                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rounding.small
                    color: "transparent"
                    border.width: 2
                    border.color: Colours.palette.m3primary
                    opacity: card.focused ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    component WindowThumb: ClippingRectangle {
        id: thumb

        required property HyprlandToplevel modelData
        required property Item cardItem

        readonly property var ipc: modelData.lastIpcObject
        readonly property bool isActive: Hypr.activeToplevel === modelData
        readonly property bool dragging: dragHandler.active

        // Resting position inside the card; while dragging it follows the pointer
        readonly property real baseX: ((ipc.at?.[0] ?? 0) - root.monX) * root.scaleFactor
        readonly property real baseY: ((ipc.at?.[1] ?? 0) - root.monY) * root.scaleFactor

        x: baseX + (dragging ? dragHandler.translation.x : 0)
        y: baseY + (dragging ? dragHandler.translation.y : 0)
        width: Math.max(4, (ipc.size?.[0] ?? 0) * root.scaleFactor)
        height: Math.max(4, (ipc.size?.[1] ?? 0) * root.scaleFactor)

        radius: Tokens.rounding.extraSmall
        color: Colours.palette.m3surfaceContainerHigh
        border.width: isActive || dragging ? 2 : 1
        border.color: isActive || dragging ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
        opacity: dragging ? 0.85 : 1

        // Lift the whole card above the others while one of its windows is dragged
        Binding {
            target: thumb.cardItem.parent
            property: "z"
            value: 10
            when: thumb.dragging
        }

        Behavior on x {
            enabled: !thumb.dragging

            Anim {}
        }
        Behavior on y {
            enabled: !thumb.dragging

            Anim {}
        }
        Behavior on width {
            Anim {}
        }
        Behavior on height {
            Anim {}
        }

        ScreencopyView {
            id: preview

            anchors.fill: parent
            captureSource: thumb.modelData.wayland ?? null // qmllint disable unresolved-type
            live: root.live
        }

        // Drag a window onto another workspace card to move it there. The drop target is worked out
        // from the pointer position (no DropArea: it only fires if Drag.drop() is called first).
        DragHandler {
            id: dragHandler

            target: null
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.ClosedHandCursor

            onCentroidChanged: {
                if (active)
                    root.dragTargetWs = root.wsAt(centroid.scenePosition);
            }

            onActiveChanged: {
                if (active)
                    return;
                const target = root.dragTargetWs;
                root.dragTargetWs = 0;
                if (target > 0 && target !== thumb.ipc.workspace?.id)
                    root.moveWindow(thumb.modelData, target);
            }
        }

        // Keep the dashboard from treating the press/drag as a swipe while a thumbnail is held
        Binding {
            target: root.screenState
            property: "dashboardDragLock"
            value: true
            when: tap.pressed || dragHandler.active
        }

        // A tap (no drag) focuses the window
        TapHandler {
            id: tap

            onTapped: {
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${thumb.modelData.address}" })` : `focuswindow address:0x${thumb.modelData.address}`);
                root.screenState.dashboard = false;
            }
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}
