import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Dashboard state
    property int dashboardTab
    // True while a window thumbnail is being pressed/dragged in the dashboard overview: the dashboard
    // must not treat that drag as a swipe (flick between tabs, or close itself)
    property bool dashboardDragLock
    property date dashboardDate: new Date()
}
