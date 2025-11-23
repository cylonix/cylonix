// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../models/ipn.dart';
import '../providers/ipn.dart';
import '../utils/utils.dart';
import '../viewmodels/state_notifier.dart';
import '../widgets/adaptive_widgets.dart';

class PeerList extends StatefulWidget {
  final Function(Node) onPeerTap;

  const PeerList({
    Key? key,
    required this.onPeerTap,
  }) : super(key: key);

  @override
  State<PeerList> createState() => _PeerListState();
}

class _PeerListState extends State<PeerList> {
  String _searchTerm = '';
  bool _onlineOnly = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final peerCategorizer = ref.watch(peerCategorizerProvider);
        final filteredSets =
            peerCategorizer.groupedAndFilteredPeers(_searchTerm);
        final showNoResults = _searchTerm.isNotEmpty &&
            filteredSets.every((set) => set.peers.isEmpty);

        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            _searchFocusNode.unfocus();
          },
          child: Column(
            children: [
              _buildSearchBar(context, ref),
              showNoResults
                  ? _buildNoResults(context)
                  : Expanded(
                      child: Padding(
                        padding: const EdgeInsetsGeometry.symmetric(
                          horizontal: 20,
                        ),
                        child: _buildPeersList(context, filteredSets, ref),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return AdaptiveSearchBar(
      focusNode: _searchFocusNode,
      controller: _searchController,
      placeholder: isApple() ? 'Search devices...' : 'Search devices',
      value: _searchTerm,
      onChanged: (value) {
        setState(() {
          _searchTerm = value;
        });
      },
      onCancel: () {
        setState(() {
          _searchController.clear();
          _searchTerm = '';
        });
        _searchFocusNode.unfocus();
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.0 /* Match cupertino list section margin */,
        vertical: useNavigationRail(context) ? 8.0 : 16.0,
      ),
      child: Row(
        children: [
          Flexible(
            child: isAndroidTV ? Container() : _buildSearchField(context),
          ),
          Checkbox.adaptive(
            value: _onlineOnly,
            onChanged: (v) => {setState(() => _onlineOnly = v ?? false)},
          ),
          const Text("Online"),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    if (isApple()) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(height: 8),
            Text(
              'No devices found',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 17,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 8),
          Text(
            'No devices found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }

  Color get _onlineColor =>
      isApple() ? CupertinoColors.systemGreen : Colors.green;

  Color get _offlineColor =>
      isApple() ? CupertinoColors.systemGrey : Theme.of(context).disabledColor;

  Widget _userTitle(UserProfile? user, WidgetRef ref) {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    final style = isApple()
        ? TextStyle(color: CupertinoColors.label.resolveFrom(context))
        : null;
    if (user == null) {
      return Text('Unknown User', style: style);
    }
    if (user.displayName.toLowerCase().endsWith('@privaterelay.appleid.com')) {
      return Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(user.displayName.split('@').first, style: style),
          Text(
            'Apple Private Relay',
            style: TextStyle(
              fontSize: 12,
              color: isApple()
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : Colors.grey,
            ),
          ),
        ],
      );
    }
    final child = Text(
      user.displayName.isNotEmpty ? user.displayName : 'Unknown User',
      style: style,
    );
    if (isAndroidTV) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () {},
          child: Padding(padding: const EdgeInsets.all(8.0), child: child),
        ),
      );
    }
    return child;
  }

  Widget _buildPeersList(
      BuildContext context, List<PeerSet> peerSets, WidgetRef ref) {
    final isConnected =
        ref.watch(ipnStateProvider)?.vpnState == VpnState.connected;
    final selfNode = ref.watch(ipnStateProvider)?.netmap?.selfNode;
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    bool isOnline(Node peer) {
      return (peer.online == true) ||
          (peer.stableID == selfNode?.stableID && isConnected);
    }

    return CustomScrollView(
      slivers: [
        for (final peerSet in peerSets)
          () {
            final filteredPeers = _onlineOnly
                ? peerSet.peers.where((peer) => isOnline(peer)).toList()
                : peerSet.peers;
            if (filteredPeers.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return MultiSliver(
              pushPinnedChildren: true,
              children: [
                SliverAppBar(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  automaticallyImplyLeading: false,
                  expandedHeight: 120.0,
                  backgroundColor: isApple()
                      ? appleScaffoldBackgroundColor(context)
                      : Theme.of(context).colorScheme.surface,
                  title: isAndroidTV ? _userTitle(peerSet.user, ref) : null,
                  flexibleSpace: isAndroidTV
                      ? null
                      : FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          centerTitle: false,
                          title: _userTitle(peerSet.user, ref),
                        ),
                  actions: [
                    if (isAndroidTV)
                      Text(
                        filteredPeers.length == 1
                            ? '1 device'
                            : '${filteredPeers.length} devices',
                      )
                  ],
                  bottom: isAndroidTV
                      ? null
                      : PreferredSize(
                          preferredSize: const Size.fromHeight(30.0),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 8.0,
                              bottom: 8.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Container()),
                                Text(
                                  filteredPeers.length == 1
                                      ? '1 device'
                                      : '${filteredPeers.length} devices',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: isApple()
                                        ? CupertinoColors.secondaryLabel
                                            .resolveFrom(context)
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  pinned: !isAndroidTV,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final peer = filteredPeers[index];
                      return _buildPeer(peer, isOnline(peer));
                    },
                    childCount: filteredPeers.length,
                  ),
                ),
              ],
            );
          }()
      ],
    );
  }

  Widget _buildPeer(Node peer, bool online) {
    final leading = [
      if (peer.isExitNode)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            isApple()
                ? CupertinoIcons.arrow_up_right_circle
                : Icons.exit_to_app,
            color: online ? _onlineColor : _offlineColor,
            size: 12,
          ),
        ),
      AdaptiveOnlineIcon(
        online: online,
        disabledColor: Theme.of(context).disabledColor,
      ),
      if (peer.isJailed ?? false)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            isApple() ? CupertinoIcons.lock_shield : Icons.lock_outline,
            color: CupertinoColors.systemRed,
            size: 12,
          ),
        ),
    ];
    return AdaptiveListTile(
      backgroundColor: Colors.transparent,
      title: Text(peer.name,
          style: isApple()
              ? null
              : Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(
        peer.addresses.join(', '),
        style: isApple()
            ? null
            : Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w300),
      ),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: leading,
      ),
      leadingSize: leading.length > 2 ? 50 : 30,
      dense: true,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: () => widget.onPeerTap(peer),
    );
  }
}
