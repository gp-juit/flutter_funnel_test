import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../analytics/analytics_capture.dart';
import '../report/funnel_report.dart';
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
/// Generates a report to `test_reports/` after every run.
///
/// ```dart
/// import 'package:flutter_funnel_test/flutter_funnel_test.dart';
///
/// void main() {
///   testYamlFunnels('test/funnels/my_funnels.yaml');
/// }
/// ```
void testYamlFunnels(String yamlFilePath, {String? tag, String reportDir = 'test_reports'}) {
  final file = File(yamlFilePath);
  final funnels = parseYamlFunnels(file.readAsStringSync());

  final filtered = tag != null
      ? funnels.where((f) => f.tags.contains(tag)).toList()
      : funnels;

  final yamlName = yamlFilePath.split('/').last.replaceAll('.yaml', '');
  final results = <String, _FunnelTestResult>{};

  group('Funnels: $yamlName', () {
    for (final funnel in filtered) {
      test(funnel.name, () {
        try {
          simulateAndValidateFunnel(funnel);
          results[funnel.name] = _FunnelTestResult(
            passed: true,
            events: funnel.events.map((e) => e.name).toList(),
          );
        } catch (e) {
          results[funnel.name] = _FunnelTestResult(
            passed: false,
            events: funnel.events.map((e) => e.name).toList(),
            error: e.toString(),
          );
          rethrow;
        }
      });
    }

    tearDownAll(() {
      _writeReport(
        reportDir: reportDir,
        yamlName: yamlName,
        funnels: filtered,
        results: results,
      );
    });
  });
}

/// Validate a YAML funnel against already-captured events (no simulation).
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

// ─── Report Writer ───────────────────────────────────────

class _FunnelTestResult {
  final bool passed;
  final List<String> events;
  final String? error;
  _FunnelTestResult({required this.passed, required this.events, this.error});
}

void _writeReport({
  required String reportDir,
  required String yamlName,
  required List<YamlFunnelDefinition> funnels,
  required Map<String, _FunnelTestResult> results,
}) {
  try {
    final dir = Directory(reportDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final reportFile = File('$reportDir/${yamlName}_report_$timestamp.txt');

    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════════════════════');
    buf.writeln('  FUNNEL TEST REPORT');
    buf.writeln('═══════════════════════════════════════════════');
    buf.writeln('');
    buf.writeln('Source:    $yamlName.yaml');
    buf.writeln('Timestamp: $timestamp');
    buf.writeln('Funnels:   ${funnels.length}');
    buf.writeln('');

    int passed = 0;
    int failed = 0;

    for (final funnel in funnels) {
      final r = results[funnel.name];
      final status = (r?.passed ?? false) ? 'PASS' : 'FAIL';
      if (r?.passed ?? false) { passed++; } else { failed++; }

      buf.writeln('[$status] ${funnel.name}');
      buf.writeln('  Description: ${funnel.description}');
      buf.writeln('  Tags:        ${funnel.tags.join(", ")}');
      buf.writeln('  Mode:        ${funnel.mode}');
      buf.writeln('  Events:      ${funnel.events.map((e) => e.name).join(" -> ")}');

      if (r?.error != null) {
        buf.writeln('  Error:       ${r!.error}');
      }

      // Event details
      for (final event in funnel.events) {
        final props = event.properties.isNotEmpty ? ' ${event.properties}' : '';
        final desc = event.description != null ? ' — ${event.description}' : '';
        buf.writeln('    - ${event.name}$props$desc');
      }
      buf.writeln('');
    }

    buf.writeln('───────────────────────────────────────────────');
    buf.writeln('SUMMARY');
    buf.writeln('  Total:  ${funnels.length}');
    buf.writeln('  Passed: $passed');
    buf.writeln('  Failed: $failed');
    buf.writeln('  Result: ${failed == 0 ? "ALL PASSED" : "FAILURES DETECTED"}');
    buf.writeln('───────────────────────────────────────────────');
    buf.writeln('');
    buf.writeln('Report: ${reportFile.path}');

    reportFile.writeAsStringSync(buf.toString());

    // Print to console too
    // ignore: avoid_print
    print('\n${buf.toString()}');
  } catch (e) {
    // Don't fail the test if report writing fails
    // ignore: avoid_print
    print('Warning: Could not write report — $e');
  }
}
