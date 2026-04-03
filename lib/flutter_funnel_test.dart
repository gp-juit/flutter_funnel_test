/// Flutter Funnel Test — a generic framework for testing UI, business logic,
/// and analytics across user funnels in any Flutter app.
///
/// Import this for unit tests (no device needed):
/// ```dart
/// import 'package:flutter_funnel_test/flutter_funnel_test.dart';
/// ```
///
/// For integration tests on emulator, also import:
/// ```dart
/// import 'package:flutter_funnel_test/flutter_funnel_test_integration.dart';
/// ```
library flutter_funnel_test;

// Analytics
export 'src/analytics/analytics_adapter.dart' show AnalyticsAdapter;
export 'src/analytics/analytics_capture.dart' show AnalyticsCapture;
export 'src/analytics/testable_analytics.dart' show TestableAnalytics;
export 'src/analytics/funnel_validation_result.dart'
    show FunnelValidationResult, CapturedEvent;

// Funnel framework
export 'src/funnel/funnel_definition.dart' show FunnelDefinition, FunnelStep;
export 'src/funnel/funnel_result.dart' show FunnelResult, StepResult;
export 'src/funnel/funnel_registry.dart' show FunnelRegistry;

// YAML funnels
export 'src/yaml/yaml_parser.dart' show parseYamlFunnels;
export 'src/yaml/yaml_funnel_definition.dart'
    show YamlFunnelDefinition, ExpectedEvent;
export 'src/yaml/yaml_funnel_validator.dart'
    show simulateAndValidateFunnel, validateFunnelAgainstCapture;

// Report
export 'src/report/funnel_report.dart' show FunnelReport;
