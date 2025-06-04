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
                      child: isApple()
                          ? _buildCupertinoPeersList(context, filteredSets, ref)
                          : _buildMaterialPeersList(context, filteredSets, ref),
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

  Widget _buildCupertinoPeersList(
      BuildContext context, List<PeerSet> peerSets, WidgetRef ref) {
    final isConnected =
        ref.watch(ipnStateProvider)?.vpnState == VpnState.connected;
    final selfNode = ref.watch(ipnStateProvider)?.netmap?.selfNode;

    return CustomScrollView(
      slivers: [
        for (final peerSet in peerSets)
          if (peerSet.peers.isNotEmpty) ...[
            SliverAppBar(
              expandedHeight: 120.0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: !useNavigationRail(context),
                title: Text(peerSet.user?.displayName ?? "",
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                    )),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final peer = peerSet.peers[index];
                  final online = (peer.online == true) ||
                      (peer.stableID == selfNode?.stableID && isConnected);
                  return CupertinoListTile(
                    title: Text(peer.name),
                    subtitle: Text(peer.addresses.join(', ')),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (peer.isExitNode)
                          Icon(CupertinoIcons.arrow_up_right_circle,
                              color: online
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemGrey,
                              size: 12),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.circle_fill,
                          size: 12,
                          color: online
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemGrey,
                        ),
                      ],
                    ),
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

  Widget _buildMaterialPeersList(
      BuildContext context, List<PeerSet> peerSets, WidgetRef ref) {
    final isConnected =
        ref.watch(ipnStateProvider)?.vpnState == VpnState.connected;
    final selfNode = ref.watch(ipnStateProvider)?.netmap?.selfNode;

    return ListView.builder(
      itemCount: peerSets.length,
      itemBuilder: (context, setIndex) {
        final peerSet = peerSets[setIndex];
        if (peerSet.peers.isEmpty) return const SizedBox.shrink();
        return ExpansionTile(
          title: Text(
            peerSet.user?.displayName ?? "",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          initiallyExpanded: true,
          children: peerSet.peers.map((peer) {
            final online = (peer.online == true) ||
                (peer.stableID == selfNode?.stableID && isConnected);

            return ListTile(
              title: Text(peer.name),
              subtitle: Text(peer.addresses.join(', ')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (peer.isExitNode)
                    Icon(
                      Icons.exit_to_app,
                      color: Theme.of(context).disabledColor,
                    ),
                  const SizedBox(width: 8),
                  AdaptiveOnlineIcon(
                    online: online,
                    disabledColor: Theme.of(context).disabledColor,
                  ),
                ],
              ),
              onTap: () => widget.onPeerTap(peer),
            );
          }).toList(),
        );
      },
    );
  }
}
