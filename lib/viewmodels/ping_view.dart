// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/ipn.dart';
import '../providers/ipn.dart';
import '../services/ipn.dart';
import '../utils/logger.dart';
import '../utils/utils.dart';
part 'ping_view.freezed.dart';

@freezed
class PingState with _$PingState {
  const factory PingState({
    @Default(false) bool isPinging,
    @Default(null) Node? peer,
    @Default("Not Connected") String connectionMode,
    @Default(null) String? errorMessage,
    @Default("") String lastLatencyValue,
    @Default([]) List<double> latencyValues,
  }) = _PingState;
}

enum ConnectionMode {
  notConnected,
  direct,
  derp;

  String get displayName {
    switch (this) {
      case ConnectionMode.direct:
        return 'Direct';
      case ConnectionMode.derp:
        return 'Via Relay';
      default:
        return 'Not Connected';
    }
  }
}

class PingStateNotifier extends StateNotifier<AsyncValue<PingState>> {
  PingStateNotifier(this._ipnService)
      : super(const AsyncValue.data(PingState()));
  static final _logger = Logger(tag: "PingStateNotifier");

  final IpnService _ipnService;
  Timer? _timer;
  int _pingCnt = 0;
  static const _maxPings = 20;
  static const _pingInterval = Duration(seconds: 1);

  void startPing(Node peer) {
    _pingCnt = 0;
    state = AsyncValue.data(state.value!.copyWith(peer: peer, isPinging: true));
    _timer?.cancel();
    _timer = Timer.periodic(_pingInterval, (_) {
      _sendPing();
    });
  }

  void stopPing() {
    _timer?.cancel();
    _pingCnt = 0;
    state = AsyncValue.data(state.value!.copyWith(isPinging: false));
  }

  void handleDismissal() {
    _timer?.cancel();
    _pingCnt = 0;
    state = const AsyncValue.data(PingState());
  }

  Future<void> _sendPing() async {
    final peer = state.value?.peer;
    if (peer == null) {
      _logger.w("Peer is null, cannot send ping");
      state = AsyncValue.data(state.value!.copyWith(
        errorMessage: "Peer is null, cannot send ping",
      ));
      return;
    }

    try {
      final result = await _ipnService.ping(peer);
      _logger.d("Ping result: $result");
      final err = result.error ?? "";
      if (err.isNotEmpty) {
        state = AsyncValue.data(state.value!.copyWith(
          errorMessage: result.error!.capitalize(),
        ));
        return;
      }

      final latency = (result.latencySeconds ?? 0) * 1000;
      state = AsyncValue.data(state.value!.copyWith(
        errorMessage: null,
        lastLatencyValue: '${latency.toStringAsFixed(1)} ms',
        latencyValues: [...state.value!.latencyValues, latency],
        connectionMode: (peer.isWireGuardOnly ?? false)
            ? "Wireguard-only"
            : result.connectionType,
      ));
    } catch (e, stack) {
      _logger.e("Ping error: $e, stack: $stack");
      final error = e.toString().contains('timeout')
          ? 'Request timed out. Make sure ${peer.computedName} is online.'
          : '$e';
      state = AsyncValue.data(state.value!.copyWith(errorMessage: error));
    } finally {
      _pingCnt++;
      if (_pingCnt >= _maxPings) {
        stopPing();
      }
    }
  }
}

final pingStateProvider =
    StateNotifierProvider<PingStateNotifier, AsyncValue<PingState>>((ref) {
  return PingStateNotifier(ref.watch(ipnServiceProvider));
});

final isPingingProvider = Provider<bool>((ref) {
  final pingState = ref.watch(pingStateProvider);
  return pingState.value?.isPinging ?? false;
});
