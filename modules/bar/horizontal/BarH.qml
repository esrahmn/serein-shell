pragma ComponentBehavior: Bound

import "../popouts" as BarPopouts
import "../components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Serein.Config
import qs.components
import qs.services

// Horizontal bar for the top/bottom screen edge. Mirrors Bar.qml (same entries from
// Config.bar.entries, same popout/scroll hooks) but lays everything out along x.
RowLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    readonly property int hPadding: Tokens.padding.large
    // Width of the centred clock, so the window title knows where to stop
    property real clockWidth

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const tray = (repeater.itemAt(i) as EntryWrapper)?.item as HTray;
            if (tray)
                tray.expanded = false;
        }
    }

    // One panel for every status icon (wifi, bluetooth, battery, audio...) instead of a popout each
    function openControlCenter(): void {
        for (let i = 0; i < repeater.count; i++) {
            const entry = repeater.itemAt(i) as EntryWrapper;
            if (entry?.entryId === "statusIcons") {
                popouts.currentName = "controlcenter";
                popouts.currentCenter = Qt.binding(() => entry.mapToItem(root, entry.width / 2, 0).x);
                popouts.hasCurrent = true;
                return;
            }
        }
    }

    function toggleControlCenter(): void {
        if (popouts.hasCurrent && popouts.currentName === "controlcenter")
            popouts.hasCurrent = false;
        else
            openControlCenter();
    }

    function checkPopout(x: real): void {
        const ch = childAt(x, height / 2) as EntryWrapper;

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;

        if (id === "statusIcons") {
            // The control center opens on click (or its shortcut), never on hover. An open control center stays;
            // any other popout closes, since the status icons have none of their own.
            if (!(popouts.hasCurrent && popouts.currentName === "controlcenter"))
                popouts.hasCurrent = false;
        } else if (id === "tray" && Config.bar.popouts.tray) {
            const tray = ch.item as HTray;
            // Compact tray: hovering the collapsed tray expands it; popouts only work on the revealed icons
            if (Config.bar.tray.compact && (!tray.expanded || tray.expandIcon.contains(mapToItem(tray.expandIcon, x, ch.height / 2)))) {
                popouts.hasCurrent = false;
                tray.expanded = true;
                return;
            }

            let index = -1;
            for (let i = 0; i < tray.items.count; i++) {
                const it = tray.items.itemAt(i);
                const left = it.mapToItem(root, 0, 0).x;
                if (x >= left && x <= left + it.width) {
                    index = i;
                    break;
                }
            }
            const model = tray.items.itemAt(index);
            if (model) {
                popouts.currentName = `traymenu${index}`;
                popouts.currentCenter = Qt.binding(() => model.mapToItem(root, model.implicitWidth / 2, 0).x);
                popouts.hasCurrent = true;
            } else {
                popouts.hasCurrent = false;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = (ch.item as Item).mapToItem(root, (ch.item as Item).implicitWidth / 2, 0).x ?? 0;
            popouts.hasCurrent = true;
        } else {
            popouts.hasCurrent = false;
        }
    }

    function handleWheel(x: real, angleDelta: point): void {
        const ch = childAt(x, height / 2) as EntryWrapper;
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = Hypr.monitorFor(screen);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || mon.activeWorkspace?.id > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if (x < screen.width / 2 && Config.bar.scrollActions.volume) {
            // Volume scroll on the left half
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on the right half
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    spacing: Tokens.spacing.medium

    Repeater {
        id: repeater

        model: ScriptModel {
            values: root.Config.bar.entries.values.filter(e => e.enabled)
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    // No gap between the workspaces and the window title: the title sits right next to
                    // them and follows the workspace pill as it expands
                    visible: repeater.model.values[index + 1]?.id !== "activeWindow"
                    Layout.fillWidth: true
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: EntryWrapper {
                    OsIcon {
                        objectName: "taskbarLogo"
                    }
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    HWorkspaces {
                        objectName: "taskbarWorkspaces"
                        screen: root.screen
                        fullscreen: root.fullscreen
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    HActiveWindow {
                        objectName: "taskbarActiveWindow"
                        bar: root
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    HTray {
                        objectName: "taskbarTray"
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    id: clockEntry

                    // Takes no space in the row: the clock sits in the exact centre of the bar, so the tray
                    // ends up right next to the status icons
                    Layout.preferredWidth: 0
                    Layout.leftMargin: -root.spacing * 1.75

                    HClock {
                        objectName: "taskbarClock"
                        x: (root.width - width) / 2 - clockEntry.x
                        onWidthChanged: root.clockWidth = width
                        Component.onCompleted: root.clockWidth = width
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    HStatusIcons {
                        objectName: "taskbarStatusIcons"
                        onClicked: root.toggleControlCenter()
                    }
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: EntryWrapper {
                    Power {
                        objectName: "taskbarPowerButton"
                        screenState: root.screenState
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        Layout.leftMargin: index === 0 ? root.hPadding : 0
        Layout.rightMargin: index === repeater.count - 1 ? root.hPadding : 0
        Layout.alignment: Qt.AlignVCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
