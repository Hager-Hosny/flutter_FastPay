import '../utils/json_utils.dart';

class TransactionsSummary {
  const TransactionsSummary({
    this.currency,
    this.totalTransactions,
    this.completedCount,
    this.failedCount,
    this.totalCompletedAmount,
    this.totalFailedAmount,
    this.rawData = const <String, dynamic>{},
  });

  final String? currency;
  final int? totalTransactions;
  final int? completedCount;
  final int? failedCount;
  final String? totalCompletedAmount;
  final String? totalFailedAmount;
  final Map<String, dynamic> rawData;

  factory TransactionsSummary.fromJson(Map<String, dynamic> json) {
    return TransactionsSummary(
      currency: asString(json['currency']),
      totalTransactions: asInt(json['total_transactions']),
      completedCount: asInt(json['completed_count']),
      failedCount: asInt(json['failed_count']),
      totalCompletedAmount: asString(json['total_completed_amount']),
      totalFailedAmount: asString(json['total_failed_amount']),
      rawData: json,
    );
  }
}
