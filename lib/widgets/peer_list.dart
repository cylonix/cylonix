import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ipn.dart';
import '../providers/ipn.dart';
import '../utils/utils.dart';
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
              _buildSearchBar(context),
              showNoResults
                  ? _buildNoResults(context)
                  : Expanded(
                      child: _buildPeersList(context, filteredSets, ref),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.0 /* Match cupertino list section margin */,
        vertical: useNavigationRail(context) ? 8.0 : 16.0,
      ),
      child: AdaptiveSearchBar(
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

  Widget userTitle(UserProfile? user) {
    final style = isApple()
        ? TextStyle(color: CupertinoColors.label.resolveFrom(context))
        : null;
    if (user == null) {
      return Text('Unknown User', style: style);
    }
    if (user.displayName.toLowerCase().endsWith('@privaterelay.appleid.com')) {
      return Row(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(user.displayName.split('@').first, style: style),
          Text(
            'Apple Private Relay',
            style: style?.copyWith(
              fontSize: 12,
              color: isApple()
                  ? CupertinoColors.secondaryLabel.resolveFrom(context)
                  : Colors.grey,
            ),
          ),
        ],
      );
    }
    return Text(
      user.displayName.isNotEmpty ? user.displayName : 'Unknown User',
      style: style,
    );
  }

  Widget _buildPeersList(
      BuildContext context, List<PeerSet> peerSets, WidgetRef ref) {
    final isConnected =
        ref.watch(ipnStateProvider)?.vpnState == VpnState.connected;
    final selfNode = ref.watch(ipnStateProvider)?.netmap?.selfNode;

    return CustomScrollView(
      slivers: [
        for (final peerSet in peerSets)
          if (peerSet.peers.isNotEmpty) ...[
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 120.0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                centerTitle: !useNavigationRail(context),
                title: userTitle(peerSet.user),
              ),
              actions: const [SizedBox.shrink()],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final peer = peerSet.peers[index];
                  final online = (peer.online == true) ||
                      (peer.stableID == selfNode?.stableID && isConnected);
                  return AdaptiveListTile(
                    backgroundColor: Colors.transparent,
                    title: Text(peer.name,
                        style: isApple()
                            ? null
                            : Theme.of(context)
                                .textTheme
                                .titleMedium
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
                      children: [
                        if (peer.isExitNode)
                          Icon(
                            isApple()
                                ? CupertinoIcons.arrow_up_right_circle
                                : Icons.exit_to_app,
                            color: online ? _onlineColor : _offlineColor,
                            size: 12,
                          ),
                        const SizedBox(width: 4),
                        AdaptiveOnlineIcon(
                          online: online,
                          disabledColor: Theme.of(context).disabledColor,
                        ),
                      ],
                    ),
                    dense: true,
                    onTap: () => widget.onPeerTap(peer),
                  );
                },
                childCount: peerSet.peers.length,
              ),
            ),
          ],
      ],
    );
  }
}
