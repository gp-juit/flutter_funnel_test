import '../analytics/funnel_validation_result.dart';
import '../funnel/funnel_result.dart';
import '../yaml/yaml_funnel_definition.dart';

/// Generates formatted reports for funnel test results.
class FunnelReport {
  /// Generate a coverage report showing which analytics events
  /// are covered by funnel definitions.
  static String coverageReport({
    required List<String> allEvents,
    required List<YamlFunnelDefinition> funnels,
  }) {
    final coveredEvents = <String>{};
    for (final funnel in funnels) {
      for (final event in funnel.events) {
        coveredEvents.add(event.name);
      }
    }

    final uncovered =
        allEvents.where((e) => !coveredEvents.contains(e)).toList();

    final buf = StringBuffer();
    buf.writeln('\n=== Analytics Event Coverage ===');
    buf.writeln('Total events:    ${allEvents.length}');
    buf.writeln('Covered:         ${coveredEvents.length}');
    buf.writeln('Uncovered:       ${uncovered.length}');
    buf.writeln('Coverage:        '
        '${(coveredEvents.length / allEvents.length * 100).toStringAsFixed(1)}%');

    if (uncovered.isNotEmpty) {
      buf.writeln('\nUncovered events:');
      for (final e in uncovered) {
        buf.writeln('  - $e');
      }
    }

    return buf.toString();
  }

  /// Generate a report from YAML funnel validation results.
  static String fromValidationResults(
      Map<String, bool> results, List<YamlFunnelDefinition> funnels) {
    final buf = StringBuffer();
    buf.writeln('\n=== Custom Funnel Results ===');
    for (final entry in results.entries) {
      final icon = entry.value ? 'PASS' : 'FAIL';
      buf.writeln('  [$icon] ${entry.key}');
    }

    final failCount = results.values.where((v) => !v).length;
    buf.writeln('\nTotal: ${results.length} | '
        'Passed: ${results.length - failCount} | '
        'Failed: $failCount');
    return buf.toString();
  }

  /// Generate a report from programmatic FunnelResults.
  static String fromFunnelResults(List<FunnelResult> results) {
    final buf = StringBuffer();
    buf.writeln('\n=== Funnel Test Results ===');
    for (final result in results) {
      buf.writeln(result.summary);
    }

    final allPassed = results.every((r) => r.allPassed);
    buf.writeln(
        '\nOverall: ${allPassed ? "ALL PASSED" : "FAILURES DETECTED"}');
    return buf.toString();
  }
}
