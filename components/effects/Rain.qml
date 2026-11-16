import QtQuick
import qs.services

// Fine slanted rain streaks falling across the item (decorative). Drops are laid out
// deterministically, so the pattern is stable; only `time` moves them.
Item {
    id: root

    property int count: 70
    property color colour: Colours.palette.m3primary
    // Degrees from vertical; drops fall down and to the left, like the serein logo
    property real angle: 12
    property real speed: 1
    property bool running: visible && opacity > 0

    // Seconds of animation time
    property real time: 0

    readonly property real tilt: Math.tan(angle * Math.PI / 180)

    // Stable pseudo-random value in [0, 1) for a drop index and a salt
    function rnd(n: int, salt: int): real {
        const v = Math.sin(n * 127.1 + salt * 311.7) * 43758.5453;
        return v - Math.floor(v);
    }

    clip: true

    FrameAnimation {
        running: root.running
        onTriggered: root.time += frameTime * root.speed
    }

    Repeater {
        model: root.count

        Rectangle {
            id: drop

            required property int index

            readonly property real depth: root.rnd(index, 1) // 0 = far/faint, 1 = near/bright
            readonly property real len: 28 + 70 * depth
            readonly property real fallSpeed: 360 + 520 * depth // px per second
            readonly property real startX: root.rnd(index, 2) * (root.width + root.height * root.tilt)
            readonly property real cycle: root.height + len * 2
            readonly property real progress: (root.rnd(index, 3) * cycle + root.time * fallSpeed) % cycle
            readonly property real centreY: progress - len
            readonly property real centreX: startX - centreY * root.tilt

            width: 1.2 + 1.6 * depth
            height: len
            radius: width / 2
            color: root.colour
            opacity: 0.16 + 0.34 * depth

            x: centreX - width / 2
            y: centreY - height / 2
            rotation: root.angle
            transformOrigin: Item.Center
            antialiasing: true
        }
    }
}
