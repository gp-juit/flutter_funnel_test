import 'funnel_validation_result.dart';

/// Captures analytics events in unit tests.
///
/// Use this in tests that don't run on a device. For integration tests
/// on an emulator, use [TestableAnalytics] instead.
///
/// ```dart
/// AnalyticsCapture.reset();
/// // ... run funnel actions ...
/// final result = AnalyticsCapture.assertFunnel([
///   'login_screen_view',
///   'phone_continue_click',
///   'login_successful',
/// ]);
/// expect(result.passed, isTrue);
/// ```
class AnalyticsCapture {
  static final List<CapturedEvent> _events = [];

  static List<CapturedEvent> get events => List.unmodifiable(_events);
  static int get count => _events.length;

  /// Clear all captured events. Call between test cases.
  static void reset() => _events.clear();

  /// Record an analytics event.
  static void track(String eventName, [Map<String, dynamic>? properties]) {
    _events.add(CapturedEvent(
      name: eventName,
      properties: properties ?? {},
      timestamp: DateTime.now(),
    ));
  }

  // ─── Queries ───────────────────────────────────────────

  /// All captured event names in order.
  static List<String> get eventNames => _events.map((e) => e.name).toList();

  /// Check if a specific event was fired.
  static bool hasEvent(String name) => _events.any((e) => e.name == name);

  /// Get all occurrences of a specific event.
  static List<CapturedEvent> getEvents(String name) =>
      _events.where((e) => e.name == name).toList();

  /// Get the first occurrence of an event.
  static CapturedEvent? getFirst(String name) {
    for (final e in _events) {
      if (e.name == name) return e;
    }
    return null;
  }

  /// Check if an event was fired with specific properties.
  static bool hasEventWithProperties(
      String name, Map<String, dynamic> expected) {
    return _events.any((e) {
      if (e.name != name) return false;
      return expected.entries
          .every((entry) => e.properties[entry.key] == entry.value);
    });
  }

  // ─── Funnel Validation ─────────────────────────────────

  /// Assert events fired in order. Other events may appear between them.
  static FunnelValidationResult assertFunnel(List<String> expectedEvents) {
    final fired = eventNames;
    final missing = <String>[];
    final outOfOrder = <String>[];
    int lastFoundIndex = -1;

    for (final expected in expectedEvents) {
      final index = fired.indexWhere((e) => e == expected, lastFoundIndex + 1);
      if (index == -1) {
        if (fired.contains(expected)) {
          outOfOrder.add(expected);
        } else {
          missing.add(expected);
        }
      } else {
        lastFoundIndex = index;
      }
    }

    return FunnelValidationResult(
      expectedEvents: expectedEvents,
      firedEvents: fired,
      missingEvents: missing,
      outOfOrderEvents: outOfOrder,
    );
  }

  /// Assert exact event sequence. No extra events allowed.
  static FunnelValidationResult assertStrictFunnel(
      List<String> expectedEvents) {
    final fired = eventNames;
    final missing = <String>[];
    final extra = <String>[];

    for (var i = 0; i < expectedEvents.length; i++) {
      if (i >= fired.length) {
        missing.addAll(expectedEvents.sublist(i));
        break;
      }
      if (fired[i] != expectedEvents[i]) {
        missing.add(expectedEvents[i]);
      }
    }

    if (fired.length > expectedEvents.length) {
      extra.addAll(fired.sublist(expectedEvents.length));
    }

    return FunnelValidationResult(
      expectedEvents: expectedEvents,
      firedEvents: fired,
      missingEvents: missing,
      extraEvents: extra,
    );
  }

  /// Pretty-print all captured events for debugging.
  static String dump() {
    if (_events.isEmpty) return '(no analytics events captured)';
    final buf = StringBuffer('Captured ${_events.length} events:\n');
    for (var i = 0; i < _events.length; i++) {
      final e = _events[i];
      final props = e.properties.isNotEmpty ? ' ${e.properties}' : '';
      buf.writeln('  ${i + 1}. ${e.name}$props');
    }
    return buf.toString();
  }
}
