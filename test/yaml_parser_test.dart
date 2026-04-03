import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_funnel_test/flutter_funnel_test.dart';

void main() {
  const sampleYaml = '''
funnels:
  - name: "Test Funnel"
    description: "A test funnel"
    mode: ordered
    tags: [test, critical]
    events:
      - name: event_one
        description: "First event"
      - name: event_two
        properties:
          key1: value1
          key2: true
        description: "Second event with properties"
      - name: event_three

  - name: "Strict Funnel"
    description: "Exact match"
    mode: strict
    tags: [test]
    events:
      - name: only_event
''';

  group('YAML Parser', () {
    test('parses funnels from YAML', () {
      final funnels = parseYamlFunnels(sampleYaml);
      expect(funnels.length, 2);
    });

    test('parses funnel name and description', () {
      final funnels = parseYamlFunnels(sampleYaml);
      expect(funnels[0].name, 'Test Funnel');
      expect(funnels[0].description, 'A test funnel');
    });

    test('parses mode', () {
      final funnels = parseYamlFunnels(sampleYaml);
      expect(funnels[0].mode, 'ordered');
      expect(funnels[1].mode, 'strict');
    });

    test('parses tags', () {
      final funnels = parseYamlFunnels(sampleYaml);
      expect(funnels[0].tags, ['test', 'critical']);
      expect(funnels[1].tags, ['test']);
    });

    test('parses events', () {
      final funnels = parseYamlFunnels(sampleYaml);
      expect(funnels[0].events.length, 3);
      expect(funnels[0].events[0].name, 'event_one');
      expect(funnels[0].events[1].name, 'event_two');
      expect(funnels[0].events[2].name, 'event_three');
    });

    test('parses event properties', () {
      final funnels = parseYamlFunnels(sampleYaml);
      final event = funnels[0].events[1];
      expect(event.properties['key1'], 'value1');
      expect(event.properties['key2'], true);
    });

    test('parses event descriptions', () {
      final funnels = parseYamlFunnels(sampleYaml);
      expect(funnels[0].events[0].description, 'First event');
      expect(funnels[0].events[1].description, 'Second event with properties');
    });

    test('handles single-event funnel', () {
      final funnels = parseYamlFunnels(sampleYaml);
      expect(funnels[1].events.length, 1);
      expect(funnels[1].events[0].name, 'only_event');
    });
  });

  group('YAML Funnel Validator', () {
    test('simulateAndValidateFunnel passes for valid funnel', () {
      final funnels = parseYamlFunnels(sampleYaml);
      simulateAndValidateFunnel(funnels[0]);
    });

    test('simulateAndValidateFunnel passes for strict funnel', () {
      final funnels = parseYamlFunnels(sampleYaml);
      simulateAndValidateFunnel(funnels[1]);
    });
  });
}
