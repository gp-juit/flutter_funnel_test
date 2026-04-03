import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../analytics/analytics_capture.dart';
import 'yaml_funnel_definition.dart';
import 'yaml_parser.dart';

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

/// Auto-generate and run tests for every funnel in a YAML file.
///
/// Just call this from a test file — no boilerplate needed:
/// ```dart
/// import 'package:flutter_funnel_test/flutter_funnel_test.dart';
///
/// void main() {
///   testYamlFunnels('test/funnels/my_funnels.yaml');
/// }
/// ```
void testYamlFunnels(String yamlFilePath, {String? tag}) {
  final file = File(yamlFilePath);
  final funnels = parseYamlFunnels(file.readAsStringSync());

  final filtered = tag != null
      ? funnels.where((f) => f.tags.contains(tag)).toList()
      : funnels;

  group('Funnels: ${yamlFilePath.split('/').last}', () {
    for (final funnel in filtered) {
      test(funnel.name, () {
        simulateAndValidateFunnel(funnel);
      });
    }
  });
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
