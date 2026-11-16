pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Serein.Config
import Serein.I18n
import qs.components
import qs.components.filedialog
import qs.components.effects
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property Item current
    property bool completed

    onSourceChanged: {
        if (!source)
            current = null;
        else
            current = imgComp.createObject(this, {
                path: source,
                sweep: current !== null && UiPrefs.wallpaperTransition !== "fade",
                kind: UiPrefs.wallpaperTransition,
                // Browsing wallpapers in the picker previews them, so keep that one quick
                duration: Wallpapers.showPreview ? 800 : 1700
            });
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                current = imgComp.createObject(this, {
                    path: source
                });
                completed = true;
            });
    }

    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: Tr.tr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: Tr.tr("Select a wallpaper")
                            filterLabel: Tr.tr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: Tr.tr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    // A new wallpaper is revealed by a shape sweeping across (a big moon, a wave front or slanted rain
    // streaks, see UiPrefs.wallpaperTransition); the very first one, or "fade", just fades in
    Component {
        id: imgComp

        Item {
            id: wrap

            required property string path
            property bool sweep
            property string kind: "moon"
            property int duration: 1700

            readonly property int status: img.status
            readonly property bool done: sweep ? reveal >= 1 : fadeAnim.finished
            property real reveal: 0

            // Moon
            readonly property real moonR: height * 0.66
            readonly property real moonX: -moonR + (width + moonR * 2 + 60) * reveal
            readonly property real moonD: moonR * 0.14
            readonly property real moonH: Math.sqrt(moonR * moonR - moonD * moonD / 4)

            // Wave front: the edge of the revealed area and the polygon behind it
            readonly property real waveX: -30 + (width + 60) * reveal
            readonly property var waveEdge: {
                const pts = [];
                const phase = reveal * 14;
                for (let y = -10; y <= height + 10; y += 8)
                    pts.push(Qt.point(waveX + 18 * Math.sin(y / 22 + phase), y));
                return pts;
            }

            // Rain: slanted bands that open one after another, each with a streak at its tip
            readonly property real slant: Math.tan(12 * Math.PI / 180)
            readonly property var rainBands: {
                const n = 16, bw = (width + 260) / n, polys = [], streaks = [];
                for (let k = 0; k < n; k++) {
                    const raw = Math.max(0, Math.min(1, reveal * 1.9 - k / n * 0.9));
                    const q = raw * raw * (3 - 2 * raw);
                    const x = k * bw - 130, y0 = -30, y1 = (height + 60) * q - 30;
                    if (q <= 0)
                        continue;
                    polys.push([Qt.point(x - slant * y0, y0), Qt.point(x + bw + 1 - slant * y0, y0), Qt.point(x + bw + 1 - slant * y1, y1), Qt.point(x - slant * y1, y1)]);
                    if (q < 1)
                        streaks.push([Qt.point(x + bw / 2 - slant * y1, y1), Qt.point(x + bw / 2 - slant * y1 - 6, y1 + 44)]);
                }
                return {
                    polys: polys,
                    streaks: streaks
                };
            }

            anchors.fill: parent
            opacity: sweep ? 1 : 0

            CachingImage {
                id: img

                anchors.fill: parent
                path: wrap.path

                layer.enabled: wrap.sweep && wrap.reveal < 1
                layer.effect: Mask {
                    maskSource: revealMask
                }

                onStatusChanged: {
                    if (status !== Image.Ready)
                        return;
                    if (wrap.sweep)
                        sweepAnim.start();
                    else
                        fadeAnim.start();
                }
            }

            // What is already revealed
            Item {
                id: revealMask

                anchors.fill: parent
                layer.enabled: true
                visible: false

                Item {
                    anchors.fill: parent
                    visible: wrap.kind === "moon"

                    Rectangle {
                        x: -40
                        width: Math.max(0, wrap.moonX + 40)
                        height: parent.height
                    }

                    Rectangle {
                        x: wrap.moonX - wrap.moonR
                        y: (parent.height - height) / 2
                        width: wrap.moonR * 2
                        height: width
                        radius: width / 2
                    }
                }

                Shape {
                    anchors.fill: parent
                    visible: wrap.kind === "wave"
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: 0
                        fillColor: "white"

                        PathPolyline {
                            path: [Qt.point(-40, -10)].concat(wrap.waveEdge, [Qt.point(-40, wrap.height + 10)])
                        }
                    }
                }

                Shape {
                    anchors.fill: parent
                    visible: wrap.kind === "rain"
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: 0
                        fillColor: "white"

                        PathMultiline {
                            paths: wrap.rainBands.polys
                        }
                    }
                }
            }

            // The bright edge of the moving shape
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                opacity: wrap.sweep && wrap.reveal > 0.02 && wrap.reveal < 0.97 ? 0.85 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }

                // Moon: a crescent on the leading side
                ShapePath {
                    strokeWidth: 0
                    fillColor: wrap.kind === "moon" ? Colours.palette.m3primary : "transparent"
                    startX: wrap.moonX - wrap.moonD / 2
                    startY: wrap.height / 2 - wrap.moonH

                    PathArc {
                        x: wrap.moonX - wrap.moonD / 2
                        y: wrap.height / 2 + wrap.moonH
                        radiusX: wrap.moonR
                        radiusY: wrap.moonR
                        direction: PathArc.Clockwise
                        useLargeArc: true
                    }

                    PathArc {
                        x: wrap.moonX - wrap.moonD / 2
                        y: wrap.height / 2 - wrap.moonH
                        radiusX: wrap.moonR
                        radiusY: wrap.moonR
                        direction: PathArc.Counterclockwise
                        useLargeArc: false
                    }
                }

                // Wave: a line of foam along the front
                ShapePath {
                    strokeWidth: wrap.kind === "wave" ? 5 : 0
                    strokeColor: Colours.palette.m3primary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: wrap.kind === "wave" ? wrap.waveEdge : []
                    }
                }

                // Rain: a short streak at the tip of every band
                ShapePath {
                    strokeWidth: wrap.kind === "rain" ? 3 : 0
                    strokeColor: Colours.palette.m3primary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathMultiline {
                        paths: wrap.kind === "rain" ? wrap.rainBands.streaks : []
                    }
                }
            }

            NumberAnimation {
                id: sweepAnim

                target: wrap
                property: "reveal"
                from: 0
                to: 1
                duration: wrap.duration * wrap.Tokens.anim.durations.scale
                easing.type: Easing.InOutCubic
            }

            Anim {
                id: fadeAnim

                property bool finished

                target: wrap
                property: "opacity"
                type: Anim.SlowEffects
                from: 0
                to: 1
                onFinished: finished = true
            }

            Timer {
                running: root.current !== wrap && root.current?.status === Image.Ready && root.current.done
                interval: 200
                onTriggered: wrap.destroy()
            }
        }
    }
}
