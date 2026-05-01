// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause
//
// Minimal Open Graph / HTML link previewer. Adapted from
// https://github.com/cylonix/tailchat/tree/main/plugins/flutter_link_previewer
// but trimmed of its flutter_chat_types dependency and simplified for the
// peer messaging surface.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart' hide Element;
import 'package:flutter/material.dart' hide Element;
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../utils/utils.dart';

class LinkPreviewData {
  final String link;
  final String? title;
  final String? description;
  final String? imageUrl;

  const LinkPreviewData({
    required this.link,
    this.title,
    this.description,
    this.imageUrl,
  });

  bool get hasContent =>
      (title?.isNotEmpty ?? false) ||
      (description?.isNotEmpty ?? false) ||
      (imageUrl?.isNotEmpty ?? false);
}

/// In-memory cache of resolved previews. Survives for the life of the app
/// process so scrolling back to an older message doesn't re-fetch. Caps
/// concurrent HTTP fetches so a long conversation doesn't open dozens of
/// parallel requests when the view first renders.
class LinkPreviewCache {
  static const int _maxConcurrent = 3;
  static final Map<String, Future<LinkPreviewData?>> _inflight = {};
  static final Map<String, LinkPreviewData?> _resolved = {};
  static final List<_QueuedFetch> _queue = [];
  static int _activeFetches = 0;

  static LinkPreviewData? peek(String url) => _resolved[url];

  static bool isCachedOrInFlight(String url) =>
      _resolved.containsKey(url) || _inflight.containsKey(url);

  static Future<LinkPreviewData?> fetch(String url) {
    if (_resolved.containsKey(url)) {
      return Future.value(_resolved[url]);
    }
    final existing = _inflight[url];
    if (existing != null) {
      return existing;
    }
    final completer = Completer<LinkPreviewData?>();
    _inflight[url] = completer.future;
    if (_activeFetches < _maxConcurrent) {
      _runFetch(url, completer);
    } else {
      _queue.add(_QueuedFetch(url, completer));
    }
    return completer.future;
  }

  static void _runFetch(String url, Completer<LinkPreviewData?> completer) {
    _activeFetches++;
    _fetchUncached(url).then((data) {
      _resolved[url] = data;
      _inflight.remove(url);
      _activeFetches--;
      completer.complete(data);
      _processQueue();
    }, onError: (Object _) {
      _resolved[url] = null;
      _inflight.remove(url);
      _activeFetches--;
      completer.complete(null);
      _processQueue();
    });
  }

  static void _processQueue() {
    while (_activeFetches < _maxConcurrent && _queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      _runFetch(next.url, next.completer);
    }
  }
}

class _QueuedFetch {
  final String url;
  final Completer<LinkPreviewData?> completer;
  _QueuedFetch(this.url, this.completer);
}

const _userAgent = 'Mozilla/5.0 (compatible; CylonixLinkPreview/1.0)';
const _imageContentType = r'image/';

Future<LinkPreviewData?> _fetchUncached(String url) async {
  Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (_) {
    return null;
  }
  if (!uri.hasScheme) {
    uri = Uri.parse('https://$url');
  }
  http.Response response;
  try {
    response = await http.get(
      uri,
      headers: const {
        'User-Agent': _userAgent,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/*;q=0.8,*/*;q=0.7',
      },
    ).timeout(const Duration(seconds: 8));
  } catch (_) {
    return null;
  }
  if (response.statusCode < 200 || response.statusCode >= 400) {
    return null;
  }
  final contentType = response.headers['content-type'] ?? '';
  if (contentType.startsWith(_imageContentType)) {
    return LinkPreviewData(link: uri.toString(), imageUrl: uri.toString());
  }
  Document document;
  try {
    document = html_parser.parse(utf8.decode(response.bodyBytes));
  } catch (_) {
    try {
      document = html_parser.parse(response.body);
    } catch (_) {
      return null;
    }
  }
  final title = _readTitle(document);
  final description = _readDescription(document);
  final imageUrl = _readImage(document, uri);
  final data = LinkPreviewData(
    link: uri.toString(),
    title: title,
    description: description,
    imageUrl: imageUrl,
  );
  return data.hasContent ? data : null;
}

