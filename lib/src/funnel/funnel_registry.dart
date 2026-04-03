import 'funnel_definition.dart';
import 'funnel_result.dart';

/// Registry for discovering and batch-executing funnels.
class FunnelRegistry {
  static final List<FunnelDefinition> _funnels = [];

  static void register(FunnelDefinition funnel) => _funnels.add(funnel);

  static List<FunnelDefinition> getAll() => List.unmodifiable(_funnels);

  static List<FunnelDefinition> getByTag(String tag) =>
      _funnels.where((f) => f.tags.contains(tag)).toList();

  static FunnelDefinition? getByName(String name) {
    for (final f in _funnels) {
      if (f.name == name) return f;
    }
    return null;
  }

  static void clear() => _funnels.clear();

  /// Run all registered funnels.
  static Future<List<FunnelResult>> runAll() async {
    final results = <FunnelResult>[];
    for (final funnel in _funnels) {
      results.add(await funnel.run());
    }
    return results;
  }

  /// Run funnels matching a tag.
  static Future<List<FunnelResult>> runByTag(String tag) async {
    final results = <FunnelResult>[];
    for (final funnel in getByTag(tag)) {
      results.add(await funnel.run());
    }
    return results;
  }

  /// Generate a formatted report.
  static String generateReport(List<FunnelResult> results) {
    final buf = StringBuffer();
    buf.writeln('\n====== FUNNEL TEST REPORT ======\n');

    int totalSteps = 0, totalPassed = 0, totalFailed = 0;

    for (final result in results) {
      buf.writeln(result.detailedReport);
      totalSteps += result.totalSteps;
      totalPassed += result.passedCount;
      totalFailed += result.failedCount;
    }

    buf.writeln('---------------------------------------------------');
    buf.writeln('SUMMARY');
    buf.writeln('  Funnels tested: ${results.length}');
    buf.writeln('  Total steps:    $totalSteps');
    buf.writeln('  Passed:         $totalPassed');
    buf.writeln('  Failed:         $totalFailed');
    buf.writeln('  Pass rate:      '
        '${totalSteps > 0 ? (totalPassed / totalSteps * 100).toStringAsFixed(1) : 0}%');

    final allPassed = results.every((r) => r.allPassed);
    buf.writeln(
        '\n  Overall: ${allPassed ? "ALL FUNNELS PASSED" : "FAILURES DETECTED"}');
    return buf.toString();
  }
}
