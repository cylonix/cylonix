import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ipn.dart';
import '../services/ipn.dart';

class IpnLogsViewModel extends StateNotifier<AsyncValue<List<String>>> {
  final IpnService _ipnService;
  
  IpnLogsViewModel(this._ipnService) : super(const AsyncValue.data([]));

  Future<List<String>> fetchLogs() async {
    try {
      state = const AsyncValue.loading();
      final logs = await _ipnService.getLogs();
      state = AsyncValue.data(logs);
      return logs;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [''];
    }
  }
}

final ipnLogsProvider = StateNotifierProvider<IpnLogsViewModel, AsyncValue<List<String>>>((ref) {
  return IpnLogsViewModel(ref.watch(ipnServiceProvider));
});