import 'dart:collection';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ansi_parser.dart';

ListQueue<OutputEvent> _outputEventBuffer = ListQueue();
bool _initialized = false;
String _titleText = "Log Console";
String _verboseText = "Verbose";
String _debugText = "Debug";
String _filterText = "Filter log message";
String _infoText = "Info";
String _warningText = "Warning";
String _errorText = "Error";
String _wtfText = "Fatal";
String _refreshText = "Refresh";
String _saveText = "Save";
String _shareText = "Share";

class LogConsole extends StatefulWidget {
  final bool dark;
  final bool showCloseButton;
  final bool showRefreshButton;
  final bool useAnsiParser;
  final String? title;
  final String? subtitle;
  final ListQueue<OutputEvent>? events;
  final Widget? backButton;
  final Future<ListQueue<OutputEvent>> Function()? getLogOutputEvents;
  final void Function(void Function())? listenToUpdateTrigger;
  final Future<String?> Function(List<OutputEvent>)? saveFile;
  final Future<void> Function(List<OutputEvent>)? shareFile;

  LogConsole({
    super.key,
    this.dark = false,
    this.title,
    this.subtitle,
    this.events,
    this.backButton,
    this.showCloseButton = false,
    this.showRefreshButton = false,
    this.getLogOutputEvents,
    this.listenToUpdateTrigger,
    this.saveFile,
    this.shareFile,
    this.useAnsiParser = true,
  }) : assert(_initialized, "Please call LogConsole.init() first.");

  static void init({int bufferSize = 20}) {
    if (_initialized) return;
    _initialized = true;
  }

  static void setLocalTexts({
    String? titleText,
    String? verboseText,
    String? debugText,
    String? filterText,
    String? infoText,
    String? warningText,
    String? errorText,
    String? wtfText,
    String? refreshText,
    String? saveText,
    String? shareText,
  }) {
    if (titleText != null) _titleText = titleText;
    if (filterText != null) _filterText = filterText;
    if (debugText != null) _debugText = debugText;
    if (verboseText != null) _verboseText = verboseText;
    if (infoText != null) _infoText = infoText;
    if (warningText != null) _warningText = warningText;
    if (errorText != null) _errorText = errorText;
    if (wtfText != null) _wtfText = wtfText;
    if (refreshText != null) _refreshText = refreshText;
    if (saveText != null) _saveText = saveText;
    if (shareText != null) _shareText = shareText;
  }

  static void setLogOutput(MemoryOutput logOutput) {
    _outputEventBuffer = logOutput.buffer;
  }

  @override
  State<LogConsole> createState() => _LogConsoleState();
}

class RenderedEvent {
  final int id;
  final Level level;
  final TextSpan? span;
  final String text;

  RenderedEvent(this.id, this.level, this.span, this.text);
}

class _LogConsoleState extends State<LogConsole> {
  final List<RenderedEvent> _renderedBuffer = [];
  List<int> _filteredEvents = [];
  final _logContentFocusNode = FocusNode();
  static const _savedPosition = Offset(100, 100);
  static const int _pageSize = 300;
  List<OutputEvent> _allEvents = [];
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _isLoadingPrevious = false;
  bool _hasMorePrevious = true;
  bool _hasMoreNext = true;
  bool _isSelectionMode = false;
  TextSelection? _currentSelection;
  String? _currentFullText;

  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  Level _filterLevel = Level.trace;
  double _logFontSize = 14;

  bool _followBottom = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _allEvents = widget.events?.toList() ??
        (widget.getLogOutputEvents == null ? _outputEventBuffer.toList() : []);

    _scrollController.addListener(() {
      final pos = _scrollController.position;
      final atBottom = pos.pixels >= pos.maxScrollExtent - 20;
      setState(() => _followBottom = !atBottom);
    });

