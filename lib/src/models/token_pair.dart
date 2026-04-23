import '../utils/json_utils.dart';

class TokenPair {
  const TokenPair({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.rawData = const <String, dynamic>{},
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final Map<String, dynamic> rawData;

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: asString(json['access_token']) ?? '',
      refreshToken: asString(json['refresh_token']),
      expiresIn: asInt(json['expires_in']),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
    }..removeWhere((String _, dynamic value) => value == null);
  }

  TokenPair copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    Map<String, dynamic>? rawData,
  }) {
    return TokenPair(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      rawData: rawData ?? this.rawData,
    );
  }
}
