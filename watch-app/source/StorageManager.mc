//
// ScanRx Watch App - Storage Manager
//

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

class StorageManager {
    private static const STORAGE_KEY_TOKEN = "device_token";
    private static const STORAGE_KEY_EXPIRES = "token_expires_at";
    private static const STORAGE_KEY_CACHED_WORKOUT = "cached_workout";
    private static const STORAGE_KEY_DEVICE_ID = "device_id";

    public function initialize() {
    }

    public static function saveDeviceToken(token as String, expiresAt as Number) as Void {
        Storage.setValue(STORAGE_KEY_TOKEN, token);
        Storage.setValue(STORAGE_KEY_EXPIRES, expiresAt);
        System.println("[ScanRx] Token saved, expires: " + expiresAt);
    }

    public static function loadDeviceToken() as String or Null {
        var token = Storage.getValue(STORAGE_KEY_TOKEN);
        if (token == null) {
            System.println("[ScanRx] No device token found");
            return null;
        }

        // Check expiry
        var expiresAt = Storage.getValue(STORAGE_KEY_EXPIRES);
        if (expiresAt != null && expiresAt instanceof Number) {
            var now = Time.now().value();
            if ((expiresAt as Number) < now) {
                System.println("[ScanRx] Device token expired");
                return null;
            }
        }

        return token as String;
    }

    public static function deleteDeviceToken() as Void {
        Storage.deleteValue(STORAGE_KEY_TOKEN);
        Storage.deleteValue(STORAGE_KEY_EXPIRES);
        System.println("[ScanRx] Device token deleted");
    }

    public static function isTokenExpired() as Boolean {
        var expiresAt = Storage.getValue(STORAGE_KEY_EXPIRES);
        if (expiresAt == null) {
            return true;
        }

        if (expiresAt instanceof Number) {
            var now = Time.now().value();
            return (expiresAt as Number) < now;
        }

        return true;
    }

    public static function cacheWorkout(workoutJson as Dictionary) as Void {
        try {
            Storage.setValue(STORAGE_KEY_CACHED_WORKOUT, workoutJson);
            System.println("[ScanRx] Workout cached");
        } catch (ex) {
            System.println("[ScanRx] Failed to cache workout");
        }
    }

    public static function getCachedWorkout() as Dictionary or Null {
        var cached = Storage.getValue(STORAGE_KEY_CACHED_WORKOUT);
        if (cached instanceof Dictionary) {
            return cached as Dictionary;
        }
        return null;
    }

    public static function saveDeviceId(deviceId as String) as Void {
        Storage.setValue(STORAGE_KEY_DEVICE_ID, deviceId);
    }

    public static function getDeviceId() as String or Null {
        var id = Storage.getValue(STORAGE_KEY_DEVICE_ID);
        if (id instanceof String) {
            return id as String;
        }
        return null;
    }
}