    final listen = widget.listenToUpdateTrigger;
    if (listen != null) {
      listen(() {
        _reload();
      });
    }
    _initContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    _logContentFocusNode.dispose();
    super.dispose();
  }

  void _reload() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final getEventsF = widget.getLogOutputEvents;
      if (getEventsF == null) {
        _allEvents = _outputEventBuffer.toList();
      } else {
        _allEvents = (await getEventsF()).toList();
      }
      _initContent();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadCurrentPage() {
    _renderedBuffer.clear();

    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    _hasMorePrevious = startIndex > 0;
    _hasMoreNext = endIndex < _filteredEvents.length;

    //print(
    //  "Loading page: $_currentPage, start: $startIndex, end: $endIndex, "
    //  "total: ${_filteredEvents.length}, hasMorePrevious: $_hasMorePrevious, "
    //  "hasMoreNext: $_hasMoreNext",
    //);

    if (startIndex >= _filteredEvents.length || startIndex < 0) {
      return;
    }

    final pageEventIDs = _filteredEvents.sublist(startIndex,
        endIndex > _filteredEvents.length ? _filteredEvents.length : endIndex);

    for (var index in pageEventIDs) {
      _renderedBuffer.add(_renderEvent(_allEvents[index], index));
    }
    //print("Rendered buffer length: ${_renderedBuffer.length}");
  }

  Future<void> _loadNextLogs() async {
    if (_isLoadingMore || !_hasMoreNext) return;
    _isLoadingMore = true;
    try {
      _currentPage++;
      _loadCurrentPage();
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _loadPreviousLogs() async {
    if (_isLoadingPrevious || !_hasMorePrevious) return;
    _isLoadingPrevious = true;
    try {
      final currentOffset = _scrollController.offset;
      _currentPage--;
      _loadCurrentPage();
      // adjust for the newly-inserted items above
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController
            .jumpTo(currentOffset + /* height of new page */ 200.0);
      });
    } finally {
      _isLoadingPrevious = false;
    }
  }

  Color _cupertinoLogColor(Level level) {
    switch (level) {
      case Level.trace:
        return CupertinoColors.secondaryLabel.resolveFrom(context);
      case Level.debug:
        return CupertinoColors.systemCyan.resolveFrom(context);
      case Level.info:
        return CupertinoColors.systemGreen.resolveFrom(context);
      case Level.warning:
        return CupertinoColors.systemOrange.resolveFrom(context);
      case Level.error:
        return CupertinoColors.systemRed.resolveFrom(context);
      case Level.wtf:
        return CupertinoColors.systemPink.resolveFrom(context);
      default:
        return CupertinoColors.label.resolveFrom(context);
    }
  }

  Widget _buildLogContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final fullSpan = TextSpan(
      children: _renderedBuffer.map((ev) {
        if (ev.span != null) {
          return TextSpan(children: ev.span!.children, text: ev.text + '\n');
        } else {
          final color = _isCupertino
              ? _cupertinoLogColor(ev.level)
              : logColor(widget.dark, ev.level);
          return TextSpan(
            text: ev.text + '\n',
            style: TextStyle(
              color: color,
            ),
          );
        }
      }).toList(),
    );
    _currentFullText = fullSpan.toPlainText();

    return Container(
      color: _isCupertino
          ? CupertinoColors.systemBackground.resolveFrom(context)
          : widget.dark
              ? Colors.black
              : Colors.grey[150],
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          final m = n.metrics;
          //print("Scroll position: ${m.pixels}, max: ${m.maxScrollExtent}, "
          //    "at edge: ${m.atEdge}, isLoadingMore=$_isLoadingMore "
          //    "_isLoadingPrevious=$_isLoadingPrevious hasMorePrevious: "
          //    "$_hasMorePrevious, hasMoreNext: $_hasMoreNext}");
          // pulled past top
          if (m.pixels <= 0 && !_isLoadingPrevious && _hasMorePrevious) {
            _loadPreviousLogs();
            return true;
          }
          // pushed past bottom
          if (m.pixels >= m.maxScrollExtent &&
              !_isLoadingMore &&
              _hasMoreNext) {
            _loadNextLogs();
            return true;
          }
          if (n is OverscrollNotification) {
            if (n.overscroll > 0 && !_isLoadingMore && _hasMoreNext) {
              _loadNextLogs();
              return true;
            }
            if (n.overscroll < 0 && !_isLoadingPrevious && _hasMorePrevious) {
              _loadPreviousLogs();
              return true;
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SelectableText.rich(
              fullSpan,
              selectionControls: _isCupertino
                  ? CupertinoTextSelectionControls()
                  : MaterialTextSelectionControls(),
              style: TextStyle(
                fontSize: _logFontSize,
                height: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              scrollPhysics: const NeverScrollableScrollPhysics(),
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.editableText(
                  editableTextState: editableTextState,
                );
              },
              // Make selection handles more visible
              selectionHeightStyle: BoxHeightStyle.strut,
              selectionWidthStyle: BoxWidthStyle.tight,

              selectionColor: _isCupertino
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : Colors.lightBlue[900]!,
              onSelectionChanged: (selection, cause) => setState(() {
                _currentSelection = selection;
                _isSelectionMode = !selection.isCollapsed;
                if (cause == SelectionChangedCause.drag) {
                  // Prevent scroll while dragging
                  _scrollController.position.hold(() {});
                  HapticFeedback.selectionClick();
                }
              }),
            ),
          ),
        ),
      ),
    );
  }

  bool _filterMatched(OutputEvent it) {
    var logLevelMatches = it.level.index >= _filterLevel.index;
    if (!logLevelMatches) {
      return false;
    }
    if (_filterController.text.isNotEmpty) {
      var filterText = _filterController.text.toLowerCase();
      return it.lines.join("\n").toLowerCase().contains(filterText);
    }
    return true;
  }

  void _refreshFilter() {
    final filtered = <int>[];
    for (var i = 0; i < _allEvents.length; i++) {
      if (_filterMatched(_allEvents[i])) {
        filtered.add(i);
      }
    }
    _filteredEvents = filtered;
  }

  void _initContent() {
    _currentPage = 0;
    _refreshFilter();
    _loadCurrentPage();
  }

  void _resetContent() {
    _initContent();
    setState(() {
      // update UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isCupertino
          ? CupertinoColors.systemBackground.resolveFrom(context)
          : null,
      appBar: _buildTopBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _logContentWithKeyShortcuts),
            _buildBottomBar(),
          ],
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _followBottom ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: FloatingActionButton(
            backgroundColor: _isCupertino
                ? CupertinoColors.secondarySystemBackground.resolveFrom(context)
                : null,
            mini: true,
            clipBehavior: Clip.antiAlias,
            onPressed: _scrollToBottom,
            child: Icon(
              _isCupertino
                  ? CupertinoIcons.arrow_down_circle
                  : Icons.arrow_downward,
              color: _isCupertino
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : widget.dark
                      ? Colors.white
                      : Colors.lightBlue[900],
            ),
          ),
        ),
      ),
    );
  }

  double get _scrollRange {
    return MediaQuery.of(context).size.height / 4;
  }

  void _scrollUp() {
    var offset = _scrollController.offset - _scrollRange;
    if (offset < 0) {
      offset = 0;
    }
    _scrollController.jumpTo(offset);
  }

  void _scrollDown() {
    var offset = _scrollController.offset + _scrollRange;
    if (offset > _scrollController.position.maxScrollExtent) {
      offset = _scrollController.position.maxScrollExtent;
    }
    _scrollController.jumpTo(offset);
  }

  Widget get _logContentWithKeyShortcuts {
    return Focus(
      focusNode: _logContentFocusNode,
      child: _buildLogContent(),
      onKeyEvent: (node, event) {
        if (node != _logContentFocusNode) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _scrollUp();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _scrollDown();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.f1) {
          _showPopUpMenu();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  Color? get _buttonColor {
    return null;
  }

  bool get _isCupertino {
    return Platform.isIOS || Platform.isMacOS;
  }

  Widget get _refresh {
    return IconButton(
      icon: Icon(
        _isCupertino ? CupertinoIcons.refresh : Icons.refresh_rounded,
        color: _buttonColor,
        size: 20,
      ),
      tooltip: _refreshText,
      onPressed: () {
        _followBottom = true;
        _reload();
      },
    );
  }

  Widget get _saveAsFile {
    // Use a builder to avoid context issues of the snack bar.
    return Builder(
      builder: (c) => IconButton(
        icon: Icon(
          _isCupertino
              ? CupertinoIcons.download_circle
              : Icons.download_rounded,
          color: _buttonColor,
          size: 20,
        ),
        tooltip: _saveText,
        onPressed: () => _save(c),
      ),
    );
  }

  void _save(BuildContext c) async {
    try {
      final path = await widget.saveFile?.call(_allEvents);
      if (path == null) {
        // Save canceled
        return;
      }

      var filesApp = "";
      var filesAppUri = "";
      if (Platform.isAndroid) {
        filesApp = "the Files app";
        filesAppUri = "content://com.android.externalstorage.documents"
            "/root/downloads";
      } else if (Platform.isIOS) {
        filesApp = "the Files app";
        filesAppUri = "shareddocuments://";
      } else if (Platform.isMacOS) {
        filesApp = "Finder";
        filesAppUri = "file://$path";
      } else if (Platform.isWindows) {
        filesApp = "File Explorer";
        filesAppUri = "file://$path";
      } else if (Platform.isLinux) {
        filesApp = "File Manager";
        filesAppUri = "file://$path";
      }

      showTopSnackBar(
        context,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                children: [
                  const TextSpan(
                    text: "Logs saved to:\n",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: path,
                  ),
                  if (filesApp.isNotEmpty) ...[
                    const TextSpan(
                      text: "\n\nYou can access through ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: filesApp,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer:
                          Platform.isWindows ? null : TapGestureRecognizer()
                            ?..onTap = () async {
                              try {
                                final uri = Uri.parse(filesAppUri);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              } catch (e) {
                                if (mounted) {
                                  await _showAlertDialog(
                                    "Error",
                                    "Failed to open files app: $e",
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        displayDuration: const Duration(seconds: 10),
      );
    } catch (e) {
      if (mounted) {
        await _showAlertDialog("Error", "Failed to save logs: $e");
      }
    }
  }

  Widget get _shareAsFile {
    return IconButton(
      icon: Icon(
        _isCupertino ? CupertinoIcons.share : Icons.ios_share_rounded,
        color: _buttonColor,
        size: 20,
      ),
      tooltip: _shareText,
      onPressed: _share,
    );
  }

  void _share() async {
    try {
      await widget.shareFile?.call(_allEvents);
    } catch (e) {
      if (mounted) {
        _showAlertDialog("Error", "Failed to share logs: $e");
      }
    }
  }

  Future<void> _showAlertDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog.adaptive(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget get _close {
    return IconButton(
      icon: Icon(
        _isCupertino ? CupertinoIcons.xmark : Icons.close,
        color: _buttonColor,
        size: 20,
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  Widget get _popupMenu {
    if (_isCupertino) {
      return PullDownButton(
        itemBuilder: (context) => [
          if (_isSelectionMode) ...[
            PullDownMenuItem(
              onTap: _copySelection,
              title: 'Copy selection',
              icon: CupertinoIcons.doc_on_doc,
            ),
            PullDownMenuItem(
              onTap: _clearSelection,
              title: 'Clear selection',
              icon: CupertinoIcons.clear,
            ),
          ],
          if (widget.showRefreshButton)
            PullDownMenuItem(
              onTap: () {
                _followBottom = true;
                _reload();
              },
              title: _refreshText,
              icon: CupertinoIcons.refresh,
            ),
          if (widget.saveFile != null)
            PullDownMenuItem(
              onTap: () => _save(context),
              title: _saveText,
              icon: CupertinoIcons.doc_text,
            ),
          if (widget.shareFile != null)
            PullDownMenuItem(
              onTap: () => widget.shareFile?.call(_allEvents),
              title: _shareText,
              icon: CupertinoIcons.share,
            ),
          if (widget.showCloseButton)
            PullDownMenuItem(
              onTap: () => Navigator.pop(context),
              title: 'Close',
              icon: CupertinoIcons.xmark,
              isDestructive: true,
            ),
        ],
        position: PullDownMenuPosition.automatic,
        buttonBuilder: (context, showMenu) => CupertinoButton(
          onPressed: showMenu,
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis_circle),
        ),
      );
    }
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      child: const Icon(Icons.more_vert_rounded),
      itemBuilder: (context) => _popupMenuEntries,
    );
  }

  List<PopupMenuEntry<String>> get _popupMenuEntries {
    return [
      if (_isSelectionMode) ...[
        PopupMenuItem<String>(
          value: "copy selection",
          onTap: _copySelection,
          child: Row(
            children: [
              _copySelectionButton,
              const Text("Copy selection"),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: "clear selection",
          onTap: _clearSelection,
          child: Row(children: [
            _clearSelectionButton,
            const Text("Clear selection"),
          ]),
        ),
      ],
      if (widget.showRefreshButton)
        PopupMenuItem<String>(
          value: "refresh",
          onTap: () {
            _followBottom = true;
            _reload();
          },
          child: Row(children: [_refresh, Text(_refreshText)]),
        ),
      if (widget.saveFile != null)
        PopupMenuItem<String>(
          value: "save as file",
          onTap: () => _save(context),
          child: Row(children: [_saveAsFile, Text(_saveText)]),
        ),
      if (widget.shareFile != null)
        PopupMenuItem<String>(
          value: "share as file",
          onTap: () => _share(),
          child: Row(children: [_shareAsFile, Text(_shareText)]),
        ),
      if (widget.showCloseButton)
        PopupMenuItem<String>(
          value: "close log view",
          onTap: () => Navigator.pop(context),
          child: _close,
        ),
    ];
  }

  void _showPopUpMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay == null) {
      return;
    }
    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        _savedPosition & const Size(40, 40),
        Offset.zero & overlay.semanticBounds.size,
      ),
      items: _popupMenuEntries,
    );
  }

  String _getSelectedLogsText() {
    if (_currentSelection == null ||
        _currentSelection!.isCollapsed ||
        _currentFullText == null) {
      return "";
    }
    final sel = _currentSelection!;
    return _currentFullText!.substring(sel.start, sel.end);
  }

  void _copySelection() {
    final text = _getSelectedLogsText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _currentSelection = null;
      _isSelectionMode = false;
    });
  }

  Widget get _copySelectionButton {
    return IconButton(
      icon: Icon(
        _isCupertino ? CupertinoIcons.doc_on_doc : Icons.content_copy,
        color: _buttonColor,
        size: 20,
      ),
      tooltip: Platform.isIOS ? "Copy selection" : "Copy selected logs",
      onPressed: _copySelection,
    );
  }

  Widget get _clearSelectionButton {
    return IconButton(
      icon: Icon(
        _isCupertino ? CupertinoIcons.clear_circled : Icons.clear_all,
        color: _buttonColor,
        size: 20,
      ),
      tooltip: Platform.isIOS ? "Clear selection" : "Clear all selections",
      onPressed: _clearSelection,
    );
  }

  List<Widget> get _selectionButtons {
    return [
      _copySelectionButton,
      _clearSelectionButton,
    ];
  }

  PreferredSizeWidget _buildTopBar() {
    final title = widget.title ?? _titleText;
    final isMobile = (Platform.isAndroid || Platform.isIOS);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (_isCupertino) {
      return CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        leading: widget.backButton,
        middle: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.add, size: 20),
              tooltip: "Increase font size",
              onPressed: () {
                setState(() {
                  _logFontSize++;
                });
              },
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.minus, size: 20),
              tooltip: "Decrease font size",
              onPressed: () {
                setState(() {
                  _logFontSize--;
                });
              },
            ),
            if (!isSmallScreen && _isSelectionMode) ..._selectionButtons,
            if (!isSmallScreen && widget.showRefreshButton) _refresh,
            if (!isSmallScreen && widget.saveFile != null) _saveAsFile,
            if (!isSmallScreen && widget.shareFile != null) _shareAsFile,
            if (!isSmallScreen && widget.showCloseButton) _close,
            if (isSmallScreen) _popupMenu,
          ],
        ),
      );
    }

    return AppBar(
      leading: widget.backButton,
      title: ListTile(
        title: Text(title),
        subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      ),
      centerTitle: true,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: "Increase font size",
          onPressed: () {
            setState(() {
              _logFontSize++;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.remove),
          tooltip: "Decrease font size",
          onPressed: () {
            setState(() {
              _logFontSize--;
            });
          },
        ),
        if (!isMobile)
          IconButton(
            tooltip: "Scroll up",
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: _scrollUp,
          ),
        if (!isMobile)
          IconButton(
            tooltip: "Scroll down",
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: _scrollDown,
          ),
        if (isSmallScreen) _popupMenu,
        if (!isSmallScreen && _isSelectionMode) ..._selectionButtons,
        if (!isSmallScreen && widget.showRefreshButton) _refresh,
        if (!isSmallScreen && widget.saveFile != null) _saveAsFile,
        if (!isSmallScreen && widget.shareFile != null) _shareAsFile,
        if (!isSmallScreen && widget.showCloseButton) _close,
        const SizedBox(width: 16),
      ],
    );
  }

  Widget get _clearButton {
    return IconButton(
      icon: Icon(_isCupertino ? CupertinoIcons.clear : Icons.clear, size: 20),
      onPressed: () {
        _filterController.clear();
        _resetContent();
      },
    );
  }

  Widget _buildBottomBar() {
    final filter = TextField(
      controller: _filterController,
      onChanged: (s) => _resetContent(),
      style: TextStyle(
        color: _isCupertino ? CupertinoColors.label.resolveFrom(context) : null,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        prefixIcon: Icon(
          _isCupertino
              ? CupertinoIcons.line_horizontal_3_decrease
              : Icons.filter_list,
        ),
        suffixIcon: _filterController.text.isNotEmpty ? _clearButton : null,
        labelText: _filterText,
        labelStyle: TextStyle(
          color: _isCupertino
              ? CupertinoColors.placeholderText.resolveFrom(context)
              : Colors.grey,
        ),
      ),
    );
    Widget levelText(String text) {
      return Text(
        text,
        style: TextStyle(
          color:
              _isCupertino ? CupertinoColors.label.resolveFrom(context) : null,
        ),
      );
    }

    if (_isCupertino) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: filter,
            ),
            CupertinoSlidingSegmentedControl<Level>(
              backgroundColor:
                  CupertinoColors.tertiarySystemFill.resolveFrom(context),
              children: {
                Level.trace: levelText(_verboseText),
                Level.debug: levelText(_debugText),
                Level.info: levelText(_infoText),
                Level.warning: levelText(_warningText),
                Level.error: levelText(_errorText),
                Level.fatal: levelText(_wtfText),
              },
              groupValue: _filterLevel,
              onValueChanged: (value) {
                _filterLevel = value ?? Level.trace;
                _resetContent();
              },
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: filter,
          ),
          const SizedBox(width: 20),
          DropdownButton(
            underline: Container(),
            elevation: 0,
            padding: const EdgeInsets.all(8),
            value: _filterLevel,
            items: [
              DropdownMenuItem(
                value: Level.trace,
                child: Text(_verboseText),
              ),
              DropdownMenuItem(
                value: Level.debug,
                child: Text(_debugText),
              ),
              DropdownMenuItem(value: Level.info, child: Text(_infoText)),
              DropdownMenuItem(
                value: Level.warning,
                child: Text(_warningText),
              ),
              DropdownMenuItem(
                value: Level.error,
                child: Text(_errorText),
              ),
              DropdownMenuItem(
                value: Level.fatal,
                child: Text(_wtfText),
              )
            ],
            onChanged: (value) {
              if (value != null) {
                _filterLevel = value;
                _resetContent();
              }
            },
          )
        ],
      ),
    );
  }

  void _scrollToBottom() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _followBottom = true;
    });

    var scrollPosition = _scrollController.position;
    await _scrollController.animateTo(
      scrollPosition.maxScrollExtent - 2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  RenderedEvent _renderEvent(OutputEvent event, int id) {
    final text = event.lines.join('\n');
    TextSpan? span;
    if (widget.useAnsiParser) {
      final parser = AnsiParser(widget.dark, level: event.level);
      parser.parse(text);
      span = TextSpan(children: parser.spans);
    }
    return RenderedEvent(
      id,
      event.level,
      span,
      text,
    );
  }
}

class LogBar extends StatelessWidget {
  final bool dark;
  final Widget child;

  const LogBar({super.key, required this.dark, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (!dark)
              BoxShadow(
                color: Colors.grey[400]!,
                blurRadius: 3,
              ),
          ],
        ),
        child: Material(
          color: dark ? Colors.blueGrey[900] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
