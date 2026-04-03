/// Metadata for a captured screenshot during a funnel step.
class StepScreenshot {
  final int index;
  final String label;
  final String filename;

  const StepScreenshot({
    required this.index,
    required this.label,
    required this.filename,
  });
}
