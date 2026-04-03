# YAML Schemas

## Analytics Funnel (logic tests, no device)

```yaml
funnels:
  - name: "Funnel Name"
    description: "What it tests"
    mode: ordered          # ordered | strict
    tags: [tag1, tag2]
    events:
      - name: event_name
        properties:
          key: value
        description: "What triggers this"
```

## Device Funnel (UI tests on emulator)

```yaml
device_funnels:
  - name: "Funnel Name"
    description: "What it tests"
    start_route: /
    tags: [tag1]
    steps:
      - name: "Step name"
        action: tap_nav | tap_button | tap_text | type | scroll_down | scroll_up | wait | screenshot
        target: "Label or hint"
        value: "Text to type"
        expect_event: analytics_event_name
        expect_text: "Text to assert visible"
        screenshot: label_for_screenshot
```

## Actions Reference

| action | target | value | What it does |
|--------|--------|-------|-------------|
| tap_nav | "Tab Label" | — | Tap bottom nav item by label |
| tap_button | "Button Text" | — | Tap ElevatedButton by label |
| tap_text | "Any text" | — | Tap any widget with this text |
| type | "TextField" or hint | "text" | Type into field |
| scroll_down | — | — | Scroll page down |
| scroll_up | — | — | Scroll page up |
| wait | — | "2000" | Wait N milliseconds |
| screenshot | — | — | Take screenshot only |
