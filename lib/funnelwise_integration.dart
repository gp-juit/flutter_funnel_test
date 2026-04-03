/// Flutter Funnel Test — integration test helpers.
///
/// Import this in files under `integration_test/`:
/// ```dart
/// import 'package:funnelwise/funnelwise_integration.dart';
/// ```
///
/// Requires a running emulator or device.
library funnelwise_integration;

// Re-export the core library
export 'funnelwise.dart';

// Integration-specific
export 'src/integration/funnel_tester.dart' show FunnelTester;
export 'src/integration/step_screenshot.dart' show StepScreenshot;
export 'src/integration/yaml_device_runner.dart' show runDeviceFunnels;
