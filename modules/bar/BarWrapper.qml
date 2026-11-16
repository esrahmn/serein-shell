pragma ComponentBehavior: Bound

import "horizontal" as Horizontal
import QtQuick
import Quickshell
import Serein.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    readonly property bool horizontal: UiPrefs.barHorizontal
    readonly property bool onRight: UiPrefs.barOnRight
    readonly property bool onBottom: UiPrefs.barOnBottom
    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    // Thickness of the bar across its short axis: animates between the plain border and the full bar
    property real size: fullscreen ? 0 : Config.border.thickness
    readonly property int clampedSize: Math.max(Config.border.minThickness, size)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentSize: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentSize : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered)
    property bool isHovered

    // `pos` is the pointer coordinate along the bar: y for a left/right bar, x for a top/bottom bar
    function closeTray(): void {
        content.item?.closeTray(); // qmllint disable missing-property
    }

    function checkPopout(pos: real): void {
        content.item?.checkPopout(pos); // qmllint disable missing-property
    }

    function toggleControlCenter(): void {
        content.item?.toggleControlCenter(); // qmllint disable missing-property
    }

    function handleWheel(pos: real, angleDelta: point): void {
        content.item?.handleWheel(pos, angleDelta); // qmllint disable missing-property
    }

    clip: true
    visible: size > Config.border.thickness
    implicitWidth: horizontal ? 0 : size
    implicitHeight: horizontal ? size : 0

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.size: root.contentSize
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "size"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "size"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        // Explicit geometry (not conditional anchors) so switching edges live leaves no stale position.
        // The content stays pinned to the inner side while the wrapper grows from the screen edge.
        x: root.horizontal ? 0 : (root.onRight ? 0 : root.width - width)
        y: root.horizontal ? (root.onBottom ? 0 : root.height - height) : 0
        width: root.horizontal ? root.width : root.contentSize
        height: root.horizontal ? root.contentSize : root.height

        active: root.shouldBeVisible
        sourceComponent: root.horizontal ? horizontalBar : verticalBar
    }

    Component {
        id: verticalBar

        Bar {
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }

    Component {
        id: horizontalBar

        Horizontal.BarH {
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }
}
