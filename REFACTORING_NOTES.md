# Refactored Code Structure

## Overview
The app has been refactored to separate UI widgets into individual files for better organization and maintainability.

## File Structure

```
lib/
├── main.dart                    # Main app logic and state management
└── widgets/
    ├── recording_card.dart      # Recording UI widget with pulse animation
    └── playback_card.dart       # Reusable playback card widget
```

## Changes Made

### 1. **Created `/lib/widgets/recording_card.dart`**
   - Displays the recording interface with:
     - Pulsing animation when recording
     - Real-time timer display
     - Start/Stop recording button
     - Dynamic gradient background (blue/cyan when idle, red/pink when recording)

### 2. **Created `/lib/widgets/playback_card.dart`**
   - Reusable widget for both Original and Reversed audio playback
   - Features:
     - **Pulse animation support** (fixes the animation issue!)
     - Progress bar during playback
     - Customizable colors and icons
     - Disabled state management

### 3. **Updated `/lib/main.dart`**
   - Added separate AnimationControllers for each playback card:
     - `_pulseController` - for recording animation
     - `_originalPulseController` - for original audio playback animation
     - `_reversePulseController` - for reversed audio playback animation
   
   - Animation lifecycle:
     - Starts when playback begins
     - Stops and resets when playback ends
   
   - Removed old widget build methods (~500 lines of duplicated code)
   - Now uses the new widget components

## Animation Fix

### The Problem
The original and reversed audio cards didn't animate because they shared the same animation controller that was always running.

### The Solution
Each playback card now has its own `AnimationController` that:
1. Only starts when that specific card begins playing
2. Stops and resets when playback completes
3. Creates the pulsing glow effect independently

### Code Example
```dart
// Start animation when playing
_originalPulseController.repeat(reverse: true);

// Stop animation when done
_originalPulseController.stop();
_originalPulseController.reset();
```

## Benefits

1. **Cleaner Code**: Main file reduced from ~870 lines to ~355 lines
2. **Reusability**: PlaybackCard can be used for any audio playback
3. **Maintainability**: Easy to find and modify specific UI components
4. **Fixed Animations**: Each card animates independently when active
5. **Better Organization**: Widget files are self-contained with their own logic

## Usage

### RecordingCard
```dart
RecordingCard(
  recording: _recording,
  duration: _duration,
  pulseAnimation: _pulseController,
  onStartRecording: _startRecording,
  onStopRecording: _stopRecording,
  isDisabled: _playingOriginal || _playingReverse,
)
```

### PlaybackCard
```dart
PlaybackCard(
  title: 'Original Audio',
  emoji: '🎧 ',
  isPlaying: _playingOriginal,
  hasFile: _filePath != null,
  playbackProgress: _playbackProgress,
  onPlay: _playOriginal,
  isDisabled: _recording,
  primaryColor: Colors.orange,
  secondaryColor: Colors.amber,
  tertiaryColor: Colors.yellow,
  icon: Icons.headphones_rounded,
  pulseAnimation: _originalPulseController,
)
```

## Testing

To verify the animations work:
1. Start recording → Recording card should pulse
2. Stop recording → Recording animation should stop
3. Play original audio → Original card should pulse
4. Play reversed audio → Reversed card should pulse

Each animation should be independent and only active during its specific operation.
