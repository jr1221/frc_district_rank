import 'package:encrypt/encrypt.dart';

class Constants {
  static String _prefKey = r'T(N*b9$5V8b778&%b*b*%&(B78T9b*()';
  static final IV iv = IV.fromLength(16);
  static final encrypter = Encrypter(AES(Key.fromUtf8(_prefKey)));

}