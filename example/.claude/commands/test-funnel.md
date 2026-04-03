---
description: Test a funnel on device with screen recording. Just give it event names.
argument-hint: "funnel name: event1 -> event2 -> event3"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

You are a Flutter funnel test agent. The user gives you analytics event names and you test them on a real device with screen recording.

## Input: $ARGUMENTS

Parse the input. Format is: `funnel name: event1 -> event2 -> event3`
Example: `QARA chat: nav_qara_click -> qara_message_send_click -> qara_message_received`

Extract:
- **Funnel name**: text before the colon
- **Events**: split by `->`, trim whitespace

## Step 1: Discover the App's Event-to-Action Map

Read the app's analytics events file to understand what each event means:

```bash
grep -r "MixpanelEvent\|AnalyticsEvent\|trackEvent\|logEvent" lib/ --include="*.dart" -l
```

Then read the events enum file (usually `lib/**/mixpanel_events.dart` or similar) to get all event names.

Search the codebase for where each requested event is fired:
```bash
grep -rn "EVENT_NAME" lib/ --include="*.dart"
```

From the file and line where the event fires, determine:
- Which **screen** the user must be on
- What **UI action** triggers it (tap button, tap nav item, type text, scroll, etc.)
- What **target** widget to interact with (button label, nav label, text field hint)

Use this mapping of action types for the YAML:
- `tap_nav` — tap a bottom navigation item by label text
- `tap_button` — tap an ElevatedButton by label text
- `tap_text` — tap any widget containing this text
- `type` — type text into a field (target: "TextField" for first field, or hint text)
- `scroll_down` / `scroll_up` — scroll the page
- `wait` — wait N milliseconds (value: "2000")
- `screenshot` — just take a screenshot, no interaction

Events that fire automatically on screen load (like `_screen_view` events) don't need a UI action — navigating to that screen is enough. Use `action: screenshot` for these.

## Step 2: Generate the Device Funnel YAML

Build a `device_funnels` YAML string with steps for each event:

```yaml
device_funnels:
  - name: "{funnel_name}"
    description: "Auto-generated funnel test"
    start_route: /
    steps:
      - name: "Step description"
        action: tap_nav
        target: "Tab Label"
        expect_event: event_name
        screenshot: step_label
```

Important rules:
- First step should be `screenshot` of the starting screen
- Events that need navigation: add a `tap_nav` step to get to the right screen first
- Events that fire on tap: add the tap action with `expect_event`
- Events that fire on screen load: just navigate there, use `screenshot`
- Do NOT add steps that trigger API calls which will fail without a backend (like send message, submit OTP) — these crash the test with GetX overlay errors
- Screenshot every step

## Step 3: Update integration_test/run_all.dart

Write the generated YAML into `integration_test/run_all.dart`:

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

If `integration_test/test_app.dart` doesn't exist, create it by reading the app's `main.dart` and creating a test version that:
- Calls `TestableAnalytics.enable()`
- Initializes Firebase (if used)
- Initializes LocalStorage (if used)
- Returns the app's root widget with GetMaterialApp/MaterialApp

## Step 4: Detect Device Platform

```bash
flutter devices 2>&1 | grep "•" | head -1
```

Determine if it's iOS (simulator) or Android (emulator). Extract the device ID.

If no device found, tell the user:
- iOS: `open -a Simulator` or `flutter emulators --launch apple_ios_simulator`
- Android: `flutter emulators --launch <emulator_id>`

## Step 5: Start Screen Recording + Run Tests

Create `test_reports/` directory.

Set timestamp: `TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")`

**iOS Simulator:**
```bash
mkdir -p test_reports
xcrun simctl io booted recordVideo test_reports/funnel_recording_$TIMESTAMP.mp4 &
RECORD_PID=$!
sleep 1
flutter test integration_test/run_all.dart -d DEVICE_ID --reporter=expanded 2>&1 | tee test_reports/funnel_report_$TIMESTAMP.txt
kill -INT $RECORD_PID 2>/dev/null
wait $RECORD_PID 2>/dev/null
```

**Android Emulator:**
```bash
mkdir -p test_reports
adb shell screenrecord /sdcard/funnel_recording.mp4 &
RECORD_PID=$!
sleep 1
flutter test integration_test/run_all.dart -d DEVICE_ID --reporter=expanded 2>&1 | tee test_reports/funnel_report_$TIMESTAMP.txt
kill -INT $RECORD_PID 2>/dev/null
sleep 1
adb pull /sdcard/funnel_recording.mp4 test_reports/funnel_recording_$TIMESTAMP.mp4
adb shell rm /sdcard/funnel_recording.mp4
```

## Step 6: Generate Report

After the test completes, read the test output and create a clean summary. Append to the report file:

```
═══ FUNNEL TEST REPORT ═══
Name:      {funnel_name}
Timestamp: {timestamp}
Status:    PASSED / FAILED

Steps:
  [PASS/FAIL] Step name → event captured
  ...

Analytics Events Captured:
  1. event_name {properties}
  ...

Recording: test_reports/funnel_recording_{timestamp}.mp4
Report:    test_reports/funnel_report_{timestamp}.txt
```

## Step 7: Report to User

Tell the user:
1. Pass/fail result
2. Path to the `.mp4` screen recording
3. Path to the `.txt` report
4. Which analytics events were verified
5. If any steps failed, explain why

## Also Generate Logic Test

In addition to the device test, also generate `test/funnels/{funnel_name}_funnels.yaml` with the analytics event sequence and a test file that uses `testYamlFunnels()`:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

void main() {
  testYamlFunnels('test/funnels/{funnel_name}_funnels.yaml');
}
```

Run this too: `flutter test test/funnels/{funnel_name}_funnel_test.dart --reporter=expanded`
This validates the event sequence without a device (fast, <1s).
