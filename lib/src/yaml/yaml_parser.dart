import 'yaml_funnel_definition.dart';

/// Parse funnel definitions from YAML content.
/// Built-in parser — no external yaml package needed.
List<YamlFunnelDefinition> parseYamlFunnels(String yamlContent) {
  final funnels = <YamlFunnelDefinition>[];
  final lines = yamlContent.split('\n');

  int i = 0;
  while (i < lines.length && !lines[i].trimLeft().startsWith('funnels:')) {
    i++;
  }
  i++;

  while (i < lines.length) {
    final trimmed = lines[i].trimLeft();
    if (trimmed.startsWith('- name:')) {
      final result = _parseFunnel(lines, i);
      if (result != null) {
        funnels.add(result.funnel);
        i = result.nextIndex;
      } else {
        i++;
      }
    } else {
      i++;
    }
  }

  return funnels;
}

class _ParseResult {
  final YamlFunnelDefinition funnel;
  final int nextIndex;
  _ParseResult(this.funnel, this.nextIndex);
}

_ParseResult? _parseFunnel(List<String> lines, int startIndex) {
  String name = _extractValue(lines[startIndex], 'name:');
  String description = '';
  String mode = 'ordered';
  List<String> tags = [];
  List<ExpectedEvent> events = [];

  int i = startIndex + 1;

  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    final indent = line.length - line.trimLeft().length;

    if (trimmed.startsWith('- name:') && indent <= 4) break;

    if (trimmed.startsWith('description:')) {
      description = _extractValue(line, 'description:');
    } else if (trimmed.startsWith('mode:')) {
      mode = _extractValue(line, 'mode:');
    } else if (trimmed.startsWith('tags:')) {
      tags = _extractList(line, 'tags:');
    } else if (trimmed.startsWith('events:')) {
      final eventResult = _parseEvents(lines, i + 1);
      events = eventResult.events;
      i = eventResult.nextIndex;
      continue;
    }
    i++;
  }

  return _ParseResult(
    YamlFunnelDefinition(
      name: name,
      description: description,
      mode: mode,
      tags: tags,
      events: events,
    ),
    i,
  );
}

class _EventsResult {
  final List<ExpectedEvent> events;
  final int nextIndex;
  _EventsResult(this.events, this.nextIndex);
}

_EventsResult _parseEvents(List<String> lines, int startIndex) {
  final events = <ExpectedEvent>[];
  int i = startIndex;

  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    final indent = line.length - line.trimLeft().length;

    if (indent < 6 && trimmed.isNotEmpty && !trimmed.startsWith('#')) break;

    if (trimmed.startsWith('- name:')) {
      String eventName = _extractValue(line, 'name:');
      Map<String, dynamic> properties = {};
      String? desc;

      i++;
      while (i < lines.length) {
        final eLine = lines[i];
        final eTrimmed = eLine.trimLeft();
        final eIndent = eLine.length - eLine.trimLeft().length;

        // Break if we hit the next event (- name:) or exit the events block
        if (eTrimmed.startsWith('- name:') ||
            (eIndent < 8 && eTrimmed.isNotEmpty && !eTrimmed.startsWith('#'))) {
          break;
        }

        if (eTrimmed.startsWith('description:')) {
          desc = _extractValue(eLine, 'description:');
        } else if (eTrimmed.startsWith('properties:')) {
          final propsIndent = eIndent;
          i++;
          while (i < lines.length) {
            final pLine = lines[i];
            final pTrimmed = pLine.trimLeft();
            final pIndent = pLine.length - pLine.trimLeft().length;

            // Property values must be indented deeper than "properties:" key
            if (pIndent <= propsIndent &&
                pTrimmed.isNotEmpty &&
                !pTrimmed.startsWith('#')) {
              break;
            }

            if (pTrimmed.contains(':') && !pTrimmed.startsWith('#')) {
              final parts = pTrimmed.split(':');
              if (parts.length >= 2) {
                final key = parts[0].trim();
                var value = parts.sublist(1).join(':').trim();
                value = value.replaceAll('"', '').replaceAll("'", '');
                if (value == 'true') {
                  properties[key] = true;
                } else if (value == 'false') {
                  properties[key] = false;
                } else {
                  properties[key] = value;
                }
              }
            }
            i++;
          }
          continue;
        }
        i++;
      }

      events.add(ExpectedEvent(
        name: eventName,
        properties: properties,
        description: desc,
      ));
      continue;
    }
    i++;
  }

  return _EventsResult(events, i);
}

String _extractValue(String line, String key) {
  final idx = line.indexOf(key);
  if (idx == -1) return '';
  var value = line.substring(idx + key.length).trim();
  value = value.replaceAll('"', '').replaceAll("'", '');
  return value;
}

List<String> _extractList(String line, String key) {
  final idx = line.indexOf(key);
  if (idx == -1) return [];
  var value = line.substring(idx + key.length).trim();
  value = value.replaceAll('[', '').replaceAll(']', '');
  return value
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
