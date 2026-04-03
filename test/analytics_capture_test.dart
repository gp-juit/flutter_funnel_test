import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

void main() {
  setUp(() => AnalyticsCapture.reset());

  group('AnalyticsCapture', () {
    test('tracks events', () {
      AnalyticsCapture.track('page_view');
      AnalyticsCapture.track('button_click', {'id': 'submit'});

      expect(AnalyticsCapture.count, 2);
      expect(AnalyticsCapture.hasEvent('page_view'), isTrue);
      expect(AnalyticsCapture.hasEvent('nonexistent'), isFalse);
    });

    test('tracks event properties', () {
      AnalyticsCapture.track('login', {'method': 'google', 'success': true});

      expect(
        AnalyticsCapture.hasEventWithProperties('login', {'method': 'google'}),
        isTrue,
      );
      expect(
        AnalyticsCapture.hasEventWithProperties('login', {'method': 'apple'}),
        isFalse,
      );
    });

    test('assertFunnel validates ordered events', () {
      AnalyticsCapture.track('splash');
      AnalyticsCapture.track('login_view');
      AnalyticsCapture.track('other_event');
      AnalyticsCapture.track('login_success');

      final result = AnalyticsCapture.assertFunnel([
        'splash',
        'login_view',
        'login_success',
      ]);

      expect(result.passed, isTrue);
    });

    test('assertFunnel detects missing events', () {
      AnalyticsCapture.track('splash');

      final result = AnalyticsCapture.assertFunnel([
        'splash',
        'login_view',
        'login_success',
      ]);

      expect(result.passed, isFalse);
      expect(result.missingEvents, contains('login_view'));
      expect(result.missingEvents, contains('login_success'));
    });

    test('assertFunnel detects out-of-order events', () {
      AnalyticsCapture.track('login_success');
      AnalyticsCapture.track('splash');

      final result = AnalyticsCapture.assertFunnel([
        'splash',
        'login_success',
      ]);

      expect(result.passed, isFalse);
      expect(result.outOfOrderEvents, contains('login_success'));
    });

    test('assertStrictFunnel rejects extra events', () {
      AnalyticsCapture.track('splash');
      AnalyticsCapture.track('login');
      AnalyticsCapture.track('extra');

      final result = AnalyticsCapture.assertStrictFunnel([
        'splash',
        'login',
      ]);

      expect(result.extraEvents, contains('extra'));
    });

    test('reset clears all events', () {
      AnalyticsCapture.track('event1');
      AnalyticsCapture.track('event2');
      expect(AnalyticsCapture.count, 2);

      AnalyticsCapture.reset();
      expect(AnalyticsCapture.count, 0);
    });

    test('dump produces readable output', () {
      AnalyticsCapture.track('login', {'method': 'phone'});
      final output = AnalyticsCapture.dump();

      expect(output, contains('login'));
      expect(output, contains('method'));
    });
  });
}
