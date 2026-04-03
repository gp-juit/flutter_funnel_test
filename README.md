# flutter_funnel_test

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/badge/GitHub-gp--juit-181717?style=for-the-badge&logo=github)](https://github.com/gp-juit/flutter_funnel_test)

![Tests](https://img.shields.io/badge/tests-23%20passing-brightgreen?style=flat-square&logo=checkmarx)
![Dependencies](https://img.shields.io/badge/external%20deps-0-brightgreen?style=flat-square)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey?style=flat-square)
![Claude Code](https://img.shields.io/badge/Claude%20Code-AI%20Agent-blueviolet?style=flat-square&logo=anthropic)

> **Analytics-agnostic** | **State management-agnostic** | **Zero external dependencies** | **AI Agent included**

Test Flutter app funnels by just typing event names in chat. The AI agent handles everything — generates tests, runs on device, records the screen, writes a report.

**Works with any analytics provider** (Mixpanel, Firebase Analytics, Amplitude, PostHog, Segment) and **any state management** (GetX, BLoC, Riverpod, Provider, plain setState).

---

## How It Works

**PM types this in Claude Code:**
```
/test-funnel checkout: cart_view -> checkout_start -> payment_success
```

**Agent does all of this automatically:**

1. Reads your app's analytics events from source code
2. Maps each event to UI actions (tap button, tap nav, type text)
3. Generates YAML funnel definition + Dart test files
4. Starts screen recording on iOS Simulator or Android Emulator
5. Runs Flutter integration test on device
6. Stops recording, writes a report

**PM gets:**
```
test_reports/
  funnel_report_2026-04-03_22-09-39.txt      # Pass/fail report
  funnel_recording_2026-04-03_22-09-39.mp4   # Screen recording
```

---

## Features

- **AI Agent (Claude Code Skill)** — PM types event names, agent does the rest
- **Screen Recording** — automatic `.mp4` capture on iOS Simulator and Android Emulator
- **YAML Funnel Definitions** — declare funnels as ordered event sequences
- **Auto-Generated Reports** — timestamped `.txt` reports saved to `test_reports/`
- **Analytics Validation** — assert events fire in order with correct properties
- **Coverage Reports** — see which analytics events are tested
- **Zero External Dependencies** — built-in YAML parser, only depends on Flutter SDK
- **Provider Agnostic** — 3-line adapter for any analytics SDK
- **`testYamlFunnels()`** — 4-line test file, auto-generates tests from YAML

---

## Setup

### Option A: Install as Claude Code Skill (Recommended)

Copy the `.claude-plugin/`, `skills/`, `commands/`, and `hooks/` directories into your project's `.claude/` folder. On next session start, the hook auto-adds the package to your `pubspec.yaml`.

Then add the 3-line analytics hook (one-time, see [Wire Analytics](#2-wire-your-analytics-3-lines) below).

### Option B: Manual Install

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_funnel_test:
    git:
      url: https://github.com/gp-juit/flutter_funnel_test.git
```

```bash
flutter pub get
```

---

## Quick Start

### 1. Install the Package

Add to `pubspec.yaml` dev_dependencies (or let the skill hook do it):

```yaml
flutter_funnel_test:
  git:
    url: https://github.com/gp-juit/flutter_funnel_test.git
```

### 2. Wire Your Analytics (3 lines)

Add this to your existing analytics service — works with any SDK:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

class MyAnalyticsService {
  static void track(String event, [Map<String, dynamic>? props]) {
    if (TestableAnalytics.isEnabled) TestableAnalytics.capture(event, props);
    _sdk.track(event, properties: props);  // Your real SDK
  }
}
```

### 3. Use It

**With AI Agent (Claude Code):**
```
/list-events                                          # See all your events
/test-funnel signup: signup_view -> signup_success     # Test a funnel
```

**With YAML (no agent):**

Create `test/funnels/my_funnels.yaml`:
```yaml
funnels:
  - name: "Signup"
    mode: ordered
    tags: [auth]
    events:
      - name: signup_view
      - name: email_entered
        properties: { valid: true }
      - name: signup_success
```

Create `test/funnels/my_funnel_test.dart`:
```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

void main() {
  testYamlFunnels('test/funnels/my_funnels.yaml');
}
```

Run:
```bash
flutter test test/funnels/
```

---

## AI Agent Commands

### `/test-funnel`

Test a funnel on device with screen recording.

```
/test-funnel checkout: cart_view -> checkout_start -> payment_success
/test-funnel signup: signup_view -> email_entered -> signup_success
/test-funnel onboarding: welcome_view -> step1_complete -> step2_complete
```

**What it does:**
1. Parses event names from your input
2. Searches your codebase to map events to UI actions
3. Generates YAML + Dart test files
4. Starts screen recording (iOS: `xcrun simctl`, Android: `adb screenrecord`)
5. Runs `flutter test` on the connected device
6. Stops recording, saves report + video to `test_reports/`

### `/list-events`

Shows all analytics events defined in your app, grouped by category.

```
/list-events
```

---

## Device Funnel YAML

For UI tests that run on emulator with screen recording:

```yaml
device_funnels:
  - name: "Checkout Flow"
    description: "User completes purchase"
    start_route: /
    steps:
      - name: "Home screen"
        action: screenshot
        screenshot: home

      - name: "Tap Cart tab"
        action: tap_nav
        target: "Cart"
        expect_event: cart_view
        screenshot: cart

      - name: "Tap Checkout"
        action: tap_button
        target: "Checkout"
        expect_event: checkout_start
        screenshot: checkout

      - name: "Scroll to payment"
        action: scroll_down
        screenshot: payment
```

### Available Actions

| action | target | value | What it does |
|--------|--------|-------|-------------|
| `tap_nav` | "Tab Label" | — | Tap bottom navigation item |
| `tap_button` | "Button Text" | — | Tap ElevatedButton |
| `tap_text` | "Any text" | — | Tap any text widget |
| `type` | "TextField" or hint | "text to type" | Type into field |
| `scroll_down` | — | — | Scroll page down |
| `scroll_up` | — | — | Scroll page up |
| `wait` | — | "2000" | Wait N milliseconds |
| `screenshot` | — | — | Take screenshot only |

Each step can also have `expect_event`, `expect_text`, and `screenshot`.

### Run Device Funnels

```dart
// integration_test/run_all.dart
import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';
import 'test_app.dart';

const funnels = '''
device_funnels:
  - name: "My Flow"
    start_route: /
    steps:
      - name: "Home"
        action: screenshot
        screenshot: home
''';

void main() {
  runDeviceFunnels(
    yamlContent: funnels,
    appBuilder: ({String? initialRoute}) =>
        createTestApp(initialRoute: initialRoute),
  );
}
```

```bash
flutter test integration_test/run_all.dart -d <device_id>
```

---

## Analytics Funnel YAML

For logic tests that validate event sequences (no device needed, runs in <1s):

```yaml
funnels:
  - name: "Signup"
    description: "New user signs up"
    mode: ordered
    tags: [auth, critical]
    events:
      - name: signup_view
      - name: email_entered
        properties:
          valid: true
      - name: signup_success
        properties:
          method: email
```

**Modes:**
- `ordered` — events must fire in this order, other events can appear between them
- `strict` — only these exact events fire, nothing else

---

## Auto-Generated Reports

Every test run produces a timestamped report in `test_reports/`:

```
═══════════════════════════════════════════════
  FUNNEL TEST REPORT
═══════════════════════════════════════════════

Source:    my_funnels.yaml
Timestamp: 2026-04-03T22-08-54
Funnels:   3

[PASS] Signup Flow
  Events: signup_view -> email_entered -> signup_success
    - signup_view
    - email_entered {valid: true}
    - signup_success {method: email}

[PASS] Checkout Flow
  Events: cart_view -> checkout_start -> payment_success

───────────────────────────────────────────────
SUMMARY
  Total:  3
  Passed: 3
  Failed: 0
  Result: ALL PASSED
───────────────────────────────────────────────
```

---

## Coverage Report

See which analytics events have funnel coverage:

```dart
final report = FunnelReport.coverageReport(
  allEvents: ['signup_view', 'login_view', 'purchase', 'logout'],
  funnels: funnels,
);
print(report);
```

```
=== Analytics Event Coverage ===
Total events:    4
Covered:         3
Uncovered:       1
Coverage:        75.0%

Uncovered events:
  - logout
```

---

## Adapter Examples

### Mixpanel
```dart
if (TestableAnalytics.isEnabled) TestableAnalytics.capture(event.name, props);
_mixpanel.track(event.name, properties: props);
```

### Firebase Analytics
```dart
if (TestableAnalytics.isEnabled) TestableAnalytics.capture(name, params);
_firebaseAnalytics.logEvent(name: name, parameters: params);
```

### Amplitude
```dart
if (TestableAnalytics.isEnabled) TestableAnalytics.capture(event, props);
_amplitude.logEvent(event, eventProperties: props);
```

### PostHog
```dart
if (TestableAnalytics.isEnabled) TestableAnalytics.capture(event, props);
_posthog.capture(eventName: event, properties: props);
```

---

## API Reference

### Imports

```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';               // Unit tests
import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';    // Device tests
```

### Core Classes

| Class | Purpose |
|-------|---------|
| `TestableAnalytics` | On-device analytics capture — `enable()`, `capture()`, `assertFunnel()` |
| `AnalyticsCapture` | Unit test event recorder — `track()`, `assertFunnel()`, `dump()` |
| `FunnelTester` | Wraps `WidgetTester` — `step()`, `tap()`, `enterText()`, `screenshot()`, `expectEvent()` |
| `FunnelDefinition` | Programmatic funnel — `run()` returns `FunnelResult` |
| `FunnelRegistry` | Batch execute funnels — `runAll()`, `getByTag()` |
| `FunnelReport` | Generate coverage and validation reports |

### Key Functions

| Function | Purpose |
|----------|---------|
| `testYamlFunnels(path)` | Auto-generate tests from YAML — 4-line test file |
| `parseYamlFunnels(content)` | Parse analytics YAML funnels |
| `parseDeviceFunnels(content)` | Parse device YAML funnels |
| `runDeviceFunnels(yaml, appBuilder)` | Run device funnels from YAML |
| `simulateAndValidateFunnel(funnel)` | Validate a single funnel |

---

## Skill / Plugin Structure

```
flutter_funnel_test/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest
├── skills/
│   └── funnel-test/
│       ├── SKILL.md                   # AI agent brain
│       └── references/
│           └── yaml-schema.md         # YAML action reference
├── commands/
│   ├── test-funnel.md                 # /test-funnel slash command
│   └── list-events.md                 # /list-events slash command
├── hooks/
│   ├── hooks.json                     # SessionStart hook config
│   └── scripts/
│       └── setup.sh                   # Auto-installs package on first session
├── lib/                               # Flutter package source
├── test/                              # 23 package tests
└── example/                           # Example app + commands
```

---

## Contributing

Contributions are welcome! Feel free to open issues and pull requests.

[![GitHub Issues](https://img.shields.io/badge/Issues-Open%20One-red?style=flat-square&logo=github)](https://github.com/gp-juit/flutter_funnel_test/issues)
[![GitHub PRs](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square&logo=github)](https://github.com/gp-juit/flutter_funnel_test/pulls)

---

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=dart&logoColor=white" height="16"/> by <strong><a href="https://github.com/gp-juit">Gurpreet Singh</a></strong>
  <br/>
  <sub>If this package helps you, consider giving it a <a href="https://github.com/gp-juit/flutter_funnel_test">star</a>!</sub>
</p>
