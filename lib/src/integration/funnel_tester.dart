import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../analytics/testable_analytics.dart';
import 'step_screenshot.dart';

/// High-level test helper for UI funnel testing on emulators.
///
/// Wraps [WidgetTester] with funnel-specific actions: tap, scroll,
/// type, screenshot, and analytics assertion.
///
/// Extend this class to add app-specific widget finders.
///
/// ```dart
/// testWidgets('signup funnel', (tester) async {
///   final ft = FunnelTester(tester, binding);
///   await tester.pumpWidget(MyApp());
///   await ft.settle();
///
///   await ft.step('Enter email', action: () async {
///     await ft.typeByHint('Email', 'user@test.com');
///   }, expectEvents: ['email_entered']);
/// });
/// ```
class FunnelTester {
  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final List<StepScreenshot> _screenshots = [];
  int _stepIndex = 0;

  FunnelTester(this.tester, this.binding);

  // ─── Navigation ────────────────────────────────────────

  Future<void> settle({Duration? timeout}) async {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout ?? const Duration(seconds: 10),
    );
  }

  Future<void> wait(Duration duration) async {
    await tester.pump(duration);
  }

  // ─── Finders ───────────────────────────────────────────

  Finder buttonByText(String text) =>
      find.widgetWithText(ElevatedButton, text);

  Finder outlinedButtonByText(String text) =>
      find.widgetWithText(OutlinedButton, text);

  Finder textButtonByText(String text) =>
      find.widgetWithText(TextButton, text);

  Finder tapTargetByText(String text) => find.text(text);

  Finder textFieldByHint(String hint) =>
      find.widgetWithText(TextFormField, hint);

  Finder firstTextField() => find.byType(TextFormField).first;

  Finder byKey(String key) => find.byKey(Key(key));

  Finder byWidgetType(Type type) => find.byType(type);

  Finder navItem(String label) => find.text(label);

  // ─── Actions ───────────────────────────────────────────

  Future<void> tap(Finder finder, {bool settle = true}) async {
    expect(finder, findsWidgets,
        reason: 'Cannot tap: widget not found — ${finder.description}');
    await tester.tap(finder.first);
    if (settle) {
      await this.settle();
    } else {
      await tester.pump();
    }
  }

  Future<void> tapButton(String text) async => tap(buttonByText(text));

  Future<void> tapNavItem(String label) async => tap(navItem(label));

  Future<void> enterText(Finder finder, String text) async {
    expect(finder, findsWidgets,
        reason: 'Cannot type: field not found — ${finder.description}');
    await tester.tap(finder.first);
    await tester.pump();
    await tester.enterText(finder.first, text);
    await tester.pump();
  }

  Future<void> typeIntoFirstField(String text) async {
    await enterText(find.byType(TextFormField).first, text);
  }

  Future<void> typeByHint(String hint, String text) async {
    final finder = find.widgetWithText(TextFormField, hint);
    if (finder.evaluate().isEmpty) {
      await enterText(find.widgetWithText(TextField, hint), text);
    } else {
      await enterText(finder, text);
    }
  }

  Future<void> scrollDown({double dy = 300}) async {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
    await settle();
  }

  Future<void> scrollUp({double dy = 300}) async {
    await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
    await settle();
  }

  // ─── UI Assertions ─────────────────────────────────────

  void expectVisible(String text) {
    expect(find.text(text), findsWidgets,
        reason: '"$text" should be visible on screen');
  }

  void expectNotVisible(String text) {
    expect(find.text(text), findsNothing,
        reason: '"$text" should not be visible');
  }

  void expectWidgetExists(Type type) {
    expect(find.byType(type), findsWidgets,
        reason: '$type should exist on screen');
  }

  void expectLoading() =>
      expect(find.byType(CircularProgressIndicator), findsWidgets);

  void expectNotLoading() =>
      expect(find.byType(CircularProgressIndicator), findsNothing);

  // ─── Analytics Assertions ──────────────────────────────

  void expectEvent(String eventName) {
    expect(TestableAnalytics.hasEvent(eventName), isTrue,
        reason: 'Expected analytics event "$eventName" to fire.\n'
            '${TestableAnalytics.dump()}');
  }

  void expectEventWithProps(String eventName, Map<String, dynamic> props) {
    expect(TestableAnalytics.hasEventWithProps(eventName, props), isTrue,
        reason: 'Expected "$eventName" with props $props.\n'
            '${TestableAnalytics.dump()}');
  }

  void expectFunnel(List<String> events) {
    final result = TestableAnalytics.assertFunnel(events);
    expect(result.passed, isTrue, reason: result.report);
  }

  void resetAnalytics() => TestableAnalytics.clear();

  void dumpAnalytics() {
    // ignore: avoid_print
    print(TestableAnalytics.dump());
  }

  // ─── Screenshots ──────────────────────────────────────

  Future<void> screenshot(String label) async {
    _stepIndex++;
    final name = '${_stepIndex.toString().padLeft(2, '0')}_$label';
    try {
      await binding.takeScreenshot(name);
    } catch (_) {}
    _screenshots.add(StepScreenshot(
      index: _stepIndex,
      label: label,
      filename: name,
    ));
  }

  // ─── Funnel Step ──────────────────────────────────────

  /// Run a named funnel step with optional screenshot + analytics assertion.
  Future<void> step(
    String name, {
    required Future<void> Function() action,
    List<String>? expectEvents,
    List<String>? expectTexts,
    bool takeScreenshot = true,
  }) async {
    // ignore: avoid_print
    print('  Step: $name');

    await action();
    await settle();

    if (takeScreenshot) {
      await screenshot(name.replaceAll(' ', '_').toLowerCase());
    }

    if (expectTexts != null) {
      for (final text in expectTexts) {
        expectVisible(text);
      }
    }

    if (expectEvents != null) {
      for (final event in expectEvents) {
        expectEvent(event);
      }
    }
  }

  /// Print a summary report.
  void printReport(String funnelName) {
    // ignore: avoid_print
    print('\n=== $funnelName ===');
    // ignore: avoid_print
    print('Screenshots: ${_screenshots.length}');
    for (final s in _screenshots) {
      // ignore: avoid_print
      print('  ${s.index}. ${s.label} -> ${s.filename}');
    }
    // ignore: avoid_print
    print('Analytics: ${TestableAnalytics.count} events captured');
    // ignore: avoid_print
    print(TestableAnalytics.dump());
  }
}
