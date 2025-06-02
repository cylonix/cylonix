import 'applog.dart';
import '../services/ipn.dart';

class Logger {
  final String tag;
  Logger({required this.tag});
  void d(String log) {
    AppLog.logger.d("$tag: $log");
    IpnService.sendLog("[APP] [DEBUG] [$tag] $log");
  }

  void w(String log) {
    AppLog.logger.w("$tag: $log");
    IpnService.sendLog("[APP] [WARNING] [$tag] $log");
  }

  void i(String log) {
    AppLog.logger.i("$tag: $log");
    IpnService.sendLog("[APP] [INFO] [$tag] $log");
  }

  void e(String log) {
    AppLog.logger.e("$tag: $log");
    IpnService.sendLog("[APP] [ERROR] [$tag] $log");
  }
}
