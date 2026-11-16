import QtQuick
import QtQuick.Shapes
import Serein.Config
import Serein.Services
import qs.components
import qs.services

// Three layered waves along the bottom of the night scene: CPU, memory and disk, the higher the usage the higher the wave
Item {
    id: root

    property real phase: 0

    readonly property var layers: [
        {
            level: Cpu.percentage,
            opacity: 1,
            offset: 0,
            speed: 1
        },
        {
            level: Memory.percentage,
            opacity: 0.55,
            offset: 2,
            speed: 0.7
        },
        {
            level: Storage.percentage,
            opacity: 0.3,
            offset: 4,
            speed: 0.5
        }
    ]

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    FrameAnimation {
        running: root.visible && root.width > 0
        onTriggered: root.phase += frameTime * 0.8
    }

    Repeater {
        model: root.layers

        Shape {
            id: layer

            required property var modelData

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            readonly property var pts: {
                const w = root.width, h = root.height;
                const out = [];
                const base = h * 0.62 - modelData.level * h * 0.45;
                for (let x = 0; x <= w + 8; x += 8)
                    out.push(Qt.point(x, base + Math.sin(x / 70 + modelData.offset + root.phase * modelData.speed) * h * 0.09));
                return out;
            }

            ShapePath {
                strokeWidth: 0
                fillColor: Qt.alpha(Colours.palette.m3primary, layer.modelData.opacity * 0.28)

                PathPolyline {
                    path: layer.pts.concat([Qt.point(root.width + 8, root.height), Qt.point(0, root.height)])
                }
            }

            ShapePath {
                strokeWidth: 2
                strokeColor: Qt.alpha(Colours.palette.m3primary, layer.modelData.opacity)
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: layer.pts
                }
            }
        }
    }
}
