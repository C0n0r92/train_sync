//
// ScanRx Watch App - Session Manager
//

import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

class SessionManager {
    private var _deviceToken as String or Null;
    private var _currentSession as Dictionary or Null;
    private var _workoutBlocks as Array or Null;
    private var _currentBlockIndex as Number;
    private var _isPolling as Boolean;
    private var _lastPollTime as Number;
    private var _notify as Method or Null;

    public function initialize() {
        _deviceToken = StorageManager.loadDeviceToken();
        _currentSession = null;
        _workoutBlocks = null;
        _currentBlockIndex = 0;
        _isPolling = false;
        _lastPollTime = 0;
        _notify = null;

        // Check if token is expired
        if (_deviceToken != null && StorageManager.isTokenExpired()) {
            log("Device token expired, showing reconnect screen");
            _deviceToken = null;
        }
    }

    public function setNotifyCallback(callback as Method) as Void {
        _notify = callback;
    }

    // Poll API for queued workout
    public function pollForWorkout() as Void {
        if (!_isPolling && _deviceToken != null) {
            _isPolling = true;
            var url = $.API_URL + "/sessions/current";
            var options = {
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :headers => {
                    "X-Device-Token" => _deviceToken
                }
            };

            Communications.makeWebRequest(
                url,
                null,
                options,
                method(:onSessionResponse)
            );
        }
    }

    public function onSessionResponse(responseCode as Number, responseData as Dictionary or String or Null) as Void {
        _isPolling = false;
        _lastPollTime = Time.now().value();

        if (responseCode == 200 && responseData != null && responseData instanceof Dictionary) {
            log("Got workout data");
            var data = responseData as Dictionary;
            // Parse blocks from response
            if (data.hasKey("workout") && data["workout"] != null) {
                var workout = data["workout"] as Dictionary;
                if (workout.hasKey("blocks")) {
                    _workoutBlocks = workout["blocks"] as Array;
                    _currentSession = data;
                    _currentBlockIndex = 0;
                    // Notify UI to show workout
                    if (_notify != null) {
                        _notify.invoke(data);
                    }
                }
            } else {
                log("No workout queued");
            }
        } else if (responseCode == 401) {
            log("Token expired or unauthorized");
            _deviceToken = null;
        } else {
            log("Failed to fetch workout: " + responseCode);
        }
    }

    public function nextBlock() as Void {
        if (_workoutBlocks != null) {
            var blocks = _workoutBlocks as Array;
            if (_currentBlockIndex < blocks.size() - 1) {
                _currentBlockIndex++;
            } else if (_currentBlockIndex >= blocks.size() - 1) {
                log("Workout complete");
                showCompletionScreen();
            }
        }
    }

    public function previousBlock() as Void {
        if (_currentBlockIndex > 0) {
            _currentBlockIndex--;
        }
    }

    public function getCurrentBlock() as Dictionary or Null {
        if (_workoutBlocks != null) {
            var blocks = _workoutBlocks as Array;
            if (_currentBlockIndex < blocks.size()) {
                return blocks[_currentBlockIndex] as Dictionary;
            }
        }
        return null;
    }

    public function getCurrentBlockIndex() as Number {
        return _currentBlockIndex;
    }

    public function getTotalBlocks() as Number {
        if (_workoutBlocks != null) {
            return (_workoutBlocks as Array).size();
        }
        return 0;
    }

    public function submitResults(blockResults as Array) as Void {
        if (_currentSession == null || _deviceToken == null) {
            log("Cannot submit: no session or token");
            return;
        }

        var session = _currentSession as Dictionary;
        var sessionId = session["id"];
        var url = $.API_URL + "/sessions/" + sessionId + "/results";
        var body = {
            "block_results" => blockResults
        };
        var options = {
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => {
                "X-Device-Token" => _deviceToken,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            }
        };

        Communications.makeWebRequest(
            url,
            body,
            options,
            method(:onResultsResponse)
        );
    }

    public function onResultsResponse(responseCode as Number, responseData as Dictionary or String or Null) as Void {
        if (responseCode == 201) {
            System.println("[ScanRx] Results submitted successfully");
        } else {
            System.println("[ScanRx] Failed to submit results: " + responseCode);
        }
    }

    private function showCompletionScreen() as Void {
        log("Workout completed - showing completion screen");
    }

    private function log(msg as String) as Void {
        System.println("[ScanRx] " + msg);
    }
}
