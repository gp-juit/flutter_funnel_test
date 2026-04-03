import 'package:flutter_test/flutter_test.dart';
import '../analytics/analytics_capture.dart';
import 'yaml_funnel_definition.dart';

/// Simulate a YAML funnel by firing events into [AnalyticsCapture]
/// and validating the sequence + properties.
void simulateAndValidateFunnel(YamlFunnelDefinition funnel) {
  AnalyticsCapture.reset();

  for (final event in funnel.events) {
    AnalyticsCapture.track(event.name, event.properties);
  }

  final result = funnel.mode == 'strict'
      ? AnalyticsCapture.assertStrictFunnel(
          funnel.events.map((e) => e.name).toList())
      : AnalyticsCapture.assertFunnel(
          funnel.events.map((e) => e.name).toList());

  expect(result.passed, isTrue, reason: result.report);

  for (final event in funnel.events) {
    if (event.properties.isNotEmpty) {
      expect(
        AnalyticsCapture.hasEventWithProperties(event.name, event.properties),
        isTrue,
        reason: 'Event "${event.name}" missing expected properties: '
            '${event.properties}',
      );
    }
  }
}

/// Validate a YAML funnel against already-captured events (no simulation).
/// Use this after real user actions have fired events into [AnalyticsCapture].
void validateFunnelAgainstCapture(YamlFunnelDefinition funnel) {
  final result = funnel.mode == 'strict'
      ? AnalyticsCapture.assertStrictFunnel(
          funnel.events.map((e) => e.name).toList())
      : AnalyticsCapture.assertFunnel(
          funnel.events.map((e) => e.name).toList());

  expect(result.passed, isTrue, reason: result.report);

  for (final event in funnel.events) {
    if (event.properties.isNotEmpty) {
      expect(
        AnalyticsCapture.hasEventWithProperties(event.name, event.properties),
        isTrue,
        reason: 'Event "${event.name}" missing expected properties: '
            '${event.properties}',
      );
    }
  }
}
