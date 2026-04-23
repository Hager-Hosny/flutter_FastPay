import '../utils/json_utils.dart';

class PageResult<T> {
  const PageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.rawData = const <String, dynamic>{},
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final Map<String, dynamic> rawData;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final List<dynamic> rawContent = json['content'] is List
        ? json['content'] as List<dynamic>
        : const <dynamic>[];

    return PageResult<T>(
      content: rawContent
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => itemParser(
              item.map(
                (dynamic key, dynamic value) =>
                    MapEntry(key.toString(), value),
              ),
            ),
          )
          .toList(),
      page: asInt(json['page']) ?? 0,
      size: asInt(json['size']) ?? 0,
      totalElements: asInt(json['total_elements']) ?? 0,
      totalPages: asInt(json['total_pages']) ?? 0,
      rawData: json,
    );
  }
}
