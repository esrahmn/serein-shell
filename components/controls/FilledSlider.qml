import "../effects"
import QtQuick
import QtQuick.Shapes
import QtQuick.Templates
import Serein.Config
import qs.components
import qs.services

Slider {
    id: root

    required property string icon
    // The filled part is a water level with a gently moving surface
    property bool wavy: false
    // The handle shows a moon whose phase follows the value (for brightness)
    property bool moon: false
    property real phase
    property real oldValue
    property bool initialized

    orientation: Qt.Vertical

    background: StyledRect {
        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            visible: !root.wavy

            y: root.handle.y
            implicitHeight: parent.height - y

            color: Colours.palette.m3secondary
            radius: parent.radius
        }

        // Wavy fill: a vertical sine wave from the handle down to the bottom, like the wavy seek bar
        StyledClippingRect {
            anchors.fill: parent
            radius: parent.radius
            visible: root.wavy

            FrameAnimation {
                running: root.wavy && root.visible
                onTriggered: root.phase = (root.phase + frameTime * 4) % (Math.PI * 2)
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 5
                    strokeColor: Colours.palette.m3secondary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: {
                            const pts = [];
                            const y0 = root.handle.y + root.handle.height / 2;
                            const y1 = root.height - root.width / 2;
                            for (let y = y0; y <= y1; y += 3)
                                pts.push(Qt.point(root.width / 2 + Math.sin(y / 22 * Math.PI * 2 - root.phase) * 5.5, y));
                            if (pts.length < 2)
                                pts.push(Qt.point(root.width / 2, y0), Qt.point(root.width / 2, y0 + 1));
                            return pts;
                        }
                    }
                }
            }
        }
    }

    handle: Item {
        id: handle

        property alias moving: icon.moving

        y: root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        Elevation {
            anchors.fill: parent
            radius: rect.radius
            level: handleInteraction.containsMouse ? 2 : 1
        }

        StyledRect {
            id: rect

            anchors.fill: parent

            color: Colours.palette.m3inverseSurface
            radius: Tokens.rounding.full

            MouseArea {
                id: handleInteraction

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }

            MoonDisc {
                anchors.centerIn: parent
                implicitWidth: root.width - 12
                implicitHeight: root.width - 12
                visible: root.moon && !icon.moving
                illumination: root.value
                waxing: true
                lit: Colours.palette.m3inverseOnSurface
            }

            MaterialIcon {
                id: icon

                property bool moving

                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: moving ? Math.round(root.value * 100) : root.icon
                visible: !(root.moon && !moving)
                color: Colours.palette.m3inverseOnSurface
                font: moving ? Tokens.font.body.small : Tokens.font.icon.medium

                Behavior on moving {
                    SequentialAnimation {
                        Anim {
                            target: icon
                            property: "scale"
                            to: 0.3
                            duration: Tokens.anim.durations.small / 2
                            easing: Tokens.anim.standardAccel
                        }
                        PropertyAction {}
                        Anim {
                            target: icon
                            property: "scale"
                            to: 1
                            duration: Tokens.anim.durations.normal / 2
                            easing: Tokens.anim.standardDecel
                        }
                    }
                }
            }
        }
    }

    onPressedChanged: handle.moving = pressed

    onValueChanged: {
        if (!initialized) {
            initialized = true;
            return;
        }
        if (Math.abs(value - oldValue) < 0.01)
            return;
        oldValue = value;
        handle.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: 500
        onTriggered: {
            if (!root.pressed)
                handle.moving = false;
        }
    }

    Behavior on value {
        Anim {
            type: Anim.StandardLarge
        }
    }
}
