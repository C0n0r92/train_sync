using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Timer;

class BlockDisplay extends WatchUi.View {
    var block;
    var blockIndex;
    var totalBlocks;
    var elapsedSeconds;
    var timerHandle;
    var isTimerRunning;
    var sessionManager;

    function initialize(sessionManager) {
        View.initialize();
        self.sessionManager = sessionManager;
        block = sessionManager.getCurrentBlock();
        blockIndex = sessionManager.currentBlockIndex;
        totalBlocks = sessionManager.workoutBlocks.size();
        elapsedSeconds = 0;
        isTimerRunning = false;
        timerHandle = null;
    }

    function onUpdate(dc) {
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

    function drawBlockHeader(dc) {
        var headerY = 20;
        var headerText = "Block " + (blockIndex + 1) + "/" + totalBlocks;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            dc.getWidth() / 2,
            headerY,
            Graphics.FONT_LARGE,
            headerText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw block type
        var blockType = block["type"];
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(
            dc.getWidth() / 2,
            headerY + 40,
            Graphics.FONT_MEDIUM,
            blockType.toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function drawBlockDetails(dc) {
        var detailsY = 100;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        // Display block-specific details
        var targetParams = block["target_params"];
        var detailText = formatBlockDetails(targetParams);

        var lines = detailText;
        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(
                20,
                detailsY + (i * 25),
                Graphics.FONT_SMALL,
                lines[i],
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }
    }

    function formatBlockDetails(params) {
        var details = [];

        if (params == null) {
            return ["No target params"];
        }

        // Bug suspect: Doesn't handle missing fields gracefully
        if (params["duration"] != null) {
            details.push("Duration: " + params["duration"] + "s");
        }

        if (params["distance"] != null) {
            details.push("Distance: " + params["distance"] + "km");
        }

        if (params["reps"] != null) {
            details.push("Reps: " + params["reps"]);
        }

        if (params["pace_target"] != null) {
            details.push("Pace: " + params["pace_target"] + "/km");
        }

        return details;
    }

    function drawTimer(dc) {
        var timerY = 200;
        var minutes = elapsedSeconds / 60;
        var seconds = elapsedSeconds % 60;
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

    function formatTimer(minutes, seconds) {
        var minStr = minutes.toString();
        var secStr = (seconds < 10) ? "0" + seconds.toString() : seconds.toString();
        return minStr + ":" + secStr;
    }

    function drawControls(dc) {
        var controlY = dc.getHeight() - 40;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);

        if (isTimerRunning) {
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

    function startTimer() {
        if (!isTimerRunning) {
            isTimerRunning = true;
            timerHandle = new Timer.Timer();
            timerHandle.start(method(:onTimerTick), 1000, true);
        }
    }

    function stopTimer() {
        if (isTimerRunning && timerHandle != null) {
            isTimerRunning = false;
            timerHandle.stop();
        }
    }

    function onTimerTick() {
        elapsedSeconds += 1;
        WatchUi.requestUpdate();
    }

    function nextBlock() {
        stopTimer();
        sessionManager.nextBlock();
        WatchUi.switchToView(
            new BlockDisplay(sessionManager),
            new BlockDelegate(sessionManager),
            WatchUi.SLIDE_LEFT
        );
    }

    function previousBlock() {
        stopTimer();
        sessionManager.previousBlock();
        WatchUi.switchToView(
            new BlockDisplay(sessionManager),
            new BlockDelegate(sessionManager),
            WatchUi.SLIDE_RIGHT
        );
    }
}

class BlockDelegate extends WatchUi.InputDelegate {
    var display;
    var sessionManager;

    function initialize(sessionManager) {
        InputDelegate.initialize();
        self.sessionManager = sessionManager;
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();

        // Bug suspect: Double-tap skips a block
        if (key == WatchUi.KEY_ENTER) {
            display.nextBlock();
            return true;
        }

        if (key == WatchUi.KEY_ESC) {
            display.previousBlock();
            return true;
        }

        return false;
    }

    function onTap(clickEvent) {
        // Toggle timer
        if (display.isTimerRunning) {
            display.stopTimer();
        } else {
            display.startTimer();
        }

        return true;
    }
}
