using Toybox.WatchUi;
using Toybox.Graphics;

class HomeView extends WatchUi.View {
    var title;

    function initialize() {
        View.initialize();
        title = "ScanRx";
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw title
        dc.drawText(
            dc.getWidth() / 2,
            40,
            Graphics.FONT_LARGE,
            title,
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

class HomeViewDelegate extends WatchUi.InputDelegate {
    function initialize() {
        InputDelegate.initialize();
    }

    function onTap(clickEvent) {
        return true;
    }

    function onKey(keyEvent) {
        return false;
    }
}
