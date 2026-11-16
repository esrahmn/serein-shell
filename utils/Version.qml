pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia

// Serein's own version, read from the VERSION file at the repo root, plus the caelestia release it is
// based on (the plugin version). The git revision is shown when the config lives in a git checkout.
Singleton {
    id: root

    readonly property string serein: versionFile.text().trim() || "dev"
    // Version of the caelestia shell/plugin this fork is built on
    readonly property string caelestiaBase: CUtils.version
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
