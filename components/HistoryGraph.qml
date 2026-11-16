import QtQuick
import QtQuick.Shapes
import Serein.Config
import qs.components
import qs.services

// Line graph of the last `length` seconds of a 0 to 1 value, sampled once a second
Item {
    id: root

    property real value
    property int length: 60
    property color colour: Colours.palette.m3primary
    property var samples: []

    function sample(): void {
        const list = root.samples.slice(-(root.length - 1));
        list.push(isNaN(root.value) ? 0 : Math.max(0, Math.min(1, root.value)));
        root.samples = list;
    }

    Component.onCompleted: sample()

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: root.sample()
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Soft area under the line
        ShapePath {
            strokeWidth: 0
            fillColor: Qt.alpha(root.colour, 0.14)

            PathPolyline {
                path: {
                    const n = root.samples.length;
                    if (n < 2)
                        return [];
                    const pts = root.samples.map((v, i) => Qt.point(root.width * (root.length - n + i) / (root.length - 1), root.height - 3 - v * (root.height - 8)));
                    return pts.concat([Qt.point(root.width, root.height), Qt.point(pts[0].x, root.height)]);
                }
            }
        }

        ShapePath {
            strokeWidth: 2.5
            strokeColor: root.colour
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: {
                    const n = root.samples.length;
                    if (n < 2)
                        return [];
                    return root.samples.map((v, i) => Qt.point(root.width * (root.length - n + i) / (root.length - 1), root.height - 3 - v * (root.height - 8)));
                }
            }
        }
    }
}
