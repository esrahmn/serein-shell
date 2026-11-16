pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Serein

// Serein's own version, read from the VERSION file at the repo root, the serein-plugin version it runs on,
// and the caelestia release the project was forked from. The git revision is shown when the config lives
// in a git checkout.
Singleton {
    id: root

    readonly property string serein: versionFile.text().trim() || "dev"
    // Version of serein-plugin (the native Serein.* QML modules)
    readonly property string plugin: CUtils.version
    // The caelestia release this project was forked from
    readonly property string caelestiaBase: "2.5.0"
    property string revision

    FileView {
        id: versionFile

        path: Quickshell.shellPath("VERSION")
        blockLoading: true
        printErrors: false
    }

    // e.g. "a1b2c3d" or "a1b2c3d-dirty"; empty when not a git checkout or git is missing
    Process {
        running: true
        command: ["sh", "-c", `git -C "${Quickshell.shellDir}" describe --always --dirty 2>/dev/null`]
        stdout: StdioCollector {
            onStreamFinished: root.revision = text.trim()
        }
    }
}
