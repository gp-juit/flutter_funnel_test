/// Result of running a single funnel step.
class StepResult {
  final String stepName;
  final bool passed;
  final String? errorMessage;
  final Duration duration;
  final Map<String, dynamic> stateSnapshot;

  StepResult({
    required this.stepName,
    required this.passed,
    this.errorMessage,
    required this.duration,
    this.stateSnapshot = const {},
  });

  @override
  String toString() {
    final status = passed ? 'PASS' : 'FAIL';
    final error = errorMessage != null ? ' — $errorMessage' : '';
    return '[$status] $stepName (${duration.inMilliseconds}ms)$error';
  }
}

/// Result of running an entire funnel.
class FunnelResult {
  final String funnelName;
  final String funnelDescription;
  final List<StepResult> stepResults;
  final Duration totalDuration;

  FunnelResult({
    required this.funnelName,
    required this.funnelDescription,
    required this.stepResults,
    required this.totalDuration,
  });

  bool get allPassed => stepResults.every((s) => s.passed);
  int get passedCount => stepResults.where((s) => s.passed).length;
  int get failedCount => stepResults.where((s) => !s.passed).length;
  int get totalSteps => stepResults.length;

  String get summary {
    final status = allPassed ? 'PASS' : 'FAIL';
    return '[$status] $funnelName: $passedCount/$totalSteps steps passed '
        '(${totalDuration.inMilliseconds}ms)';
  }

  String get detailedReport {
    final buf = StringBuffer();
    buf.writeln('===================================================');
    buf.writeln('Funnel: $funnelName');
    buf.writeln('Description: $funnelDescription');
    buf.writeln('Status: ${allPassed ? "ALL PASSED" : "FAILURES DETECTED"}');
    buf.writeln('Steps: $passedCount/$totalSteps passed');
    buf.writeln('Duration: ${totalDuration.inMilliseconds}ms');
    buf.writeln('---------------------------------------------------');
    for (final step in stepResults) {
      buf.writeln('  $step');
      if (step.stateSnapshot.isNotEmpty) {
        buf.writeln('    State: ${step.stateSnapshot}');
      }
    }
    buf.writeln('===================================================');
    return buf.toString();
  }
}
