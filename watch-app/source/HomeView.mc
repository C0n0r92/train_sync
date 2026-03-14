//
// ScanRx Watch App - Home View
//

import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class HomeView extends WatchUi.View {
    private var _title as String;

    public function initialize() {
        View.initialize();
        _title = "ScanRx";
    }

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw title
        dc.drawText(
            dc.getWidth() / 2,
            40,
            Graphics.FONT_LARGE,
            _title,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw status message
        var statusText = "Loading workout...";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_SMALL,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}

class HomeViewDelegate extends WatchUi.BehaviorDelegate {
    public function initialize() {
        BehaviorDelegate.initialize();
    }

    public function onSelect() as Boolean {
        return true;
    }

    public function onKey(evt as KeyEvent) as Boolean {
        return false;
    }
}
