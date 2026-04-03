import 'funnel_validation_result.dart';

/// On-device analytics capture for integration tests.
///
/// Wire this into your analytics service with a 3-line check:
/// ```dart
/// void track(String event, [Map<String, dynamic>? props]) {
///   if (TestableAnalytics.isEnabled) TestableAnalytics.capture(event, props);
///   _realSdk.track(event, props);
/// }
/// ```
///
/// Then in integration tests:
/// ```dart
/// TestableAnalytics.enable();
/// // ... tap through UI ...
/// expect(TestableAnalytics.hasEvent('login_successful'), isTrue);
/// ```
class TestableAnalytics {
  static bool _enabled = false;
  static final List<CapturedEvent> _events = [];

  /// Enable capture mode. Call before launching the test app.
  static void enable() {
    _enabled = true;
    _events.clear();
  }

  /// Disable and reset.
  static void disable() {
    _enabled = false;
    _events.clear();
  }

  /// Whether capture mode is active.
  static bool get isEnabled => _enabled;

  /// Record an event. Called by your analytics service when test mode is on.
  static void capture(String eventName, [Map<String, dynamic>? properties]) {
    if (!_enabled) return;
    _events.add(CapturedEvent(
      name: eventName,
      properties: properties ?? {},
      timestamp: DateTime.now(),
    ));
  }

  /// Clear captured events. Call between funnels.
  static void clear() => _events.clear();

  // ─── Queries ───────────────────────────────────────────

  static List<CapturedEvent> get events => List.unmodifiable(_events);
  static List<String> get eventNames => _events.map((e) => e.name).toList();
  static int get count => _events.length;

  static bool hasEvent(String name) => _events.any((e) => e.name == name);

  static CapturedEvent? lastEvent(String name) {
    for (int i = _events.length - 1; i >= 0; i--) {
      if (_events[i].name == name) return _events[i];
    }
    return null;
  }

  static bool hasEventWithProps(String name, Map<String, dynamic> expected) {
    return _events.any((e) {
      if (e.name != name) return false;
      return expected.entries.every((kv) => e.properties[kv.key] == kv.value);
    });
  }

  /// Verify events fired in given order (other events may appear between).
  static FunnelValidationResult assertFunnel(List<String> expectedEvents) {
    final fired = eventNames;
    final missing = <String>[];
    final outOfOrder = <String>[];
    int cursor = -1;

    for (final expected in expectedEvents) {
      final idx = fired.indexWhere((e) => e == expected, cursor + 1);
      if (idx == -1) {
        if (fired.contains(expected)) {
          outOfOrder.add(expected);
        } else {
          missing.add(expected);
        }
      } else {
        cursor = idx;
      }
    }

    return FunnelValidationResult(
      expectedEvents: expectedEvents,
      firedEvents: fired,
      missingEvents: missing,
      outOfOrderEvents: outOfOrder,
    );
  }

  /// Pretty-print all captured events.
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
