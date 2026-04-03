# flutter_funnel_test

A generic framework for testing **UI, business logic, and analytics** across user funnels in any Flutter app.

Define funnels as YAML event sequences, validate analytics fire in the right order with correct properties, and run integration tests on emulators with screenshots — all from one package.

**Works with any analytics provider** (Mixpanel, Firebase Analytics, Amplitude, PostHog, Segment) and **any state management** (GetX, BLoC, Riverpod, Provider, plain setState).

---

## Features

- **YAML Funnel Definitions** — declare funnels as ordered event sequences, no code needed
- **Analytics Validation** — assert events fire in order with correct properties
- **Integration Test Helpers** — `FunnelTester` wraps `WidgetTester` with tap, scroll, type, screenshot, and analytics assertions
- **Coverage Reports** — see which analytics events are tested and which are not
- **Zero External Dependencies** — built-in YAML parser, only depends on Flutter SDK
- **Provider Agnostic** — 3-line adapter wiring for any analytics SDK
- **Extensible** — subclass `FunnelTester` to add app-specific widget finders

---

## Quick Start (10 minutes)

### 1. Install

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_funnel_test:
    git:
      url: https://github.com/gp-juit/flutter_funnel_test.git
```

### 2. Wire Your Analytics (3 lines)

Add this check to your existing analytics service — works with any SDK:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

class MyAnalyticsService {
  static void track(String event, [Map<String, dynamic>? props]) {
    // This line enables funnel testing
    if (TestableAnalytics.isEnabled) TestableAnalytics.capture(event, props);

    // Your real SDK call (Mixpanel, Firebase, Amplitude, etc.)
    _mixpanel.track(event, properties: props);
  }
}
```

### 3. Define Funnels in YAML

Create `test/funnels/my_funnels.yaml`:

```yaml
funnels:
  - name: "User Signup"
    description: "New user signs up via email"
    mode: ordered
    tags: [auth, critical]
    events:
      - name: signup_screen_view
        description: "Signup screen loads"
      - name: email_entered
        properties:
          valid: true
      - name: signup_button_click
      - name: signup_success
        properties:
          method: email

  - name: "Add to Cart"
    description: "User browses and adds item"
    mode: ordered
    tags: [ecommerce]
    events:
      - name: product_list_view
      - name: product_card_click
        properties:
          product_id: "123"
      - name: add_to_cart_click
```

### 4. Write Tests

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

void main() {
  late List<YamlFunnelDefinition> funnels;

  setUpAll(() {
    funnels = parseYamlFunnels(
      File('test/funnels/my_funnels.yaml').readAsStringSync(),
    );
  });

  test('User Signup funnel validates', () {
    simulateAndValidateFunnel(
      funnels.firstWhere((f) => f.name == 'User Signup'),
    );
  });

  test('Add to Cart funnel validates', () {
    simulateAndValidateFunnel(
      funnels.firstWhere((f) => f.name == 'Add to Cart'),
    );
  });
}
```

### 5. Run

```bash
flutter test test/funnels/
```

---

## Integration Tests (on Emulator)

Test real UI with taps, scrolls, typed text, screenshots, and analytics assertions.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup funnel on device', (tester) async {
    TestableAnalytics.enable();
    final ft = FunnelTester(tester, binding);

    await tester.pumpWidget(MyApp());
    await ft.settle();

    await ft.step('Enter email', action: () async {
      await ft.typeByHint('Email', 'user@test.com');
    }, expectEvents: ['email_entered']);

    await ft.step('Tap signup', action: () async {
      await ft.tapButton('Sign Up');
    }, expectEvents: ['signup_success']);

    // Assert entire funnel sequence
    ft.expectFunnel([
      'signup_screen_view',
      'email_entered',
      'signup_success',
    ]);

    await ft.screenshot('signup_complete');
    ft.printReport('Signup Funnel');
  });
}
```

Run on emulator:

```bash
flutter test integration_test/signup_test.dart
```

---

## Programmatic Funnels

Define funnels in Dart code for testing business logic:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

