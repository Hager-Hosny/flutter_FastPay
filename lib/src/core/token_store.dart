import '../models/token_pair.dart';

/// Token persistence abstraction used by the FastPay SDK.
abstract class TokenStore {
  Future<TokenPair?> read();

  Future<void> write(TokenPair tokenPair);

  Future<void> clear();
}

/// Default in-memory token store used by the SDK.
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore({TokenPair? initialTokens}) : _tokens = initialTokens;

  TokenPair? _tokens;

  @override
  Future<TokenPair?> read() async => _tokens;

  @override
  Future<void> write(TokenPair tokenPair) async {
    _tokens = tokenPair;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}
