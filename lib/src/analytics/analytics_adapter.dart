/// Abstract contract for analytics providers.
///
/// Implement this for your analytics SDK (Mixpanel, Firebase Analytics,
/// Amplitude, PostHog, Segment, or any custom provider).
///
/// Example for Mixpanel:
/// ```dart
/// class MixpanelAdapter extends AnalyticsAdapter {
///   @override
///   void trackEvent(String eventName, [Map<String, dynamic>? properties]) {
///     if (TestableAnalytics.isEnabled) {
///       TestableAnalytics.capture(eventName, properties);
///     }
///     mixpanel.track(eventName, properties: properties);
///   }
/// }
/// ```
abstract class AnalyticsAdapter {
  /// Track a named event with optional properties.
  void trackEvent(String eventName, [Map<String, dynamic>? properties]);

  /// Identify a user by unique ID. Override if your provider supports it.
  void identify(String userId) {}

  /// Reset identity (e.g. on logout). Override if your provider supports it.
  void reset() {}
}
