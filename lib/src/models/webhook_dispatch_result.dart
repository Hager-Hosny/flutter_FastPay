import '../utils/json_utils.dart';

class WebhookDispatchResult {
  const WebhookDispatchResult({
    this.eventId,
    this.matchedEndpoints,
    this.enqueuedJobs,
    this.logIds = const <int>[],
    this.rawData = const <String, dynamic>{},
  });

  final String? eventId;
  final int? matchedEndpoints;
  final int? enqueuedJobs;
  final List<int> logIds;
  final Map<String, dynamic> rawData;

  factory WebhookDispatchResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawLogIds = json['log_ids'] is List
        ? json['log_ids'] as List<dynamic>
        : const <dynamic>[];
    return WebhookDispatchResult(
      eventId: asString(json['event_id']),
      matchedEndpoints: asInt(json['matched_endpoints']),
      enqueuedJobs: asInt(json['enqueued_jobs']),
      logIds: rawLogIds.map(asInt).whereType<int>().toList(),
      rawData: json,
    );
  }
}