String? _metaContent(Document document, String key) {
  for (final element in document.getElementsByTagName('meta')) {
    final property = element.attributes['property'];
    final name = element.attributes['name'];
    if (property == key || name == key) {
      final content = element.attributes['content']?.trim();
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }
  }
  return null;
}

String? _readTitle(Document document) {
  final og = _metaContent(document, 'og:title');
  if (og != null) return og;
  final twitter = _metaContent(document, 'twitter:title');
  if (twitter != null) return twitter;
  final titles = document.getElementsByTagName('title');
  if (titles.isNotEmpty) {
    final text = titles.first.text.trim();
    if (text.isNotEmpty) return text;
  }
  return _metaContent(document, 'og:site_name');
}

String? _readDescription(Document document) {
  return _metaContent(document, 'og:description') ??
      _metaContent(document, 'twitter:description') ??
      _metaContent(document, 'description');
}

String? _readImage(Document document, Uri baseUri) {
  final raw = _metaContent(document, 'og:image') ??
      _metaContent(document, 'twitter:image') ??
      _firstImgSrc(document);
  if (raw == null) return null;
  return _absoluteUrl(raw, baseUri);
}

String? _firstImgSrc(Document document) {
  for (final Element img in document.getElementsByTagName('img')) {
    final src = img.attributes['src']?.trim();
    if (src != null && src.isNotEmpty && !src.startsWith('data:')) {
      return src;
    }
  }
  return null;
}

String? _absoluteUrl(String raw, Uri base) {
  if (raw.isEmpty) return null;
  if (raw.startsWith('//')) return 'https:$raw';
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  try {
    return base.resolve(raw).toString();
  } catch (_) {
    return null;
  }
}

class LinkPreview extends StatefulWidget {
  final String url;
  final Color foregroundColor;
  final Color secondaryColor;
  final Color borderColor;
  final VoidCallback? onLongPress;
  final void Function(Offset globalPosition)? onSecondaryTapDown;

  const LinkPreview({
    super.key,
    required this.url,
    required this.foregroundColor,
    required this.secondaryColor,
    required this.borderColor,
    this.onLongPress,
    this.onSecondaryTapDown,
  });

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  bool _resolveStarted = false;

  @override
  void initState() {
    super.initState();
    _ensureFetch();
  }

  @override
  void didUpdateWidget(LinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resolveStarted = false;
      _ensureFetch();
    }
  }

  void _ensureFetch() {
    if (_resolveStarted) return;
    if (LinkPreviewCache.peek(widget.url) != null) {
      return;
    }
    _resolveStarted = true;
    LinkPreviewCache.fetch(widget.url).then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = LinkPreviewCache.peek(widget.url);
    if (data == null || !data.hasContent) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => launchUrl(
          Uri.parse(data.link),
          mode: LaunchMode.externalApplication,
        ),
        onLongPress: widget.onLongPress,
        onSecondaryTapDown: widget.onSecondaryTapDown == null
            ? null
            : (details) => widget.onSecondaryTapDown!(details.globalPosition),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(isApple() ? 12 : 10),
          ),
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((data.imageUrl ?? '').isNotEmpty)
                _PreviewImage(url: data.imageUrl!),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((data.title ?? '').isNotEmpty)
                      Text(
                        data.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.foregroundColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    if ((data.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.secondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _hostFor(data.link),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.secondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hostFor(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }
}

class _PreviewImage extends StatelessWidget {
  final String url;
  const _PreviewImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 160,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: 160,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: isApple()
                  ? const CupertinoActivityIndicator(radius: 9)
                  : const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
