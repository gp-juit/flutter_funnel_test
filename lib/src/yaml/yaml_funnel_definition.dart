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

/// A UI step parsed from YAML for device testing.
class UiStep {
  final String name;
  final String action; // tap_nav, tap_button, type, scroll_down, wait, screenshot
  final String? target; // text label, hint, key
  final String? value;  // text to type
  final String? expectEvent; // analytics event to assert
  final String? expectText;  // text to assert visible
  final String? screenshot;  // screenshot label

  UiStep({
    required this.name,
    required this.action,
    this.target,
    this.value,
    this.expectEvent,
    this.expectText,
    this.screenshot,
  });
}

/// A device funnel parsed from YAML.
class YamlDeviceFunnel {
  final String name;
  final String description;
  final String? startRoute;
  final List<String> tags;
  final List<UiStep> steps;

  YamlDeviceFunnel({
    required this.name,
    required this.description,
    this.startRoute,
    this.tags = const [],
    required this.steps,
  });
}
