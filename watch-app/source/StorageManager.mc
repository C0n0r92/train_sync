using Toybox.Application;
using Toybox.System;

class StorageManager {
    static var STORAGE_KEY_TOKEN = "device_token";
    static var STORAGE_KEY_EXPIRES = "token_expires_at";
    static var STORAGE_KEY_CACHED_WORKOUT = "cached_workout";
    static var STORAGE_KEY_DEVICE_ID = "device_id";

    function initialize() {
    }

    static function saveDeviceToken(token, expiresAt) {
        var app = Application.getApp();
        var properties = app.getProperties();

        properties.put(STORAGE_KEY_TOKEN, token);
        properties.put(STORAGE_KEY_EXPIRES, expiresAt);

        System.println("[ScanRx] Token saved, expires: " + expiresAt);
    }

    static function loadDeviceToken() {
        var app = Application.getApp();
        var properties = app.getProperties();

        var token = properties.get(STORAGE_KEY_TOKEN);
        if (token == null) {
            System.println("[ScanRx] No device token found");
            return null;
        }

        // Check expiry
        var expiresAt = properties.get(STORAGE_KEY_EXPIRES);
        if (expiresAt != null && expiresAt < System.getSystemTime()) {
            System.println("[ScanRx] Device token expired");
            return null;
        }

        return token;
    }

    static function deleteDeviceToken() {
        var app = Application.getApp();
        var properties = app.getProperties();

        properties.remove(STORAGE_KEY_TOKEN);
        properties.remove(STORAGE_KEY_EXPIRES);
        System.println("[ScanRx] Device token deleted");
    }

    static function isTokenExpired() {
        var app = Application.getApp();
        var properties = app.getProperties();

        var expiresAt = properties.get(STORAGE_KEY_EXPIRES);
        if (expiresAt == null) {
            return true;
        }

        return expiresAt < System.getSystemTime();
    }

    static function cacheWorkout(workoutJson) {
        var app = Application.getApp();
        var properties = app.getProperties();

        try {
            properties.put(STORAGE_KEY_CACHED_WORKOUT, workoutJson);
            System.println("[ScanRx] Workout cached");
        } catch (ex) {
            System.println("[ScanRx] Failed to cache workout: " + ex.getErrorMessage());
        }
    }

    static function getCachedWorkout() {
        var app = Application.getApp();
        var properties = app.getProperties();

        return properties.get(STORAGE_KEY_CACHED_WORKOUT);
    }

    static function saveDeviceId(deviceId) {
        var app = Application.getApp();
        var properties = app.getProperties();

        properties.put(STORAGE_KEY_DEVICE_ID, deviceId);
    }

    static function getDeviceId() {
        var app = Application.getApp();
        var properties = app.getProperties();

        return properties.get(STORAGE_KEY_DEVICE_ID);
    }
}
