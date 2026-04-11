Map<String, dynamic>? asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (Object? key, Object? item) => MapEntry(key.toString(), item),
    );
  }

  return null;
}

Map<String, String> asStringMap(Map<String, dynamic>? value) {
  if (value == null) {
    return const <String, String>{};
  }

  return value.map(
    (String key, dynamic item) => MapEntry(key, item?.toString() ?? ''),
  );
}

String? asString(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  return value.toString();
}

double? asDouble(Object? value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

int? asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

bool? asBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }

  if (value is num) {
    return value != 0;
  }

  return null;
}
