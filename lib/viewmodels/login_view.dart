import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ipn.dart';
import 'state_notifier.dart';

class LoginViewModel extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  LoginViewModel(this.ref) : super(const AsyncValue.data(null));

  Future<void> loginWithAuthKey(String key,
      {required void Function() onSuccess}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(ipnStateNotifierProvider.notifier)
          .login(authKey: key, controlURL: ref.read(controlURLProvider));
      state = const AsyncValue.data(null);
      onSuccess();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, AsyncValue<void>>((ref) {
  return LoginViewModel(
    ref, // Pass ref to LoginViewModel
  );
});
