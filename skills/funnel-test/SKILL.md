---
name: funnel-test
description: "This skill should be used when the user asks to 'test a funnel', 'test flow', 'test-funnel', 'run funnel test', 'test analytics events', 'test user journey', or discusses testing a sequence of analytics events on a device/emulator. Also triggers on '/test-funnel' and '/list-events'."
version: 1.0.0
license: MIT
---

# Flutter Funnel Test Agent

You are an AI agent that tests Flutter app funnels on real devices. The user gives you analytics event names in chat and you handle everything — generate tests, run on device, record the screen, write a report.

## What You Do

1. **Parse** the user's input to extract funnel name + event sequence
2. **Discover** the app's analytics events by reading its source code
3. **Map** each event to the UI action that triggers it
4. **Generate** YAML funnel definition + Dart test files
5. **Start** screen recording (iOS Simulator or Android Emulator)
6. **Run** Flutter integration test on the device
7. **Stop** recording and write a report
8. **Report** back with video path + pass/fail

## Input Formats

The user types any of these:

```
test checkout: cart_view -> checkout_start -> payment_success
test signup: signup_screen_view -> email_entered -> signup_success
test onboarding: welcome_view -> step1_complete -> step2_complete
list events
```

## Step 1: Check Prerequisites

### Package installed?

Check if `flutter_funnel_test` is in `pubspec.yaml`:

```bash
grep -q "flutter_funnel_test" pubspec.yaml
```

If NOT found, add it:

```bash
# Add to dev_dependencies in pubspec.yaml
```

Add these lines under `dev_dependencies:`:
```yaml
  integration_test:
    sdk: flutter
  flutter_funnel_test:
    git:
      url: https://github.com/gp-juit/flutter_funnel_test.git
```

Then run `flutter pub get`.

### Analytics wired?

Search for `TestableAnalytics` in the app's analytics service:

```bash
grep -r "TestableAnalytics" lib/ --include="*.dart"
```

If NOT found, find the analytics service:

```bash
grep -rl "trackEvent\|track(" lib/ --include="*.dart" | head -5
```

Read that file and add the 3-line hook:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';
```

Inside the `trackEvent` / `track` method, add before the real SDK call:

```dart
if (TestableAnalytics.isEnabled) {
  TestableAnalytics.capture(eventName, properties);
}
```

### test_app.dart exists?

Check if `integration_test/test_app.dart` exists. If not, create it by:

1. Read the app's `lib/main.dart` or equivalent entry point
2. Create a test version that:
   - Calls `TestableAnalytics.enable()`
   - Initializes required services (Firebase, LocalStorage, etc.) with try/catch
   - Returns the root widget (MaterialApp/GetMaterialApp/etc.)
   - Exports a `createTestApp({String? initialRoute})` function

### Device running?

```bash
flutter devices 2>&1 | grep "•"
```

If no device, tell the user:
- iOS: `open -a Simulator`
- Android: `flutter emulators --launch <id>`

## Step 2: Discover Events (for "list events")

If the user says "list events":

```bash
grep -rl "enum.*Event\|MixpanelEvent\|AnalyticsEvent" lib/ --include="*.dart"
```

Read the file, extract all event name strings, group by category, print them.

## Step 3: Map Events to UI Actions

For each event in the user's sequence, search where it fires:

```bash
grep -rn "EVENT_NAME" lib/ --include="*.dart"
```

From the file + line, determine:
- Which **screen** the user must be on (look at the file path and class)
- What **UI action** triggers it
- What **target** widget to interact with

### Action Types

| action | target | What it does |
|--------|--------|-------------|
| `tap_nav` | "Label" | Tap bottom navigation item |
| `tap_button` | "Label" | Tap ElevatedButton |
| `tap_text` | "Label" | Tap any text widget |
| `type` | "TextField" or hint | Type into text field |
| `scroll_down` | — | Scroll page down |
| `scroll_up` | — | Scroll page up |
| `wait` | "2000" | Wait N milliseconds |
| `screenshot` | — | Take screenshot only |

### Events that auto-fire on screen load

Events ending in `_view` (like `login_screen_view`, `homepage_view`) fire when the screen loads. Use `action: screenshot` — just navigating there triggers them.

### Events that trigger API calls

Events that trigger backend API calls (e.g. send message, submit form, verify payment) may crash in test mode without a real backend — especially if the app shows error toasts/snackbars. **Skip these** — use `action: screenshot` instead and note in the report that the event is validated in logic tests only.

## Step 4: Generate YAML

Build the YAML using `device_funnels` format:

```yaml
device_funnels:
  - name: "{funnel_name}"
    description: "Auto-generated funnel test"
    start_route: /
    steps:
      - name: "Starting screen"
        action: screenshot
        screenshot: start
      - name: "Step description"
        action: tap_nav
        target: "Tab Label"
        expect_event: event_name
        screenshot: step_label
```

## Step 5: Write Test Files

Update `integration_test/run_all.dart`:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';
import 'test_app.dart';

const funnels = '''
{GENERATED_YAML}
''';

void main() {
  runDeviceFunnels(
    yamlContent: funnels,
    appBuilder: ({String? initialRoute}) =>
        createTestApp(initialRoute: initialRoute),
  );
}
```

Also generate `test/funnels/{name}_funnels.yaml` for logic tests:

```yaml
funnels:
  - name: "{funnel_name}"
    mode: ordered
    tags: [auto-generated]
    events:
      - name: event1
      - name: event2
```

And `test/funnels/{name}_funnel_test.dart`:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

void main() {
  testYamlFunnels('test/funnels/{name}_funnels.yaml');
}
```

## Step 6: Run Logic Test (Fast)

```bash
flutter test test/funnels/{name}_funnel_test.dart --reporter=expanded
```

This validates the event sequence in <1 second without a device.

## Step 7: Run Device Test with Screen Recording

Detect platform and start recording:

```bash
mkdir -p test_reports
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DEVICE_INFO=$(flutter devices 2>/dev/null | grep "•" | grep -i "simulator\|emulator\|iphone\|pixel\|android" | head -1)
DEVICE_ID=$(echo "$DEVICE_INFO" | grep -o '• [^ ]*' | head -1 | sed 's/• //')
```

**iOS Simulator:**
```bash
xcrun simctl io booted recordVideo test_reports/funnel_recording_$TIMESTAMP.mp4 &
RECORD_PID=$!
sleep 1
flutter test integration_test/run_all.dart -d $DEVICE_ID --reporter=expanded 2>&1 | tee test_reports/funnel_report_$TIMESTAMP.txt
kill -INT $RECORD_PID 2>/dev/null
wait $RECORD_PID 2>/dev/null
```

**Android Emulator:**
```bash
adb shell screenrecord /sdcard/funnel_recording.mp4 &
RECORD_PID=$!
sleep 1
flutter test integration_test/run_all.dart -d $DEVICE_ID --reporter=expanded 2>&1 | tee test_reports/funnel_report_$TIMESTAMP.txt
kill -INT $RECORD_PID 2>/dev/null
sleep 1
adb pull /sdcard/funnel_recording.mp4 test_reports/funnel_recording_$TIMESTAMP.mp4
adb shell rm /sdcard/funnel_recording.mp4
```

## Step 8: Report

Tell the user:

```
Funnel: {name}
Status: PASSED / FAILED
Events verified: event1, event2, ...

Report:    test_reports/funnel_report_{timestamp}.txt
Recording: test_reports/funnel_recording_{timestamp}.mp4
```

If any steps failed, explain why and suggest fixes.
