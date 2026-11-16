import QtQuick
import Quickshell

// Phosphor-based icon fonts (see assets/icons), used when the icon style is not Material
Item {
    FontLoader {
        source: Quickshell.shellPath("assets/icons/SereinIcons.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/icons/SereinIcons-Fill.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/icons/SereinIcons-Bold.ttf")
    }
}
