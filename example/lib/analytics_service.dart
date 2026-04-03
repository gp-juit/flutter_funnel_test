import 'package:funnelwise/funnelwise.dart';

/// Example: wiring TestableAnalytics into your analytics service.
///
/// This works with ANY analytics SDK — Mixpanel, Firebase Analytics,
/// Amplitude, PostHog, Segment, or a custom backend.
class MyAnalyticsService {
  /// Track an event. The 3-line TestableAnalytics check is all you need.
  static void track(String event, [Map<String, dynamic>? props]) {
    // This line enables funnel testing on device
    if (TestableAnalytics.isEnabled) {
      TestableAnalytics.capture(event, props);
    }

    // Your real analytics SDK call goes here:
    // _mixpanel.track(event, properties: props);
    // _firebaseAnalytics.logEvent(name: event, parameters: props);
    // _amplitude.logEvent(event, eventProperties: props);
  }
}
