/// Flutter Funnel Test — integration test helpers.
///
/// Import this in files under `integration_test/`:
/// ```dart
/// import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';
/// ```
///
/// Requires a running emulator or device.
library flutter_funnel_test_integration;

// Re-export the core library
export 'flutter_funnel_test.dart';

// Integration-specific
export 'src/integration/funnel_tester.dart' show FunnelTester;
export 'src/integration/step_screenshot.dart' show StepScreenshot;
