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

Login & Onboarding:
  login_splash_view
  login_screen_view
  phone_input_click
  phone_continue_click
  otp_input_click
  otp_verify_click
  otp_validation
  login_successful
  ...

Navigation:
  nav_home_click
  nav_foryou_click
  nav_cry_click
  nav_qara_click
  ...

Usage:
  /test-funnel QARA chat: nav_qara_click -> qara_message_send_click
  /test-funnel login: login_screen_view -> phone_continue_click -> otp_verify_click
```
