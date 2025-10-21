# 🔧 Xiaomi Recording Debug Guide

## 📱 Debug APK Location
```
build/app/outputs/flutter-apk/app-debug.apk
```

## 🐛 How to See Error Logs

### Method 1: Using Android Studio (Recommended)
1. Install the debug APK on your Xiaomi tablet
2. Connect tablet to computer via USB
3. Enable USB debugging on tablet:
   - Settings > About tablet > Tap "MIUI version" 7 times
   - Settings > Additional settings > Developer options > USB debugging (enable)
4. Open Android Studio
5. Go to **View > Tool Windows > Logcat**
6. Filter by "flutter" or look for these emoji in logs: 📁 🎵 ✅ ❌
7. Click record button and watch the logs

### Method 2: Using ADB Command Line
```bash
# Connect tablet via USB, then run:
adb logcat | grep -E "flutter|record|audio"
```

## 🔍 What to Look For in Logs

When you click the record button, you should see:
```
📁 Recording directory: /data/user/0/com.example.reverse_sing/app_flutter/...
🎵 Recording file: /data/user/0/.../recorded_1234567890.m4a
✅ Recording started successfully
```

If it fails, you'll see:
```
❌ Error starting recording: [error message here]
Stack trace: [detailed error info]
```

## 🛠️ Xiaomi-Specific Fixes

### Fix 1: Disable MIUI Optimizations
1. Settings > Additional settings > Developer options
2. Turn OFF "MIUI optimization"
3. Restart tablet
4. Reinstall app

### Fix 2: Grant All Permissions Manually
1. Settings > Apps > Manage apps > Reverse Sing
2. Enable ALL of these permissions:
   - 🎤 **Microphone** - MUST BE ON
   - 📁 **Storage** - Enable if available
   - 🔊 **Modify audio settings** - Enable if available
   - 🔋 **Battery optimization** - Set to "No restrictions"
3. Also check "Display pop-up windows" and "Display pop-up window while running in background"

### Fix 3: Reset App Permissions
1. Uninstall the app completely
2. Restart tablet
3. Install fresh
4. When it asks for permissions, grant ALL of them

### Fix 4: Check MIUI Security App
1. Open **Security** app
2. Go to **Permissions**
3. Find **Reverse Sing**
4. Enable all permissions
5. Set **Autostart** to ON

### Fix 5: Clear App Data
1. Settings > Apps > Reverse Sing
2. Clear data and cache
3. Force stop
4. Open app again

## 📋 Share This Info

When you see the error, please share:
1. The exact error message from the snackbar
2. The logs from Logcat (Method 1 or 2 above)
3. Your Android/MIUI version:
   - Settings > About tablet > Android version
   - Settings > About tablet > MIUI version

## 🎯 Quick Test Steps

1. **Uninstall old app**
2. **Install debug APK** (app-debug.apk)
3. **Connect to computer** (USB debugging on)
4. **Run logcat** (see Method 2 above)
5. **Open app and click record**
6. **Copy all the logs** that appear
7. **Send me the logs** - they will show exactly what's failing

---

**Note:** The debug APK will show detailed error messages in the app AND print logs that we can analyze to fix the exact issue!
