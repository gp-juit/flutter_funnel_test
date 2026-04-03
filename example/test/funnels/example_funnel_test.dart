import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:funnelwise/funnelwise.dart';

void main() {
  late List<YamlFunnelDefinition> funnels;

  setUpAll(() {
    final yamlFile = File('test/funnels/example_funnels.yaml');
    funnels = parseYamlFunnels(yamlFile.readAsStringSync());
  });

  group('YAML Funnel Loading', () {
    test('parses all funnels from YAML', () {
      expect(funnels.length, 4);
      for (final f in funnels) {
        // ignore: avoid_print
        print('  - ${f.name} (${f.events.length} events) [${f.tags.join(", ")}]');
      }
    });
  });

  group('Auth Funnels', () {
    test('User Signup funnel validates', () {
      final funnel = funnels.firstWhere((f) => f.name == 'User Signup');
      simulateAndValidateFunnel(funnel);
    });

    test('User Login funnel validates', () {
      final funnel = funnels.firstWhere((f) => f.name == 'User Login');
      simulateAndValidateFunnel(funnel);
    });
  });

  group('Ecommerce Funnels', () {
    test('Add to Cart funnel validates', () {
      final funnel = funnels.firstWhere((f) => f.name == 'Add to Cart');
      simulateAndValidateFunnel(funnel);
    });

    test('Checkout funnel validates', () {
      final funnel = funnels.firstWhere((f) => f.name == 'Checkout');
      simulateAndValidateFunnel(funnel);
    });
  });

  group('Programmatic Funnel', () {
    test('define and run a funnel in code', () async {
      final funnel = FunnelDefinition(
        name: 'Onboarding',
        description: 'User completes onboarding flow',
        tags: ['onboarding'],
        steps: [
          FunnelStep(
            name: 'Welcome screen',
            description: 'User sees welcome',
            action: () async {},
            assertions: () async => {'screen': 'welcome'},
          ),
          FunnelStep(
            name: 'Select interests',
            description: 'User picks topics',
            action: () async {},
            assertions: () async => {'interests': 3},
          ),
          FunnelStep(
            name: 'Complete',
            description: 'Onboarding done',
            action: () async {},
            assertions: () async => {'completed': true},
          ),
        ],
      );

      final result = await funnel.run();
      // ignore: avoid_print
      print(result.detailedReport);
      expect(result.allPassed, isTrue);
    });
  });

  group('Coverage Report', () {
    test('shows analytics coverage', () {
      final allEvents = [
        'signup_screen_view', 'email_entered', 'password_entered',
        'signup_button_click', 'signup_success',
        'login_screen_view', 'login_button_click', 'login_success',
        'product_list_view', 'product_card_click', 'product_detail_view',
        'add_to_cart_click', 'cart_view', 'checkout_start',
        'payment_method_selected', 'payment_success',
        'order_confirmation_view',
        'profile_view', 'settings_view', 'logout_click', // uncovered
      ];

      final report = FunnelReport.coverageReport(
        allEvents: allEvents,
        funnels: funnels,
      );
      // ignore: avoid_print
      print(report);

      // At least 50% coverage
      final covered = <String>{};
      for (final f in funnels) {
        for (final e in f.events) {
          covered.add(e.name);
        }
      }
      expect(covered.length, greaterThan(allEvents.length ~/ 2));
    });
  });
}
