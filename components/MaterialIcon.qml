import QtQuick
import Serein.Config
import qs.services
import qs.utils

// Icon by Material Symbols name. With the Phosphor style the same names resolve to Phosphor glyphs:
// assets/icons/SereinIcons*.ttf carry a ligature for every Material name (regular, and a fill variant).
StyledText {
    property real fill
    property int grade: Colours.light ? 0 : -25
    property font fontStyle: Tokens.font.icon.small

    font: {
        const f = Tokens.font.icon.size(fontStyle.pointSize).weight(fontStyle.weight).vaxes(fontStyle.variableAxes).fill(fill.toFixed(1)).grade(grade).build();
        if (UiPrefs.iconStyle === "phosphor") {
            f.family = fill > 0.5 ? (Icons.isSolidIcon(text) ? "SereinIcons Fill" : "SereinIcons Bold") : "SereinIcons";
            f.variableAxes = {};
        }
        return f;
    }
}
