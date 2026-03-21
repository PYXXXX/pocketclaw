import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:gateway_transport/gateway_transport.dart';

import 'gateway_device_auth_provider.dart';
import 'gateway_device_identity.dart';
import 'gateway_device_identity_store.dart';

final class CryptographyDeviceAuthProvider
    implements GatewayDeviceAuthProvider {
  CryptographyDeviceAuthProvider({
    required GatewayDeviceIdentityStore store,
    Ed25519? algorithm,
    Sha256? sha256,
    Random? random,
  })  : _store = store,
        _algorithm = algorithm ?? Ed25519(),
        _sha256 = sha256 ?? Sha256(),
        _random = random ?? Random.secure();

  final GatewayDeviceIdentityStore _store;
  final Ed25519 _algorithm;
  final Sha256 _sha256;
  final Random _random;

  @override
  Future<Map<String, Object?>> buildDeviceAuth({
    required ConnectChallenge challenge,
    required ConnectRequest connectRequest,
  }) async {
    final identity = await _loadOrCreateIdentity();
    final signedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    final token = (connectRequest.auth?['token'] as String?) ?? '';
    final payload = _buildSignaturePayload(
      deviceId: identity.deviceId,
      clientId: connectRequest.client.id,
      clientMode: connectRequest.client.mode,
      role: connectRequest.role,
      scopes: connectRequest.scopes,
      signedAtMs: signedAt,
      token: token,
      nonce: challenge.nonce,
    );

    final keyPair = await _algorithm.newKeyPairFromSeed(
      _decodeBase64Url(identity.privateKey),
    );
    final signature = await _algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );

    return <String, Object?>{
      'id': identity.deviceId,
      'publicKey': identity.publicKey,
      'signature': _encodeBase64Url(signature.bytes),
      'signedAt': signedAt,
      'nonce': challenge.nonce,
    };
  }

  Future<GatewayDeviceIdentity> _loadOrCreateIdentity() async {
    final existing = await _store.read();
    if (existing != null) {
      return existing;
    }

    final seed = List<int>.generate(32, (_) => _random.nextInt(256));
    final keyPair = await _algorithm.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    final digest = await _sha256.hash(publicKey.bytes);

    final identity = GatewayDeviceIdentity(
      deviceId: _hexEncode(digest.bytes),
      publicKey: _encodeBase64Url(publicKey.bytes),
      privateKey: _encodeBase64Url(seed),
    );
    await _store.write(identity);
    return identity;
  }

  String _buildSignaturePayload({
    required String deviceId,
    required String clientId,
    required String clientMode,
    required String role,
    required List<String> scopes,
    required int signedAtMs,
    required String token,
    required String nonce,
  }) {
    return <String>[
      'v2',
      deviceId,
      clientId,
      clientMode,
      role,
      scopes.join(','),
      signedAtMs.toString(),
      token,
      nonce,
    ].join('|');
  }

  String _encodeBase64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Uint8List _decodeBase64Url(String value) {
    final normalized = base64Url.normalize(value);
    return base64Url.decode(normalized);
  }

  String _hexEncode(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
