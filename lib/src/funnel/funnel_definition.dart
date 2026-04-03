import 'funnel_result.dart';

/// A single step within a funnel test.
class FunnelStep {
  final String name;
  final String description;
  final Future<void> Function()? precondition;
  final Future<void> Function() action;
  final Future<Map<String, dynamic>> Function() assertions;

  FunnelStep({
    required this.name,
    required this.description,
    this.precondition,
    required this.action,
    required this.assertions,
  });
}

/// A complete funnel — a sequence of steps representing a user journey.
class FunnelDefinition {
  final String name;
  final String description;
  final List<String> tags;
  final List<FunnelStep> steps;
  final Future<void> Function()? setup;
  final Future<void> Function()? teardown;

  FunnelDefinition({
    required this.name,
    required this.description,
    this.tags = const [],
    required this.steps,
    this.setup,
    this.teardown,
  });

  /// Run all steps in sequence, collecting results.
  Future<FunnelResult> run() async {
    final funnelStart = DateTime.now();
    final results = <StepResult>[];

    if (setup != null) await setup!();

    for (final step in steps) {
      final stepStart = DateTime.now();
      try {
        if (step.precondition != null) await step.precondition!();
        await step.action();
        final stateSnapshot = await step.assertions();

        results.add(StepResult(
          stepName: step.name,
          passed: true,
          duration: DateTime.now().difference(stepStart),
          stateSnapshot: stateSnapshot,
        ));
      } catch (e) {
        results.add(StepResult(
          stepName: step.name,
          passed: false,
          errorMessage: e.toString(),
          duration: DateTime.now().difference(stepStart),
        ));
      }
    }

    if (teardown != null) await teardown!();

    return FunnelResult(
      funnelName: name,
      funnelDescription: description,
      stepResults: results,
      totalDuration: DateTime.now().difference(funnelStart),
    );
  }
}
