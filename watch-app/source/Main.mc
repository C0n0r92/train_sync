//
// ScanRx Watch App - Coach-to-Athlete Workout Distribution
// Copyright 2024
//

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// API configuration - update for your server
var API_URL = "http://localhost:3000/api";

class ScanRxApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
        // Load stored device token from storage
        // Check for queued workout
        // Initialize SessionManager to poll for workouts
        System.println("[ScanRx] App started");
    }

    public function onStop(state as Dictionary?) as Void {
        // Save session state
        // Stop polling
        System.println("[ScanRx] App stopped");
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        // Show HomeView (list of blocks) if workout queued
        // Or show ConnectView (pairing) if no device token
        return [new $.HomeView(), new $.HomeViewDelegate()];
    }
}

// Global helper to access app instance
function getApp() as ScanRxApp {
    return Application.getApp() as ScanRxApp;
}
