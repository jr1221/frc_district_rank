import 'package:tba_api_dart_dio_client/tba_api_dart_dio_client.dart';

class ApiMgr {
  static const tbaKey =
      'KMpingB75hZd8noCRQew4L8ZFEGikoSCGVfZx2x2i4BeL3pVs5C3L9llrEGIvuoB';

  static final api = TbaApiDartDioClient();

  static void init() {
    api.setApiKey('apiKey', tbaKey);
  }
}