final loginFunnel = FunnelDefinition(
  name: 'Login Flow',
  description: 'User logs in with email',
  tags: ['auth'],
  steps: [
    FunnelStep(
      name: 'Enter credentials',
      description: 'User types email and password',
      action: () async {
        controller.setEmail('user@test.com');
        controller.setPassword('password123');
      },
      assertions: () async {
        expect(controller.isFormValid, isTrue);
        return {'formValid': true};
      },
    ),
    FunnelStep(
      name: 'Submit login',
      description: 'User taps login button',
      action: () async {
        await controller.login();
      },
      assertions: () async {
        expect(controller.isLoggedIn, isTrue);
        return {'loggedIn': true};
      },
    ),
  ],
);

// Run it
test('login funnel', () async {
  final result = await loginFunnel.run();
  print(result.detailedReport);
  expect(result.allPassed, isTrue);
});
```

---

## Coverage Report

See which analytics events are covered by your funnels:

```dart
final report = FunnelReport.coverageReport(
  allEvents: ['signup_view', 'login_view', 'purchase', 'logout'],
  funnels: funnels,
);
print(report);
```

Output:

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

## API Reference

### Imports

```dart
// For unit tests (no device needed)
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

// For integration tests on emulator (adds FunnelTester)
import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';
```

### Analytics Layer

| Class | Purpose |
|-------|---------|
| `AnalyticsAdapter` | Abstract class — implement for your analytics SDK |
| `AnalyticsCapture` | Unit test event recorder — `track()`, `assertFunnel()`, `dump()` |
| `TestableAnalytics` | On-device capture — wire into your service with `isEnabled` check |
| `FunnelValidationResult` | Result of funnel assertion — `passed`, `missingEvents`, `report` |
| `CapturedEvent` | Single captured event — `name`, `properties`, `timestamp` |

### Funnel Framework

| Class | Purpose |
|-------|---------|
| `FunnelDefinition` | Sequence of steps forming a user journey — `run()` |
| `FunnelStep` | Single step — `action`, `assertions`, `precondition` |
| `FunnelResult` | Execution result — `allPassed`, `detailedReport` |
| `StepResult` | Single step result — `passed`, `errorMessage`, `stateSnapshot` |
| `FunnelRegistry` | Register and batch-execute funnels — `runAll()`, `getByTag()` |

### YAML Funnels

| Function / Class | Purpose |
|------------------|---------|
| `parseYamlFunnels(String)` | Parse YAML into funnel definitions |
| `simulateAndValidateFunnel(funnel)` | Fire events and validate sequence |
| `validateFunnelAgainstCapture(funnel)` | Validate against already-captured events |
| `YamlFunnelDefinition` | Parsed funnel — `name`, `events`, `mode`, `tags` |
| `ExpectedEvent` | Expected event — `name`, `properties`, `description` |

### Integration Testing

| Class | Purpose |
|-------|---------|
| `FunnelTester` | Wraps `WidgetTester` — `step()`, `tap()`, `tapButton()`, `enterText()`, `typeByHint()`, `scrollDown()`, `screenshot()`, `expectEvent()`, `expectFunnel()` |
| `StepScreenshot` | Screenshot metadata |

### Reports

| Class | Purpose |
|-------|---------|
| `FunnelReport` | `coverageReport()`, `fromValidationResults()`, `fromFunnelResults()` |

---

## YAML Funnel Format

```yaml
funnels:
  - name: "Funnel Name"              # Required
    description: "What it tests"      # Optional
    mode: ordered                     # "ordered" (default) or "strict"
    tags: [tag1, tag2]                # Optional, for filtering
    events:
      - name: event_name              # Required — your analytics event name
        properties:                   # Optional — assert these properties
          key: value
          another_key: true
        description: "What triggers"  # Optional — documentation
```

**Modes:**
- `ordered` — events must fire in this order, but other events can appear between them
- `strict` — only these exact events fire, nothing else

---

## Extending FunnelTester

Add app-specific widget finders by subclassing:

```dart
import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';
import 'package:my_app/widgets/my_button.dart';

class MyAppTester extends FunnelTester {
  MyAppTester(super.tester, super.binding);

  Finder myButton(String text) => find.widgetWithText(MyButton, text);

  Future<void> tapMyButton(String text) async => tap(myButton(text));
}
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

## License

MIT License - Gurpreet Singh

---

## Author

**Gurpreet Singh** — [github.com/gp-juit](https://github.com/gp-juit)
