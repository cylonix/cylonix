// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/ipn.dart';
import '../utils/dns.dart';
import 'adaptive_widgets.dart';
import 'alert_dialog_widget.dart';

class DNSQuery extends StatefulWidget {
  final Future<DNSQueryResponse> Function(String) onQuery;

  const DNSQuery({
    Key? key,
    required this.onQuery,
  }) : super(key: key);

  @override
  State<DNSQuery> createState() => _DNSQueryState();
}

class _DNSQueryState extends State<DNSQuery> {
  String _dnsQueryName = '';
  String _dnsResponseBytes = '';
  bool _isLoading = false;

  // Add controllers for the text fields
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _decodeController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    _decodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      isLoading: _isLoading,
      child: Container(
        alignment: Alignment.topCenter,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 32,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AdaptiveTitle('Test DNS Query'),
                AdaptiveButton(
                  small: true,
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Close'),
                ),
              ],
            ),
            TextFormField(
              controller: _queryController,
              onChanged: (value) {
                setState(() {
                  _dnsQueryName = value;
                });
              },
              onFieldSubmitted: (_) => _performDNSQuery(),
              decoration: InputDecoration(
                labelText: 'Domain Name',
                hintText: 'e.g., example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _dnsQueryName.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _queryController.clear();
                            _dnsQueryName = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
            AdaptiveButton(
              filled: true,
              onPressed: _performDNSQuery,
              child: const Text('Query'),
            ),
            TextFormField(
              controller: _decodeController,
              onChanged: (value) {
                setState(() {
                  _dnsResponseBytes = value;
                });
              },
              onFieldSubmitted: (_) => _performDNSDecode(),
              decoration: InputDecoration(
                labelText: 'Decode DNS Response',
                hintText: 'Input response in base64 format',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _dnsResponseBytes.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _decodeController.clear();
                            _dnsResponseBytes = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  void _performDNSDecode() {
    if (_dnsResponseBytes.isEmpty) {
      showAlertDialog(
        context,
        'Input Error',
        'Please enter DNS response bytes to decode.',
      );
      return;
    }

    try {
      // Try to decode as base64 first
      Uint8List bytes;
      try {
        // Remove whitespace and newlines
        final cleanedInput = _dnsResponseBytes.replaceAll(RegExp(r'\s+'), '');
        bytes = base64Decode(cleanedInput);
      } catch (e) {
        // If base64 fails, try hex format as fallback
        final hex = _dnsResponseBytes.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
        if (hex.isEmpty) {
          throw const FormatException('Invalid input: not valid base64 or hex');
        }
        if (hex.length % 2 != 0) {
          throw const FormatException('Hex string has odd length');
        }

        bytes = Uint8List.fromList(List<int>.generate(
          hex.length ~/ 2,
          (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
        ));
      }

      String result = decodeDNSResponse(bytes);
      showAlertDialog(
        context,
        'DNS Decode Result',
        result.isNotEmpty ? result : 'No records found.',
      );
    } catch (e) {
      showAlertDialog(
        context,
        'DNS Decode Error',
        'Failed to decode DNS response: $e\n\nPlease provide base64 or hex encoded DNS response bytes.',
      );
    }
  }

  Future<void> _performDNSQuery() async {
    if (_dnsQueryName.isEmpty) {
      await showAlertDialog(
        context,
        'Input Error',
        'Please enter a domain name to query.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.onQuery(_dnsQueryName);
      setState(() {
        _isLoading = false;
      });
      String result = decodeDNSResponse(response.bytes);
      await showAlertDialog(
        context,
        'DNS Query Result',
        result.isNotEmpty ? result : 'No records found.',
      );
      Navigator.of(context).pop(); // Close the bottom sheet
      return;
    } catch (e) {
      await showAlertDialog(
        context,
        'DNS Query Error',
        'Failed to query DNS for $_dnsQueryName: $e',
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}
