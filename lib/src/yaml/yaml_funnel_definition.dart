/// A funnel definition parsed from YAML.
class YamlFunnelDefinition {
  final String name;
  final String description;
  final String mode; // "ordered" or "strict"
  final List<String> tags;
  final List<ExpectedEvent> events;

  YamlFunnelDefinition({
    required this.name,
    required this.description,
    required this.mode,
    required this.tags,
    required this.events,
  });
}

/// A single expected analytics event in a YAML funnel.
class ExpectedEvent {
  final String name;
  final Map<String, dynamic> properties;
  final String? description;

  ExpectedEvent({
    required this.name,
    this.properties = const {},
    this.description,
  });
}
