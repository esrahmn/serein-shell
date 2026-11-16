pragma ComponentBehavior: Bound

import QtQuick
import Serein.Config
import qs.components
import qs.services

// This week at a glance: today sits in a cookie-ish highlight
Item {
    id: root

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    readonly property var days: {
        const now = new Date(Time.date);
        const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
        return Array.from({
            length: 7
        }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
    }
    readonly property int todayDay: Time.date.getDate()

    StyledText {
        id: header

        text: Time.format("MMMM yyyy")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.medium
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: header.implicitHeight / 2

        Repeater {
            model: root.days

            Item {
                id: cell

                required property date modelData
                readonly property bool today: modelData.getDate() === root.todayDay && modelData.getMonth() === Time.date.getMonth()

                width: parent.width / 7
                height: 64

                Column {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.locale().dayName(cell.modelData.getDay(), Locale.ShortFormat).slice(0, 2)
                        color: cell.today ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }

                    // Today sits in a rounded square around its date; the other days stay quiet
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32
                        height: 32

                        Rectangle {
                            anchors.fill: parent
                            radius: width * 0.4
                            color: Colours.palette.m3primary
                            opacity: cell.today ? 1 : 0

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: cell.modelData.getDate()
                            color: cell.today ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            font: Tokens.font.title.small
                        }
                    }
                }
            }
        }
    }
}
