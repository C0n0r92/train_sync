using Toybox.Communications;
using Toybox.System;

class SessionManager {
    var deviceToken;
    var currentSession;
    var workoutBlocks;
    var currentBlockIndex;
    var isPolling;
    var lastPollTime;

    function initialize() {
        deviceToken = StorageManager.loadDeviceToken();
        currentSession = null;
        workoutBlocks = null;
        currentBlockIndex = 0;
        isPolling = false;
        lastPollTime = 0;

        // Check if token is expired
        if (deviceToken != null && StorageManager.isTokenExpired()) {
            log("Device token expired, showing reconnect screen");
            // TODO: Show reconnect view
            deviceToken = null;
        }
    }

    // Poll API for queued workout
    function pollForWorkout() {
        if (!isPolling && deviceToken != null) {
            isPolling = true;
            var url = API_URL + "/sessions/current";
            var options = {
                "method" => Communications.HTTP_REQUEST_METHOD_GET,
                "headers" => {
                    "X-Device-Token" => deviceToken
                }
            };

            Communications.makeWebRequest(
                url,
                null,
                options,
                new SessionResponseHandler(self)
            );
        }
    }

    function onSessionResponse(responseCode, responseData) {
        isPolling = false;
        lastPollTime = System.getSystemTime();

        if (responseCode == 200 && responseData != null) {
            log("Got workout data");
            // Parse blocks from response
            if (responseData["workout"] != null) {
                workoutBlocks = responseData["workout"]["blocks"];
                currentSession = responseData;
                currentBlockIndex = 0;
                // TODO: Notify UI to show workout
            } else {
                log("No workout queued");
            }
        } else if (responseCode == 401) {
            log("Token expired or unauthorized");
            deviceToken = null;
            // TODO: Show reconnect screen
        } else {
            log("Failed to fetch workout: " + responseCode);
        }
    }

    function nextBlock() {
        if (workoutBlocks != null && currentBlockIndex < workoutBlocks.size() - 1) {
            currentBlockIndex++;
        } else if (currentBlockIndex >= workoutBlocks.size() - 1) {
            log("Workout complete");
            showCompletionScreen();
        }
    }

    function previousBlock() {
        if (currentBlockIndex > 0) {
            currentBlockIndex--;
        }
    }

    function getCurrentBlock() {
        if (workoutBlocks != null && currentBlockIndex < workoutBlocks.size()) {
            return workoutBlocks[currentBlockIndex];
        }
        return null;
    }

    function submitResults(blockResults) {
        if (currentSession == null || deviceToken == null) {
            log("Cannot submit: no session or token");
            return;
        }

        var sessionId = currentSession["id"];
        var url = API_URL + "/sessions/" + sessionId + "/results";
        var body = {
            "block_results" => blockResults
        };
        var options = {
            "method" => Communications.HTTP_REQUEST_METHOD_POST,
            "headers" => {
                "X-Device-Token" => deviceToken
            },
            "requestBody" => body
        };

        Communications.makeWebRequest(
            url,
            body,
            options,
            new ResultsResponseHandler()
        );
    }

    function showCompletionScreen() {
        log("Workout completed!");
        // TODO: Show completion screen
    }

    function log(msg) {
        System.println("[ScanRx] " + msg);
    }
}

class SessionResponseHandler extends Communications.ResponseListener {
    var sessionManager;

    function initialize(manager) {
        sessionManager = manager;
    }

    function onResponse(responseCode, responseData) {
        sessionManager.onSessionResponse(responseCode, responseData);
    }

    function onError(error) {
        System.println("[ScanRx] Network error: " + error);
    }
}

class ResultsResponseHandler extends Communications.ResponseListener {
    function onResponse(responseCode, responseData) {
        if (responseCode == 201) {
            System.println("[ScanRx] Results submitted successfully");
        } else {
            System.println("[ScanRx] Failed to submit results: " + responseCode);
        }
    }

    function onError(error) {
        System.println("[ScanRx] Error submitting results: " + error);
    }
}
