pragma Singleton

import QtQuick
import Serein.I18n
import qs.services

// Real moon phase from the date (mean synodic month, accurate to within about a day)
QtObject {
    id: root

    readonly property real synodic: 29.530588853
    // A known new moon: 2000-01-06 18:14 UTC
    readonly property real reference: Date.UTC(2000, 0, 6, 18, 14) / 86400000

    // 0 = new moon, 0.5 = full moon, back to 1 = new moon
    readonly property real phase: {
        const days = Time.date.getTime() / 86400000 - reference;
        const p = (days / synodic) % 1;
        return p < 0 ? p + 1 : p;
    }
    // Lit fraction of the disc, 0 to 1
    readonly property real illumination: (1 - Math.cos(phase * 2 * Math.PI)) / 2
    readonly property bool waxing: phase < 0.5

    readonly property string name: {
        const p = phase;
        if (p < 0.03 || p >= 0.97)
            return Tr.trCtx("New moon", "moon phase");
        if (p < 0.22)
            return Tr.trCtx("Waxing crescent", "moon phase");
        if (p < 0.28)
            return Tr.trCtx("First quarter", "moon phase");
        if (p < 0.47)
            return Tr.trCtx("Waxing gibbous", "moon phase");
        if (p < 0.53)
            return Tr.trCtx("Full moon", "moon phase");
        if (p < 0.72)
            return Tr.trCtx("Waning gibbous", "moon phase");
        if (p < 0.78)
            return Tr.trCtx("Last quarter", "moon phase");
        return Tr.trCtx("Waning crescent", "moon phase");
    }
}
