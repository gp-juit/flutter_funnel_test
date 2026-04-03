---
description: List all analytics events available for funnel testing
allowed-tools: Read, Grep, Glob
---

Find and display all analytics events defined in this Flutter app.

## Step 1: Find the events file

```bash
grep -rl "enum.*Event" lib/ --include="*.dart"
```

Or search for common patterns:
```bash
grep -rl "MixpanelEvent\|AnalyticsEvent\|AppEvent" lib/ --include="*.dart"
```

## Step 2: Extract event names

Read the events file and extract all event name strings (the snake_case return values).

## Step 3: Group and display

Print them grouped by category (based on comments in the file), like:

```
Available Analytics Events for Funnel Testing
══════════════════════════════════════════════

Auth:
  signup_screen_view
  login_screen_view
  login_success
  ...

Navigation:
  nav_home_click
  nav_settings_click
  nav_profile_click
  ...

Usage:
  /test-funnel signup: signup_screen_view -> email_entered -> signup_success
  /test-funnel checkout: cart_view -> checkout_start -> payment_success
```
