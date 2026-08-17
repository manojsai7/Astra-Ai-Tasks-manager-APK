import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Exceptions thrown during cryptographic operations (KDF, encryption, decryption, MAC verification).
class AstraCryptoException implements Exception {
  final String message;
  final String? code;

  const AstraCryptoException(this.message, [this.code]);

  @override
  String toString() => 'AstraCryptoException: $message (code: $code)';
}

/// Encrypted container holding ciphertext, nonce, salt, and authentication tag.
class AstraEncryptedPackage {
  final String cipher;
  final String kdf;
  final int kdfIterations;
  final String saltBase64;
  final String nonceBase64;
  final String authTagBase64;
  final String ciphertextBase64;

  const AstraEncryptedPackage({
    this.cipher = 'AES-256-GCM',
    this.kdf = 'PBKDF2_HMAC_SHA256',
    this.kdfIterations = AstraCryptoService.defaultPbkdf2Iterations,
    required this.saltBase64,
    required this.nonceBase64,
    required this.authTagBase64,
    required this.ciphertextBase64,
  });

  Map<String, dynamic> toJson() => {
        'cipher': cipher,
        'kdf': kdf,
        'kdfParameters': {
          'iterations': kdfIterations,
          'keyLength': 32,
          'saltLength': 16,
          'nonceLength': 12,
        },
        'salt': saltBase64,
        'nonce': nonceBase64,
        'authTag': authTagBase64,
        'ciphertext': ciphertextBase64,
      };

  factory AstraEncryptedPackage.fromJson(Map<String, dynamic> json) {
    final kdfParams = json['kdfParameters'] as Map<String, dynamic>? ?? {};
    return AstraEncryptedPackage(
      cipher: json['cipher'] as String? ?? 'AES-256-GCM',
      kdf: json['kdf'] as String? ?? 'PBKDF2_HMAC_SHA256',
      kdfIterations: kdfParams['iterations'] as int? ?? (json['kdfIterations'] as int? ?? AstraCryptoService.defaultPbkdf2Iterations),
      saltBase64: json['salt'] as String? ?? '',
      nonceBase64: json['nonce'] as String? ?? '',
      authTagBase64: json['authTag'] as String? ?? '',
      ciphertextBase64: json['ciphertext'] as String? ?? '',
    );
  }
}

/// Service providing production-grade password key derivation and AES-256-GCM authenticated encryption.
class AstraCryptoService {
  /// OWASP recommended minimum work factor for PBKDF2-HMAC-SHA256 (600,000 rounds).
  static const int defaultPbkdf2Iterations = 600000;
  static const int saltLength = 16;
  static const int nonceLength = 12;

  final AesGcm _aesGcm;

  AstraCryptoService({AesGcm? aesGcm})
      : _aesGcm = aesGcm ?? Cryptography.instance.aesGcm(secretKeyLength: 32);

  /// Generates cryptographically secure random bytes.
  Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derives a 256-bit SecretKey from the user password and salt using PBKDF2-HMAC-SHA256.
  Future<SecretKey> deriveKey({
    required String password,
    required Uint8List salt,
    int iterations = defaultPbkdf2Iterations,
  }) async {
    if (password.isEmpty) {
      throw const AstraCryptoException('Password cannot be empty.', 'empty_password');
    }

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    return secretKey;
  }

  /// Encrypts plaintext JSON payload with AES-256-GCM using a password-derived key.
  Future<AstraEncryptedPackage> encryptData({
    required String plaintext,
    required String password,
    int iterations = defaultPbkdf2Iterations,
  }) async {
    final salt = generateRandomBytes(saltLength);
    final nonce = generateRandomBytes(nonceLength);

    final key = await deriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
    );

    final cleartextBytes = utf8.encode(plaintext);

    final secretBox = await _aesGcm.encrypt(
      cleartextBytes,
      secretKey: key,
      nonce: nonce,
    );

    return AstraEncryptedPackage(
      cipher: 'AES-256-GCM',
      kdf: 'PBKDF2_HMAC_SHA256',
      kdfIterations: iterations,
      saltBase64: base64Encode(salt),
      nonceBase64: base64Encode(nonce),
      authTagBase64: base64Encode(secretBox.mac.bytes),
      ciphertextBase64: base64Encode(secretBox.cipherText),
    );
  }

  /// Decrypts an [AstraEncryptedPackage] with AES-256-GCM and verifies the authentication tag.
  Future<String> decryptData({
    required AstraEncryptedPackage package,
    required String password,
  }) async {
    if (package.saltBase64.isEmpty || package.nonceBase64.isEmpty || package.ciphertextBase64.isEmpty) {
      throw const AstraCryptoException('Invalid or missing cryptographic parameters in backup archive.', 'invalid_package');
    }

    final Uint8List salt;
    final Uint8List nonce;
    final Uint8List authTag;
    final Uint8List ciphertext;

    try {
      salt = base64Decode(package.saltBase64);
      nonce = base64Decode(package.nonceBase64);
      authTag = base64Decode(package.authTagBase64);
      ciphertext = base64Decode(package.ciphertextBase64);
    } catch (_) {
      throw const AstraCryptoException('Corrupted Base64 encoding in encrypted backup archive.', 'corrupt_base64');
    }

    final key = await deriveKey(
      password: password,
      salt: salt,
      iterations: package.kdfIterations,
    );

    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(authTag),
    );

    try {
      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: key,
      );
      return utf8.decode(decryptedBytes);
    } on SecretBoxAuthenticationError {
      throw const AstraCryptoException(
        'Decryption failed: Incorrect password or tampered backup archive.',
        'invalid_password_or_mac',
      );
    } catch (e) {
      if (e is AstraCryptoException) rethrow;
      throw AstraCryptoException(
        'Failed to decrypt backup data: $e',
        'decryption_error',
      );
    }
  }
}
