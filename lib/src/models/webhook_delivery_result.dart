import '../utils/json_utils.dart';

class WebhookDeliveryResult {
  const WebhookDeliveryResult({
    this.logId,
    this.webhookEndpointId,
    this.endpointUrl,
    this.eventId,
    this.eventType,
    this.delivered,
    this.httpStatus,
    this.attemptNumber,
    this.maxAttempts,
    this.errorMessage,
    this.sentAt,
    this.rawData = const <String, dynamic>{},
  });

  final int? logId;
  final int? webhookEndpointId;
  final String? endpointUrl;
  final String? eventId;
  final String? eventType;
  final bool? delivered;
  final int? httpStatus;
  final int? attemptNumber;
  final int? maxAttempts;
  final String? errorMessage;
  final String? sentAt;
  final Map<String, dynamic> rawData;

  factory WebhookDeliveryResult.fromJson(Map<String, dynamic> json) {
    return WebhookDeliveryResult(
      logId: asInt(json['log_id']),
      webhookEndpointId: asInt(json['webhook_endpoint_id']),
      endpointUrl: asString(json['endpoint_url']),
      eventId: asString(json['event_id']),
      eventType: asString(json['event_type']),
      delivered: asBool(json['delivered']),
      httpStatus: asInt(json['http_status']),
      attemptNumber: asInt(json['attempt_number']),
      maxAttempts: asInt(json['max_attempts']),
      errorMessage: asString(json['error_message']),
      sentAt: asString(json['sent_at']),
      rawData: json,
    );
  }
}
