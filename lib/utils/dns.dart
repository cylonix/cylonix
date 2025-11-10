import 'dart:typed_data';

String decodeDNSResponse(Uint8List bytes) {
  if (bytes.isEmpty) {
    return 'Empty response';
  }

  try {
    final buffer = ByteData.sublistView(bytes);

    // Skip DNS header (12 bytes)
    if (bytes.length < 12) {
      return 'Invalid DNS response: too short';
    }

    int offset = 12;

    // Skip question section
    // Read QNAME (domain name)
    while (offset < bytes.length && bytes[offset] != 0) {
      int labelLen = bytes[offset];
      offset += labelLen + 1;
    }
    offset += 1; // Skip null terminator
    offset += 4; // Skip QTYPE and QCLASS

    if (offset >= bytes.length) {
      return 'No answer records found';
    }

    // Parse answer section
    List<String> records = [];
    int answerCount = buffer.getUint16(6); // ANCOUNT from header

    for (int i = 0; i < answerCount && offset < bytes.length; i++) {
      // Skip NAME (usually a pointer)
      if ((bytes[offset] & 0xC0) == 0xC0) {
        offset += 2;
      } else {
        while (offset < bytes.length && bytes[offset] != 0) {
          int labelLen = bytes[offset];
          offset += labelLen + 1;
        }
        offset += 1;
      }

      if (offset + 10 > bytes.length) break;

      int type = buffer.getUint16(offset);
      offset += 2; // TYPE
      offset += 2; // CLASS
      offset += 4; // TTL
      int rdLength = buffer.getUint16(offset);
      offset += 2; // RDLENGTH

      if (offset + rdLength > bytes.length) break;

      String record = _parseResourceRecord(type, bytes, offset, rdLength);
      records.add(record);

      offset += rdLength;
    }

    return records.isEmpty ? 'No valid records found' : records.join('\n');
  } catch (e) {
    return 'Error decoding response: $e';
  }
}

String _parseResourceRecord(int type, Uint8List bytes, int offset, int length) {
  switch (type) {
    case 1: // A record (IPv4)
      if (length == 4) {
        return 'A: ${bytes[offset]}.${bytes[offset + 1]}.${bytes[offset + 2]}.${bytes[offset + 3]}';
      }
      break;
    case 28: // AAAA record (IPv6)
      if (length == 16) {
        List<String> parts = [];
        for (int i = 0; i < 16; i += 2) {
          int value = (bytes[offset + i] << 8) | bytes[offset + i + 1];
          parts.add(value.toRadixString(16));
        }
        return 'AAAA: ${parts.join(':')}';
      }
      break;
    case 5: // CNAME record
      return 'CNAME: ${_readDomainName(bytes, offset)}';
    case 15: // MX record
      int priority = (bytes[offset] << 8) | bytes[offset + 1];
      String exchange = _readDomainName(bytes, offset + 2);
      return 'MX: $priority $exchange';
    case 16: // TXT record
      return 'TXT: ${String.fromCharCodes(bytes.sublist(offset + 1, offset + length))}';
    default:
      return 'Type $type: ${bytes.sublist(offset, offset + length).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}';
  }
  return 'Unknown record format';
}

String _readDomainName(Uint8List bytes, int offset) {
  List<String> labels = [];
  int currentOffset = offset;

  while (currentOffset < bytes.length && bytes[currentOffset] != 0) {
    // Check for compression pointer
    if ((bytes[currentOffset] & 0xC0) == 0xC0) {
      int pointer =
          ((bytes[currentOffset] & 0x3F) << 8) | bytes[currentOffset + 1];
      labels.add(_readDomainName(bytes, pointer));
      break;
    }

    int labelLen = bytes[currentOffset];
    currentOffset++;

    if (currentOffset + labelLen > bytes.length) break;

    labels.add(String.fromCharCodes(
        bytes.sublist(currentOffset, currentOffset + labelLen)));
    currentOffset += labelLen;
  }

  return labels.join('.');
}
