import 'package:flutter_test/flutter_test.dart';
import 'package:funnelwise/funnelwise.dart';

void main() {
  group('FunnelDefinition', () {
    test('runs steps and collects results', () async {
      final funnel = FunnelDefinition(
        name: 'Test Funnel',
        description: 'A test',
        steps: [
          FunnelStep(
            name: 'Step 1',
            description: 'First step',
            action: () async {},
            assertions: () async => {'done': true},
          ),
          FunnelStep(
            name: 'Step 2',
            description: 'Second step',
            action: () async {},
            assertions: () async => {'value': 42},
          ),
        ],
      );

      final result = await funnel.run();
      expect(result.allPassed, isTrue);
      expect(result.totalSteps, 2);
      expect(result.passedCount, 2);
      expect(result.failedCount, 0);
    });

    test('captures failed steps', () async {
      final funnel = FunnelDefinition(
        name: 'Failing Funnel',
        description: 'Has a failure',
        steps: [
          FunnelStep(
            name: 'Pass',
            description: 'This passes',
            action: () async {},
            assertions: () async => {},
          ),
          FunnelStep(
            name: 'Fail',
            description: 'This fails',
            action: () async {
              throw Exception('Intentional failure');
            },
            assertions: () async => {},
          ),
        ],
      );

      final result = await funnel.run();
      expect(result.allPassed, isFalse);
      expect(result.passedCount, 1);
      expect(result.failedCount, 1);
      expect(result.stepResults[1].errorMessage, contains('Intentional'));
    });

    test('detailedReport contains funnel name', () async {
      final funnel = FunnelDefinition(
        name: 'Report Test',
        description: 'Test report',
        steps: [
          FunnelStep(
            name: 'Only Step',
            description: 'Only',
            action: () async {},
            assertions: () async => {},
          ),
        ],
      );

      final result = await funnel.run();
      expect(result.detailedReport, contains('Report Test'));
    });
  });

  group('FunnelRegistry', () {
    setUp(() => FunnelRegistry.clear());

    test('registers and retrieves funnels', () {
      FunnelRegistry.register(FunnelDefinition(
        name: 'A',
        description: 'Funnel A',
        tags: ['tag1'],
        steps: [],
      ));
      FunnelRegistry.register(FunnelDefinition(
        name: 'B',
        description: 'Funnel B',
        tags: ['tag2'],
        steps: [],
      ));

      expect(FunnelRegistry.getAll().length, 2);
      expect(FunnelRegistry.getByName('A')?.name, 'A');
      expect(FunnelRegistry.getByTag('tag1').length, 1);
    });

    test('runAll executes all funnels', () async {
      FunnelRegistry.register(FunnelDefinition(
        name: 'Quick',
        description: 'Quick test',
        steps: [
          FunnelStep(
            name: 'S1',
            description: 'd',
            action: () async {},
            assertions: () async => {},
          ),
        ],
      ));

      final results = await FunnelRegistry.runAll();
      expect(results.length, 1);
      expect(results[0].allPassed, isTrue);
    });
  });
}
