/// Result of validating a funnel event sequence.
class FunnelValidationResult {
  final List<String> expectedEvents;
  final List<String> firedEvents;
  final List<String> missingEvents;
  final List<String> outOfOrderEvents;
  final List<String> extraEvents;

  const FunnelValidationResult({
    required this.expectedEvents,
    required this.firedEvents,
    this.missingEvents = const [],
    this.outOfOrderEvents = const [],
    this.extraEvents = const [],
  });

  /// True if all expected events fired in the correct order.
  bool get passed => missingEvents.isEmpty && outOfOrderEvents.isEmpty;

  /// Human-readable report for test output.
  String get report {
    final buf = StringBuffer();
    if (passed) {
      buf.writeln(
          'FUNNEL VALID - All ${expectedEvents.length} events fired in order');
    } else {
      buf.writeln('FUNNEL INVALID');
      if (missingEvents.isNotEmpty) {
        buf.writeln('  Missing events: ${missingEvents.join(", ")}');
      }
      if (outOfOrderEvents.isNotEmpty) {
        buf.writeln('  Out of order: ${outOfOrderEvents.join(", ")}');
      }
    }
    if (extraEvents.isNotEmpty) {
      buf.writeln('  Extra events: ${extraEvents.join(", ")}');
    }
    buf.writeln('  Expected: ${expectedEvents.join(" -> ")}');
    buf.writeln('  Fired:    ${firedEvents.join(" -> ")}');
    return buf.toString();
  }
}

/// A single captured analytics event.
class CapturedEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  const CapturedEvent({
    required this.name,
    required this.properties,
    required this.timestamp,
  });

  @override
  String toString() {
    final props = properties.isNotEmpty ? ' $properties' : '';
    return '$name$props';
  }
}
