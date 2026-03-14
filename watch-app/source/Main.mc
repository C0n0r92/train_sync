using Toybox.Application;
using Toybox.WatchUi;

// API configuration - update for your server
var API_URL = "http://localhost:3000/api";

class ScanRxApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        // Load stored device token from storage
        // Check for queued workout
        // Initialize SessionManager to poll for workouts
    }

    function onStop(state) {
        // Save session state
        // Stop polling
    }

    function getInitialView() {
        // Show HomeView (list of blocks) if workout queued
        // Or show ConnectView (pairing) if no device token
        return [ new HomeView(), new HomeViewDelegate() ];
    }
}

// Global helper to access app instance
function getApp() {
    return Application.getApp();
}
