pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Serein.Config
import Serein.I18n
import qs.components
import qs.components.effects
import qs.services
import qs.utils

// Weather tab: a night-sky scene with the sun (or moon) travelling along its arc, the next hours as a temperature
// curve and the week with temperature ranges
Item {
    id: root

    readonly property var hours: Weather.hourlyForecast.slice(0, 8)
    readonly property var days: Weather.forecast.slice(0, 7)
    readonly property real weekMin: days.length ? Math.min(...days.map(d => d.minTempC)) : 0
    readonly property real weekMax: days.length ? Math.max(...days.map(d => d.maxTempC)) : 1

    // Where the sun is on its way from sunrise to sunset (0 to 1), clamped to the ends at night
    readonly property real sunFraction: {
        if (!Weather.cc)
            return 0.5;
        const rise = new Date(Weather.cc.sunrise.replace(" ", "T")).getTime();
        const set = new Date(Weather.cc.sunset.replace(" ", "T")).getTime();
        const now = Time.date.getTime();
        return Math.max(0, Math.min(1, (now - rise) / Math.max(1, set - rise)));
    }
    readonly property bool isNight: Weather.cc ? (Time.date.getTime() < new Date(Weather.cc.sunrise.replace(" ", "T")).getTime() || Time.date.getTime() > new Date(Weather.cc.sunset.replace(" ", "T")).getTime()) : false

    implicitWidth: 920
    implicitHeight: layout.implicitHeight
    Component.onCompleted: Weather.reload()

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacing.medium

        // Scene
        StyledClippingRect {
            id: scene

            Layout.fillWidth: true
            implicitHeight: 250
            radius: Tokens.rounding.extraLarge * 1.5
            color: Colours.tPalette.m3surfaceContainer

            readonly property real edgeL: 52
            readonly property real edgeR: width - 52
            readonly property real baseY: height - 52
            readonly property real arcRise: 150
            // Quadratic arc: start, control point, end
            readonly property point p0: Qt.point(edgeL, baseY)
            readonly property point p1: Qt.point(width / 2, baseY - 2 * arcRise)
            readonly property point p2: Qt.point(edgeR, baseY)
            readonly property real t: root.sunFraction
            readonly property point sun: Qt.point((1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x, (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y)
            readonly property point mid: Qt.point((1 - t) * p0.x + t * p1.x, (1 - t) * p0.y + t * p1.y)

            Rain {
                anchors.fill: parent
                count: 60
                colour: Colours.palette.m3primary
                opacity: UiPrefs.rainVisible ? 0.55 : 0
                visible: opacity > 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                // The whole path of the day, dotted
                ShapePath {
                    strokeWidth: 3
                    strokeColor: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [1, 3.5]
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    startX: scene.p0.x
                    startY: scene.p0.y

                    PathQuad {
                        x: scene.p2.x
                        y: scene.p2.y
                        controlX: scene.p1.x
                        controlY: scene.p1.y
                    }
                }

                // What the sun has already travelled
                ShapePath {
                    strokeWidth: 3
                    strokeColor: Colours.palette.m3primary
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    startX: scene.p0.x
                    startY: scene.p0.y

                    PathQuad {
                        x: scene.sun.x
                        y: scene.sun.y
                        controlX: scene.mid.x
                        controlY: scene.mid.y
                    }
                }
            }

            Rectangle {
                x: scene.sun.x - width / 2
                y: scene.sun.y - height / 2
                width: 20
                height: 20
                radius: 10
                color: Colours.palette.m3primary
                opacity: root.isNight ? 0.55 : 1
                border.width: 4
                border.color: Qt.alpha(Colours.palette.m3primary, 0.3)
            }

            // Left: where, how warm, how it feels
            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Tokens.padding.extraLargeIncreased
                anchors.topMargin: Tokens.padding.large
                spacing: 0

                StyledText {
                    text: `${Weather.city || Tr.tr("Loading...")} · ${new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")}`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }

                StyledText {
                    animate: true
                    text: Weather.temp
                    font: Tokens.font.headline.builders.large.scale(1.8).weight(Font.Medium).build()
                }

                Row {
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        animate: true
                        text: Weather.icon
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        animate: true
                        text: Weather.description
                        font: Tokens.font.title.small
                    }
                }

                StyledText {
                    text: Tr.tr("Feels %1 · %2% humidity · %3 km/h").arg(Weather.feelsLike).arg(Weather.humidity).arg(Weather.windSpeed.toFixed(1))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }

            // Right: the moon
            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.extraLargeIncreased
                spacing: Tokens.spacing.small

                MoonDisc {
                    anchors.right: parent.right
                    implicitWidth: 56
                    implicitHeight: 56
                    illumination: Moon.illumination
                    waxing: Moon.waxing
                }

                StyledText {
                    anchors.right: parent.right
                    text: Moon.name
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }

            StyledText {
                x: Math.max(Tokens.padding.extraLargeIncreased, scene.edgeL - width / 2)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.large
                text: `${Tr.tr("Sunrise")} ${Weather.sunrise}`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }

            StyledText {
                x: Math.min(scene.width - width - Tokens.padding.extraLargeIncreased, scene.edgeR - width / 2)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Tokens.padding.large
                text: `${Tr.tr("Sunset")} ${Weather.sunset}`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }

        // Next hours as a temperature curve
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 190
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer
            visible: root.hours.length > 1

            StyledText {
                id: hoursLabel

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                text: Tr.tr("Next hours")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }

            Item {
                id: curve

                readonly property real minT: Math.min(...root.hours.map(h => h.tempC))
                readonly property real maxT: Math.max(...root.hours.map(h => h.tempC))
                readonly property real colW: width / Math.max(1, root.hours.length)

                function yFor(temp: real): real {
                    const span = Math.max(1, maxT - minT);
                    return height - 8 - (temp - minT) / span * (height - 16);
                }

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: hoursLabel.bottom
                anchors.bottom: hourRow.top
                anchors.margins: Tokens.padding.large
                anchors.topMargin: Tokens.spacing.small

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeWidth: 3
                        strokeColor: Colours.palette.m3primary
                        fillColor: "transparent"
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap

                        PathPolyline {
                            path: root.hours.map((h, i) => Qt.point(curve.colW * (i + 0.5), curve.yFor(h.tempC)))
                        }
                    }
                }

                Repeater {
                    model: root.hours

                    Rectangle {
                        required property var modelData
                        required property int index

                        x: curve.colW * (index + 0.5) - width / 2
                        y: curve.yFor(modelData.tempC) - height / 2
                        width: 10
                        height: 10
                        radius: 5
                        color: Colours.palette.m3primary
                    }
                }
            }

            Row {
                id: hourRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.large

                Repeater {
                    model: root.hours

                    Column {
                        id: hourCol

                        required property var modelData
                        required property int index

                        width: hourRow.width / Math.max(1, root.hours.length)
                        spacing: 2

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: hourCol.index === 0 ? Tr.tr("Soon") : Qt.formatTime(new Date(2000, 0, 1, hourCol.modelData.hour), Units.twelveHourClock ? "h AP" : "HH:00")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }

                        MaterialIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: hourCol.modelData.icon
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.formatTemp(hourCol.modelData.tempC, true)
                            font: Tokens.font.body.small
                        }
                    }
                }
            }
        }

        }

        // The week with temperature ranges, beside the scene and the hours
        StyledRect {
            Layout.preferredWidth: 330
            Layout.fillHeight: true
            implicitHeight: weekColumn.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer
            visible: root.days.length > 0

            Column {
                id: weekColumn

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                StyledText {
                    id: weekLabel

                    text: Tr.tr("This week")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                Repeater {
                    model: root.days

                    Row {
                        id: dayRow

                        required property var modelData
                        required property int index

                        width: weekColumn.width
                        height: Math.min(60, (weekColumn.height - weekLabel.height - weekColumn.spacing * 7) / Math.max(1, root.days.length))
                        spacing: Tokens.spacing.medium

                        StyledText {
                            width: 48
                            anchors.verticalCenter: parent.verticalCenter
                            text: dayRow.index === 0 ? Tr.trCtx("Today", "forecast column") : new Date(dayRow.modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                            font: Tokens.font.body.medium
                        }

                        MaterialIcon {
                            width: 26
                            anchors.verticalCenter: parent.verticalCenter
                            text: dayRow.modelData.icon
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            width: 34
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.formatTemp(dayRow.modelData.minTempC, true)
                            color: Colours.palette.m3onSurfaceVariant
                            horizontalAlignment: Text.AlignRight
                        }

                        Item {
                            width: parent.width - 48 - 26 - 34 * 2 - parent.spacing * 4
                            height: parent.height

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 3)

                                Rectangle {
                                    readonly property real span: Math.max(1, root.weekMax - root.weekMin)

                                    x: (dayRow.modelData.minTempC - root.weekMin) / span * parent.width
                                    width: Math.max(8, (dayRow.modelData.maxTempC - dayRow.modelData.minTempC) / span * parent.width)
                                    height: parent.height
                                    radius: 3
                                    color: Colours.palette.m3primary
                                }
                            }
                        }

                        StyledText {
                            width: 34
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.formatTemp(dayRow.modelData.maxTempC, true)
                        }
                    }
                }
            }
        }
    }
}
