import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../analytics/testable_analytics.dart';
import '../yaml/yaml_funnel_definition.dart';
import '../yaml/yaml_parser.dart';
import 'funnel_tester.dart';

/// Run device tests from YAML — zero Dart code needed by the PM.
///
/// YAML format:
/// ```yaml
/// device_funnels:
///   - name: "QARA Chat"
///     description: "User chats with QARA"
///     start_route: /
///     steps:
///       - name: "Tap QARA tab"
///         action: tap_nav
///         target: "QARA"
///         expect_event: nav_qara_click
///         screenshot: qara_screen
///       - name: "Type message"
///         action: type
///         target: TextField
///         value: "My baby cries at night"
///         screenshot: qara_typed
/// ```
///
/// Test file (only code needed):
/// ```dart
/// void main() {
///   runDeviceFunnels(
///     yamlPath: 'test/funnels/qara_device.yaml',
///     appBuilder: () => createTestApp(),
///   );
/// }
/// ```
void runDeviceFunnels({
  required String yamlPath,
  required Future<Widget> Function({String? initialRoute}) appBuilder,
  String? tag,
}) {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final file = File(yamlPath);
  final funnels = parseDeviceFunnels(file.readAsStringSync());

  final filtered = tag != null
      ? funnels.where((f) => f.tags.contains(tag)).toList()
      : funnels;

  final yamlName = yamlPath.split('/').last.replaceAll('.yaml', '');

  group('Device: $yamlName', () {
    for (final funnel in filtered) {
      testWidgets(funnel.name, (tester) async {
        TestableAnalytics.enable();
        final ft = FunnelTester(tester, binding);

        final app = await appBuilder(initialRoute: funnel.startRoute);
        await tester.pumpWidget(app);
        await ft.settle(timeout: const Duration(seconds: 15));

        for (final step in funnel.steps) {
          await _executeStep(ft, tester, step);
        }

        ft.dumpAnalytics();
        ft.printReport(funnel.name);
      });
    }
  });
}

Future<void> _executeStep(
  FunnelTester ft,
  WidgetTester tester,
  UiStep step,
) async {
  // ignore: avoid_print
  print('  Step: ${step.name}');

  switch (step.action) {
    case 'tap_nav':
      // Tap a bottom navigation item by label
      final finder = find.text(step.target ?? '');
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder.last); // .last = bottom nav, not homepage card
        await ft.settle();
      }
      break;

    case 'tap_button':
      // Tap an ElevatedButton by label
      final finder = find.widgetWithText(ElevatedButton, step.target ?? '');
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder.first);
        await ft.settle();
      }
      break;

    case 'tap_text':
      // Tap any widget containing this text
      final finder = find.text(step.target ?? '');
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder.first);
        await ft.settle();
      }
      break;

    case 'type':
      // Type text into a field. target = hint text or "TextField" for first field
      if (step.target == 'TextField' || step.target == 'TextFormField') {
        final finder = find.byType(TextField);
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first);
          await tester.pump();
          await tester.enterText(finder.first, step.value ?? '');
          await tester.pump();
        }
      } else {
        await ft.typeByHint(step.target ?? '', step.value ?? '');
      }
      break;

    case 'scroll_down':
      await ft.scrollDown();
      break;

    case 'scroll_up':
      await ft.scrollUp();
      break;

    case 'wait':
      final ms = int.tryParse(step.value ?? '1000') ?? 1000;
      await ft.wait(Duration(milliseconds: ms));
      await ft.settle();
      break;

    case 'screenshot':
      // Just take a screenshot, no other action
      break;

    default:
      // Unknown action — skip
      break;
  }

  // Take screenshot if specified
  if (step.screenshot != null) {
    await ft.screenshot(step.screenshot!);
  }

  // Assert analytics event
  if (step.expectEvent != null) {
    ft.expectEvent(step.expectEvent!);
  }

  // Assert visible text
  if (step.expectText != null) {
    ft.expectVisible(step.expectText!);
  }
}
