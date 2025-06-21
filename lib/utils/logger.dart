import 'applog.dart';
import '../services/ipn.dart';

class Logger {
  final String tag;
  final _ipnService = IpnService();
  final _logger = AppLog.logger;
  Logger({required this.tag});
  void d(String log) {
    _logger.d("$tag: $log");
    _ipnService.sendLog("[APP] [DEBUG] [$tag] $log");
  }

  void w(String log) {
    _logger.w("$tag: $log");
    _ipnService.sendLog("[APP] [WARNING] [$tag] $log");
  }

  void i(String log) {
    _logger.i("$tag: $log");
    _ipnService.sendLog("[APP] [INFO] [$tag] $log");
  }

  void e(String log) {
    _logger.e("$tag: $log");
    _ipnService.sendLog("[APP] [ERROR] [$tag] $log");
  }
}
