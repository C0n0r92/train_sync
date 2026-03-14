//
// ScanRx Watch App - Block Display View
//

import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Timer;
import Toybox.Lang;

class BlockDisplay extends WatchUi.View {
    private var _block as Dictionary or Null;
    private var _blockIndex as Number;
    private var _totalBlocks as Number;
    private var _elapsedSeconds as Number;
    private var _timerHandle as Timer.Timer or Null;
    private var _isTimerRunning as Boolean;
    private var _sessionManager as SessionManager;

    public function initialize(sessionManager as SessionManager) {
        View.initialize();
        _sessionManager = sessionManager;
        _block = sessionManager.getCurrentBlock();
        _blockIndex = sessionManager.getCurrentBlockIndex();
        _totalBlocks = sessionManager.getTotalBlocks();
        _elapsedSeconds = 0;
        _isTimerRunning = false;
        _timerHandle = null;
    }

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw block header
        drawBlockHeader(dc);

        // Draw block details
        drawBlockDetails(dc);

        // Draw timer
        drawTimer(dc);

        // Draw control prompts
        drawControls(dc);
    }

    private function drawBlockHeader(dc as Dc) as Void {
        var headerY = 20;
        var headerText = "Block " + (_blockIndex + 1) + "/" + _totalBlocks;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            dc.getWidth() / 2,
            headerY,
            Graphics.FONT_LARGE,
            headerText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw block type
        if (_block != null) {
            var block = _block as Dictionary;
            var blockType = "UNKNOWN";
            if (block.hasKey("type") && block["type"] != null) {
                blockType = (block["type"] as String).toUpper();
            }
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.drawText(
                dc.getWidth() / 2,
                headerY + 40,
                Graphics.FONT_MEDIUM,
                blockType,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    private function drawBlockDetails(dc as Dc) as Void {
        var detailsY = 100;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        if (_block == null) {
            dc.drawText(20, detailsY, Graphics.FONT_SMALL, "No block data", Graphics.TEXT_JUSTIFY_LEFT);
            return;
        }

        var block = _block as Dictionary;

        // Display block-specific details
        if (block.hasKey("target_params") && block["target_params"] != null) {
            var targetParams = block["target_params"] as Dictionary;
            var lines = formatBlockDetails(targetParams);

            for (var i = 0; i < lines.size(); i++) {
                dc.drawText(
                    20,
                    detailsY + (i * 25),
                    Graphics.FONT_SMALL,
                    lines[i] as String,
                    Graphics.TEXT_JUSTIFY_LEFT
                );
            }
        } else {
            dc.drawText(20, detailsY, Graphics.FONT_SMALL, "No target params", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function formatBlockDetails(params as Dictionary) as Array<String> {
        var details = [] as Array<String>;

        if (params.hasKey("duration") && params["duration"] != null) {
            details.add("Duration: " + params["duration"] + "s");
        }

        if (params.hasKey("distance") && params["distance"] != null) {
            details.add("Distance: " + params["distance"] + "km");
        }

        if (params.hasKey("reps") && params["reps"] != null) {
            details.add("Reps: " + params["reps"]);
        }

        if (params.hasKey("pace_target") && params["pace_target"] != null) {
            details.add("Pace: " + params["pace_target"] + "/km");
        }

        if (details.size() == 0) {
            details.add("No target params");
        }

        return details;
    }

    private function drawTimer(dc as Dc) as Void {
        var timerY = 200;
        var minutes = _elapsedSeconds / 60;
        var seconds = _elapsedSeconds % 60;
        var timerText = formatTimer(minutes, seconds);

        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        dc.drawText(
            dc.getWidth() / 2,
            timerY,
            Graphics.FONT_LARGE,
            timerText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    private function formatTimer(minutes as Number, seconds as Number) as String {
        var minStr = minutes.toString();
        var secStr = (seconds < 10) ? "0" + seconds.toString() : seconds.toString();
        return minStr + ":" + secStr;
    }

    private function drawControls(dc as Dc) as Void {
        var controlY = dc.getHeight() - 40;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);

        if (_isTimerRunning) {
            dc.drawText(
                dc.getWidth() / 2,
                controlY,
                Graphics.FONT_SMALL,
                "TAP TO STOP",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else {
            dc.drawText(
                dc.getWidth() / 2,
                controlY,
                Graphics.FONT_SMALL,
                "TAP TO CONTINUE",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    public function startTimer() as Void {
        if (!_isTimerRunning) {
            _isTimerRunning = true;
            _timerHandle = new Timer.Timer();
            _timerHandle.start(method(:onTimerTick), 1000, true);
        }
    }

    public function stopTimer() as Void {
        if (_isTimerRunning && _timerHandle != null) {
            _isTimerRunning = false;
            _timerHandle.stop();
        }
    }

    public function onTimerTick() as Void {
        _elapsedSeconds += 1;
        WatchUi.requestUpdate();
    }

    public function isTimerRunning() as Boolean {
        return _isTimerRunning;
    }

    public function getSessionManager() as SessionManager {
        return _sessionManager;
    }
}

class BlockDelegate extends WatchUi.BehaviorDelegate {
    private var _display as BlockDisplay;

    public function initialize(display as BlockDisplay) {
        BehaviorDelegate.initialize();
        _display = display;
    }

    public function onKey(evt as KeyEvent) as Boolean {
        var key = evt.getKey();

        if (key == WatchUi.KEY_ENTER) {
            nextBlock();
            return true;
        }

        if (key == WatchUi.KEY_ESC) {
            previousBlock();
            return true;
        }

        return false;
    }

    public function onTap(evt as ClickEvent) as Boolean {
        // Toggle timer
        if (_display.isTimerRunning()) {
            _display.stopTimer();
        } else {
            _display.startTimer();
        }

        return true;
    }

    private function nextBlock() as Void {
        _display.stopTimer();
        var sessionManager = _display.getSessionManager();
        sessionManager.nextBlock();
        var newDisplay = new BlockDisplay(sessionManager);
        WatchUi.switchToView(
            newDisplay,
            new BlockDelegate(newDisplay),
            WatchUi.SLIDE_LEFT
        );
    }

    private function previousBlock() as Void {
        _display.stopTimer();
        var sessionManager = _display.getSessionManager();
        sessionManager.previousBlock();
        var newDisplay = new BlockDisplay(sessionManager);
        WatchUi.switchToView(
            newDisplay,
            new BlockDelegate(newDisplay),
            WatchUi.SLIDE_RIGHT
        );
    }
}
