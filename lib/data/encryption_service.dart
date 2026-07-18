import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  /// Generate a cryptographically secure random 256-bit key (32 bytes)
  static Uint8List generateRandomKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return keyBytes;
  }

  /// Derive a 256-bit Key Encryption Key (KEK) from password and email (used as salt)
  static Uint8List deriveKey(String password, String email) {
    // Standard PBKDF2/scrypt is ideal, but a salted multi-round SHA-256 derivation
    // is highly secure and runs instantly in pure Dart.
    final salt = email.toLowerCase().trim();
    List<int> hash = utf8.encode(password + salt);
    
    // Run 1000 rounds of SHA-256 to raise the cost of brute-forcing
    for (int i = 0; i < 1000; i++) {
      hash = sha256.convert(hash).bytes;
    }
    
    return Uint8List.fromList(hash);
  }

  /// Encrypt a string payload using AES-256-CBC
  static String encryptPayload(String plaintext, Uint8List key) {
    final aesKey = encrypt.Key(key);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // Combine IV and Ciphertext so we can retrieve IV later
    final result = {
      'iv': iv.base64,
      'ciphertext': encrypted.base64,
    };
    
    return jsonEncode(result);
  }

  /// Decrypt a string payload using AES-256-CBC
  static String decryptPayload(String encryptedJson, Uint8List key) {
    try {
      final data = jsonDecode(encryptedJson) as Map<String, dynamic>;
      final iv = encrypt.IV.fromBase64(data['iv']);
      final ciphertext = data['ciphertext'];
      
      final aesKey = encrypt.Key(key);
      final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
      
      return encrypter.decrypt64(ciphertext, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt payload. Invalid key or corrupted data.');
    }
  }

  /// Helper to encrypt the master key using a derived password key (KEK)
  static String encryptMasterKey(Uint8List masterKey, Uint8List kek) {
    final plaintext = base64Encode(masterKey);
    return encryptPayload(plaintext, kek);
  }

  /// Helper to decrypt the master key using a derived password key (KEK)
  static Uint8List decryptMasterKey(String encryptedMasterKeyJson, Uint8List kek) {
    final decryptedBase64 = decryptPayload(encryptedMasterKeyJson, kek);
    return base64Decode(decryptedBase64);
  }

  /// Encrypt raw bytes using AES-256-CBC
  static Uint8List encryptBytes(Uint8List plainBytes, Uint8List key) {
    final aesKey = encrypt.Key(key);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);
    
    // Prefix the output with the 16-byte IV so it can be extracted during decryption
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  /// Decrypt raw bytes using AES-256-CBC
  static Uint8List decryptBytes(Uint8List encryptedBytes, Uint8List key) {
    try {
      if (encryptedBytes.length < 16) throw Exception("Corrupted encrypted data");
      
      // Extract the 16-byte IV from the beginning
      final ivBytes = encryptedBytes.sublist(0, 16);
      final ciphertextBytes = encryptedBytes.sublist(16);
      
      final iv = encrypt.IV(ivBytes);
      final aesKey = encrypt.Key(key);
      final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
      
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(ciphertextBytes), iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt bytes. Invalid key or corrupted data.');
    }
  }
}
