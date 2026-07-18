import 'dart:typed_data';

class CryptoState {
  static final CryptoState instance = CryptoState._internal();
  CryptoState._internal();

  Uint8List? _masterKey;

  void setMasterKey(Uint8List key) {
    _masterKey = key;
  }

  Uint8List? get masterKey => _masterKey;

  void clear() {
    _masterKey = null;
  }
}
