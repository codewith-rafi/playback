# APK Installation Guide for Xiaomi Tablet

## ✅ Permissions Configured

Your APK is now properly configured with all necessary permissions:

### Android Permissions (AndroidManifest.xml)
- ✅ **RECORD_AUDIO** - Required for recording audio with microphone
- ✅ **WRITE_EXTERNAL_STORAGE** - For saving audio files (Android 12 and below)
- ✅ **READ_EXTERNAL_STORAGE** - For accessing audio files (Android 12 and below)

### iOS Permissions (Info.plist)
- ✅ **NSMicrophoneUsageDescription** - Already configured

## 📱 APK File Location

Your release APK is ready at:
```
/Users/rafiahmed/Documents/reverse_sing/build/app/outputs/flutter-apk/app-release.apk
```

**Size:** 120.6 MB

## 🚀 Installation Steps for Xiaomi Tablet

### Method 1: Direct Transfer (Recommended)
1. Connect your Xiaomi tablet to your Mac via USB
2. Enable **File Transfer** mode on the tablet
3. Copy the APK file to your tablet's **Downloads** folder
4. On your tablet:
   - Open **File Manager**
   - Navigate to **Downloads**
   - Tap on `app-release.apk`
   - If prompted, enable **"Install from Unknown Sources"**
   - Tap **Install**

### Method 2: Via Google Drive/Email
1. Upload `app-release.apk` to Google Drive or send via email
2. On your Xiaomi tablet, download the APK
3. Open the downloaded file and install

### Method 3: Using ADB (Developer Method)
```bash
# Connect tablet via USB
# Enable USB Debugging on tablet (Settings > About > Tap "MIUI Version" 7 times > Developer Options > USB Debugging)

# Install using ADB
adb install /Users/rafiahmed/Documents/reverse_sing/build/app/outputs/flutter-apk/app-release.apk
```

## ⚙️ Xiaomi-Specific Settings

### MIUI Permissions
After installation, you may need to manually grant permissions:

1. Go to **Settings** > **Apps** > **Manage apps**
2. Find **reverse_sing**
3. Tap on **Permissions**
4. Enable:
   - ✅ **Microphone**
   - ✅ **Storage** (if prompted)

### MIUI Battery Optimization (Important!)
MIUI aggressively kills background apps. To prevent issues:

1. Go to **Settings** > **Apps** > **Manage apps**
2. Find **reverse_sing**
3. Tap on **Battery saver**
4. Select **No restrictions**
5. Enable **Autostart**

## 🧪 Testing Checklist

After installation, test the following:

### ✅ Recording
- [ ] Tap "START RECORDING" button
- [ ] Check if microphone permission is requested (first time only)
- [ ] Verify recording animation pulses (red glow)
- [ ] Verify timer is counting
- [ ] Record for 5-10 seconds
- [ ] Tap "STOP RECORDING"

### ✅ Original Playback
- [ ] Tap "PLAY ORIGINAL" button
- [ ] Verify playback animation pulses (orange glow)
- [ ] Verify progress bar moves
- [ ] Verify you hear your recording
- [ ] Animation should stop when playback completes

### ✅ Reversed Playback
- [ ] Tap "PLAY REVERSED" button
- [ ] Verify playback animation pulses (purple glow)
- [ ] Verify progress bar moves
- [ ] Verify you hear reversed audio
- [ ] Animation should stop when playback completes

## 🐛 Common Issues on Xiaomi Devices

### Issue: App crashes on recording
**Solution:** Grant microphone permission manually in Settings

### Issue: No sound during playback
**Solution:** 
- Check volume is not muted
- Check Do Not Disturb is off
- Grant storage permissions

### Issue: App closes automatically
**Solution:** Disable battery optimization and enable autostart

### Issue: Permission denied
**Solution:** 
1. Go to Settings > Apps > reverse_sing > Permissions
2. Manually enable Microphone permission
3. Restart the app

## 📊 App Information

- **Package Name:** com.example.reverse_sing
- **App Name:** reverse_sing
- **Version:** 1.0.0
- **Size:** 120.6 MB
- **Min Android Version:** Android 5.0+ (API 21+)
- **Target Android Version:** Latest

## 🔒 Security Note

The APK is signed with debug keys. For production/Play Store release, you'll need to:
1. Create a release keystore
2. Configure signing in `android/app/build.gradle.kts`
3. Rebuild with proper signing

---

## ✨ Ready to Test!

Your APK is fully configured and ready to be installed on your Xiaomi tablet. All permissions are properly set, and the app should work without issues!
