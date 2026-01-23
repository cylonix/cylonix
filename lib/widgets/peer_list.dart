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
        final isAndroidTV = ref.watch(isAndroidTVProvider);

        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            _searchFocusNode.unfocus();
          },
          child: Column(
            spacing: isAndroidTV ? 8 : 12,
            children: [
              Container(
                constraints: _isLargeDisplay || isAndroidTV
                    ? const BoxConstraints(maxWidth: 800)
                    : null,
                child: _buildSearchBar(context, ref),
              ),
              showNoResults
                  ? _buildNoResults(context)
                  : Expanded(
                      child: Padding(
                        padding: const EdgeInsetsGeometry.only(
                          left: 20,
                          right: 20,
                          bottom: 20,
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

  bool get _isLargeDisplay {
    return MediaQuery.of(context).size.width >= 1200.0;
  }

  Widget _buildSearchField(BuildContext context) {
    return AdaptiveSearchBar(
      focusNode: _searchFocusNode,
      controller: _searchController,
      placeholder: isApple() ? 'Search devices...' : 'Search devices',
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
        vertical: isAndroidTV
            ? 0
            : _isLargeDisplay
                ? 8.0
                : 16.0,
      ),
      child: Row(
        children: [
          Expanded(
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

  Widget _userTitle(PeerSet peerSet, WidgetRef ref) {
    final user = peerSet.user;
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    final isSharingUser = peerSet.isSharee || peerSet.isSharer;
    final style = isApple()
        ? isSharingUser
            ? TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue.resolveFrom(context))
            : TextStyle(color: CupertinoColors.label.resolveFrom(context))
        : isSharingUser
            ? Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600, color: Colors.blue)
            : Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600);
    if (user == null) {
      return Text('Unknown User', style: style);
    }
    final isApplePrivateRelay =
        user.displayName.toLowerCase().endsWith('@privaterelay.appleid.com');

    final title = Text(
      isApplePrivateRelay
          ? "Apple Private Relay " +
              user.displayName.split('@').first +
              (isSharingUser ? '*' : '')
          : (user.displayName.isNotEmpty ? user.displayName : 'Unknown User') +
              (isSharingUser ? '*' : ''),
      style: style,
    );
    final subTitle = isSharingUser
        ? Text(
            '* ' +
                (peerSet.isSharee
                    ? 'Current device is shared to this user. '
                    : '') +
                (peerSet.isSharer ? 'This user shared device with you.' : ''),
            style: TextStyle(
              fontSize: 12,
              color: isApple()
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : Colors.grey,
            ),
          )
        : null;
    final child = Column(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        if (subTitle != null) subTitle,
      ],
    );

    final isSmallDisplay = MediaQuery.of(context).size.width < 500;
    if (isSmallDisplay && subTitle != null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        title: title,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog.adaptive(
              title: title,
              content: subTitle,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
    }
    if (isAndroidTV) {
      return ListTile(
        onTap: () {},
        minLeadingWidth: 0,
        title: title,
        subtitle: subTitle,
      );
    }
    return child;
  }

  Widget _fitWithinMaxWidth(Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          constraints: const BoxConstraints(
            maxWidth: 760.0,
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTitle(PeerSet peerSet, int filteredPeersLength, WidgetRef ref) {
    final isAndroidTV = ref.watch(isAndroidTVProvider);
    final smallDisplay = MediaQuery.of(context).size.width < 500;
    final child = Row(
      spacing: _isLargeDisplay || isAndroidTV ? 0 : 12,
      children: [
        if (!smallDisplay)
          _isLargeDisplay || isAndroidTV
              ? Container(
                  alignment: Alignment.centerLeft,
                  width: 66,
                  child: AdaptiveAvatar(
                    user: peerSet.user,
                    radius: 20,
                  ),
                )
              : AdaptiveAvatar(
                  user: peerSet.user,
                  radius: 20,
                ),
        Expanded(child: _userTitle(peerSet, ref)),
        Text(
          filteredPeersLength == 1
              ? '1 device'
              : '$filteredPeersLength devices',
          style: TextStyle(
            color: isApple()
                ? CupertinoColors.secondaryLabel.resolveFrom(context)
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
    return _isLargeDisplay || isAndroidTV ? _fitWithinMaxWidth(child) : child;
  }

  double _getLeadingSizeForPeerSet(PeerSet peerSet, WidgetRef ref) {
    if (_isLargeDisplay || ref.watch(isAndroidTVProvider)) {
      return 48.0;
    }
    if (peerSet.peers
        .any((peer) => peer.isExitNode && (peer.isJailed ?? false))) {
      return 48.0;
    } else if (peerSet.peers
        .any((peer) => peer.isExitNode || (peer.isJailed ?? false))) {
      return 32.0;
    } else {
      return 20.0;
    }
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
            final leadingSize = _getLeadingSizeForPeerSet(peerSet, ref);
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
                  collapsedHeight: 80.0,
                  expandedHeight: _isLargeDisplay || isAndroidTV ? 80.0 : 120.0,
                  primary: false,
                  leadingWidth: 0,
                  centerTitle: false,
                  forceMaterialTransparency: _isLargeDisplay || isAndroidTV,
                  backgroundColor: isAndroidTV
                      ? Colors.transparent
                      : isApple()
                          ? appleScaffoldBackgroundColor(context)
                          : Theme.of(context).colorScheme.surface,
                  titleSpacing: 0,
                  title: _isLargeDisplay || isAndroidTV
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                          ),
                          color: isAndroidTV
                              ? null
                              : isApple()
                                  ? appleScaffoldBackgroundColor(context)
                                  : Theme.of(context).colorScheme.surface,
                          child: _buildTitle(
                            peerSet,
                            filteredPeers.length,
                            ref,
                          ),
                        )
                      : null,
                  flexibleSpace: _isLargeDisplay || isAndroidTV
                      ? null
                      : FlexibleSpaceBar(
                          centerTitle: false,
                          title: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 8.0,
                            ),
                            child: _buildTitle(
                              peerSet,
                              filteredPeers.length,
                              ref,
                            ),
                          ),
                          expandedTitleScale: 1.2,
                        ),
                  pinned: !isAndroidTV,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final peer = filteredPeers[index];
                      final child = _buildPeer(
                        peer,
                        isOnline(peer),
                        leadingSize,
                      );
                      if (!_isLargeDisplay && !isAndroidTV) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: child,
                        );
                      }
                      return _fitWithinMaxWidth(child);
                    },
                    childCount: filteredPeers.length,
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            );
          }()
      ],
    );
  }

  Widget _buildPeer(Node peer, bool online, double leadingSize) {
    final leading = [
      AdaptiveOnlineIcon(
        online: online,
        disabledColor: Theme.of(context).disabledColor,
      ),
      if (peer.isExitNode)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            isApple()
                ? CupertinoIcons.arrow_up_right_circle
                : Icons.exit_to_app,
            color: online ? _onlineColor : _offlineColor,
            size: 12,
          ),
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
      title: Text(
        peer.displayName,
        style: isApple()
            ? null
            : Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w500),
      ),
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
        mainAxisSize: MainAxisSize.max,
        children: leading,
      ),
      leadingSize: leadingSize,
      dense: true,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: () => widget.onPeerTap(peer),
    );
  }
}
