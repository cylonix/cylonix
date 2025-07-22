import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../utils/logger.dart';

const errorNoError = 0;
const errorIoPending = 997;
const errorBrokenPipe = 109;
const errorPipeInstancesBusy = 231;
const errorPipeNotConnected = 233;
const fileFlagOverlapped = 0x40000000;
const infinite = 0xFFFFFFFF;
const waitObject0 = 0x00000000;

const securityIdentification = 1;
const securitySqosPresent = 0x00100000;
var _handleCount = 0;

final class SecurityQualityOfService extends Struct {
  @Uint32()
  external int length;

  @Int32()
  external int impersonationLevel;

  @Uint8()
  external int contextTrackingMode;

  @Uint8()
  external int effectiveOnly;
}

final _logger = Logger(
  tag: 'NamedPipeSocket',
  defaultSendToIpn: false, // Avoid logging loops
);

class NamedPipeSocket extends StreamView<Uint8List> implements Socket {
  final String id;
  final String pipeName;
  NamedPipeSocket(this.pipeName, this.id) : super(const Stream.empty());

  int? _handle;
  final StreamController<Uint8List> _controller = StreamController<Uint8List>();
  bool _closed = false;
  ReceivePort? _receivePort;
  Isolate? _isolate;

  // IOSink encoding property
  Encoding _encoding = utf8;

  Future<NamedPipeSocket> connect() async {
    await _connect();
    return this;
  }

  bool get _quiet =>
      id.contains("/profiles/current") ||
      id.endsWith("/files/") ||
      id.endsWith("/log");

  Future<ConnectionTask<Socket>> createConnectionTask() async {
    final completer = Completer<NamedPipeSocket>();
    bool cancelled = false;

    // Start the connection
    connect().then((socket) {
      if (!cancelled) {
        completer.complete(socket);
      } else {
        socket.close(); // Clean up if cancelled
        if (!completer.isCompleted) {
          completer.completeError(
            const SocketException('Connection cancelled'),
          );
        }
      }
    }).catchError((error) {
      _logger.e('$id Connection failed: $error');
      close();
      if (!cancelled && !completer.isCompleted) {
        completer.completeError(error);
      }
    });

    // Create ConnectionTask with proper cancellation
    return ConnectionTask.fromSocket(
      completer.future,
      () {
        cancelled = true;
        _logger.w('$id ConnectionTask cancelled');
        close();
        if (!completer.isCompleted) {
          completer.completeError(
            const SocketException('Connection cancelled'),
          );
        }
      },
    );
  }

  void _closeHandle() {
    if (_handle != null) {
      if (!_quiet) {
        _logger.d('$id CloseHandle() handleCount: $_handleCount');
      }
      CloseHandle(_handle!);
      _handle = null;
      _handleCount--;
    }
  }

  Future<void> _connect() async {
    if (!_quiet) {
      _logger.d('$id Connect() handleCount: $_handleCount');
    }
    final lpPipeName = pipeName.toNativeUtf16();
    try {
      var flags = fileFlagOverlapped |
          securitySqosPresent |
          (securityIdentification << 16);
      if (_handle != null) {
        _logger.w('$id Already connected, reuse previous handle');
        return;
      }

      // Try for max of 5 times to connect to the named pipe
      for (var i = 0; i < 5; i++) {
        _handle = CreateFile(
          lpPipeName,
          GENERIC_READ | GENERIC_WRITE,
          0,
          nullptr,
          OPEN_EXISTING,
          flags,
          NULL,
        );

        if (_handle == INVALID_HANDLE_VALUE) {
          final error = GetLastError();
          if (error == errorPipeInstancesBusy || error == errorNoError) {
            if (!_quiet) {
              _logger.w(
                '$id Pipe busy, retrying... attempt ${i + 1}',
              );
            }
            await Future.delayed(const Duration(milliseconds: 200));
            continue;
          }
          throw SocketException(
            'Failed to connect. Error: (${_getErrorMessage(error)})',
            address: InternetAddress.anyIPv4,
            port: 0,
          );
        } else {
          if (!_quiet) {
            _logger.d('$id ✅ Connected. Attempt: ${i + 1}');
          }
          break;
        }
      }

      _handleCount++;

      // Start async reading with blocking reads in isolate
      await _startAsyncReading();
    } catch (e) {
      _closeHandle();
      _logger.e('$id Failed to connect to named pipe: $e');
      rethrow;
    } finally {
      calloc.free(lpPipeName);
    }
  }

  static String _getErrorMessage(int errorCode) {
    switch (errorCode) {
      case 0:
        return '$errorCode SUCCESS - No error';
      case 2:
        return '$errorCode ERROR_FILE_NOT_FOUND - Cannot find the file';
      case 5:
        return '$errorCode ERROR_ACCESS_DENIED - Access is denied';
      case 87:
        return '$errorCode ERROR_INVALID_PARAMETER - The parameter is incorrect';
      case 109:
        return '$errorCode ERROR_BROKEN_PIPE - The pipe has been ended';
      case 231:
        return '$errorCode ERROR_PIPE_BUSY - All pipe instances are busy';
      case 233:
        return '$errorCode ERROR_NO_DATA - The pipe is being closed';
      case 997:
        return '$errorCode ERROR_IO_PENDING - Overlapped I/O in progress';
      default:
        return '$errorCode Unknown error';
    }
  }

  Future<void> _startAsyncReading() async {
    _receivePort = ReceivePort();
    _receivePort!.listen((message) {
      if (message is List<int>) {
        if (!_controller.isClosed) {
          _controller.add(Uint8List.fromList(message));
        }
      } else if (message is String && message.startsWith('error: ')) {
        message = message.replaceFirst('error: ', '');
        _logger.e('$id Named pipe read error: $message');
        if (!_controller.isClosed) {
          _controller.addError(SocketException(
            'Named pipe read error: $message',
            address: InternetAddress.anyIPv4,
            port: 0,
          ));
        } else {
          _logger.e('$id Controller is closed, cannot add error: $message');
        }
      } else if (message == 'done') {
        if (!_controller.isClosed) {
          _controller.close();
        }
      }
    });

    // Start reading isolate
    _isolate = await Isolate.spawn(
      _readingIsolateEntry,
      _ReadingIsolateData(id, _handle!, _receivePort!.sendPort),
    );
  }

  static const _debugNotificationData = false;
  static void _showDebugData(
    String id,
    Uint8List data,
  ) {
    if (id.contains("watch")) {
      try {
        print('\n=== $id Raw Data ===');
        print('Data size: ${data.length} bytes');
        final hexPrefix = data
            .take(8)
            .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
            .join(' ');
        print('First 8 bytes (hex): $hexPrefix');

        // Try to show as ASCII
        try {
          final ascii = String.fromCharCodes(data.take(8));
          print('First 8 bytes (ASCII): $ascii');
        } catch (e) {
          print('First 8 bytes not valid ASCII');
        }
      } catch (e) {
        print('Error analyzing chunk: $e');
      }
      print('=======================\n');
    }
  }

  static void _readingIsolateEntry(_ReadingIsolateData data) {
    final id = data.id;
    final handle = data.handle;
    final sendPort = data.sendPort;

    try {
      while (true) {
        final buffer = calloc<Uint8>(4096);
        final bytesRead = calloc<DWORD>();
        final overlapped = calloc<OVERLAPPED>();
        final event = CreateEvent(nullptr, TRUE, FALSE, nullptr);

        try {
          if (event != NULL) {
            overlapped.ref.hEvent = event;
          }

          //print('Starting async read in isolate...');

          // Async read using overlapped I/O
          final result = ReadFile(
            handle,
            buffer,
            4096,
            bytesRead,
            event != NULL ? overlapped : nullptr, // Use overlapped structure
          );

          if (result != 0) {
            // ReadFile succeeded immediately
            //print(
            //    '$id ReadFile succeeded immediately: ${bytesRead.value} bytes');
            // ReadFile succeeded immediately
            if (bytesRead.value <= 0) {
              // EOF: sender closed their end gracefully
              //print('$id Pipe EOF: clean shutdown');
              sendPort.send('done');
              break;
            }
            //print(
            //    '$id ReadFile succeeded immediately: ${bytesRead.value} bytes');
            final data = buffer.asTypedList(bytesRead.value);
            if (_debugNotificationData) {
              _showDebugData(id, data);
            }
            sendPort.send(data.toList());
            continue;
          }

          // Failed.
          final error = GetLastError();
          //print('$id ReadFile returned 0, error: ${_getErrorMessage(error)}');

          if (error == errorIoPending || error == 0) {
            if (event == NULL) {
              // No event handle provided, cannot wait for completion
              // Should we break and fail??
              continue;
            }
            // Read is pending - wait for completion
            //print('$id ReadFile pending, waiting for completion...');

            final waitResult =
                WaitForSingleObject(event, 10000); // 10 sec timeout

            if (waitResult == waitObject0) {
              // Get the actual bytes read
              final overlappedSuccess = GetOverlappedResult(
                handle,
                overlapped,
                bytesRead,
                FALSE,
              );

              if (overlappedSuccess != 0) {
                //print('$id Async read completed: ${bytesRead.value} bytes');
                if (bytesRead.value > 0) {
                  final data = buffer.asTypedList(bytesRead.value);
                  if (_debugNotificationData) {
                    _showDebugData(id, data);
                  }
                  sendPort.send(data.toList());
                }
                // Continue reading
                continue;
              }
              final error = GetLastError();
              //print(
              //    '$id GetOverlappedResult failed: ${_getErrorMessage(error)}');
              if (error == errorBrokenPipe || error == errorPipeNotConnected) {
                sendPort.send('done');
              } else {
                sendPort.send(
                    'error: read waiting failed: ${_getErrorMessage(error)}');
              }
              break;
            }
            if (waitResult == 258) {
              // WAIT_TIMEOUT
              //print('$id Read operation timed out - continuing...');
              continue;
            }
            //print('$id WaitForSingleObject failed: $waitResult');
            sendPort.send('error: wait failed: $waitResult');
            break;
          }
          if (error == errorBrokenPipe || error == errorPipeNotConnected) {
            //print('$id Pipe disconnected normally');
            sendPort.send('done');
            break;
          }
          //print('$id ReadFile error: ${_getErrorMessage(error)}');
          sendPort.send('error: read failed: ${_getErrorMessage(error)}');
          break;
        } finally {
          if (event != NULL) CloseHandle(event);
          calloc.free(overlapped);
          calloc.free(buffer);
          calloc.free(bytesRead);
        }
      }
    } catch (e, stackTrace) {
      _logger.e('$id Exception in reading isolate: $e');
      _logger.e('$id Stack trace: $stackTrace');
      sendPort.send('error: $e $stackTrace');
    }
  }

  // Override Stream methods to use our controller
  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // IOSink encoding implementation
  @override
  Encoding get encoding => _encoding;

  @override
  set encoding(Encoding encoding) {
    _encoding = encoding;
  }

  @override
  void add(List<int> data) {
    if (_closed || _handle == null) return;

    // Start async write - don't block the caller
    _writeAsync(data);
  }

  void _writeAsync(List<int> data) async {
    final buffer = calloc<Uint8>(data.length);
    final bytesWritten = calloc<DWORD>();
    final overlapped = calloc<OVERLAPPED>();
    final event = CreateEvent(nullptr, TRUE, FALSE, nullptr);

    try {
      if (data.isEmpty) {
        print('$id No data to write, skipping...');
        return;
      }
      for (int i = 0; i < data.length; i++) {
        buffer[i] = data[i];
      }

      if (event != NULL) {
        overlapped.ref.hEvent = event;
      }

      //print('$id Writing ${data.length} bytes to pipe (async)...');
      //print('Content: ${String.fromCharCodes(data)}');

      final success = WriteFile(
        _handle!,
        buffer,
        data.length,
        bytesWritten,
        event != NULL ? overlapped : nullptr, // Use overlapped if we have event
      );

      if (success == 0) {
        final error = GetLastError();

        if (error == errorIoPending) {
          // Write is pending - wait for completion
          print('$id WriteFile pending, waiting for completion...');

          if (event != NULL) {
            final waitResult =
                WaitForSingleObject(event, 5000); // 5 sec timeout

            if (waitResult == waitObject0) {
              // Get the actual bytes written
              final overlappedSuccess = GetOverlappedResult(
                _handle!,
                overlapped,
                bytesWritten,
                FALSE,
              );

              if (overlappedSuccess != 0) {
                print(
                    '$id Successfully wrote ${bytesWritten.value} bytes (async)');
              } else {
                final error = GetLastError();
                print(
                    '$id GetOverlappedResult failed: ${_getErrorMessage(error)}');
              }
            } else {
              print('$id Write operation timed out or failed: $waitResult');
            }
          }
        } else if (error == 0) {
          print('$id error=0 Pipe disconnected normally');
        } else {
          //print('WriteFile failed with error: ${_getErrorMessage(error)}');
          throw SocketException(
            'Failed to write to pipe. Error: ${_getErrorMessage(error)}',
            address: InternetAddress.anyIPv4,
            port: 0,
          );
        }
      } else if (id.contains("/test-stream-error")) {
        _logger.e("$id test error");
        throw SocketException(
          'Failed to write to pipe immediately.Error: Test error',
          address: InternetAddress.anyIPv4,
          port: 0,
        );
      } else if (!_quiet) {
        print('$id Successfully wrote ${bytesWritten.value} bytes (immediate)');
      }
    } catch (e, stackTrace) {
      _logger.e('$id Exception while writing to pipe: $e');
      _controller.addError(
        SocketException(
          'Failed to write to pipe: $e',
          address: InternetAddress.anyIPv4,
          port: 0,
        ),
        stackTrace,
      );
    } finally {
      if (event != NULL) CloseHandle(event);
      calloc.free(overlapped);
      calloc.free(buffer);
      calloc.free(bytesWritten);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    _isolate?.kill();
    _receivePort?.close();
    _closeHandle();

    await _controller.close();
  }

  @override
  void destroy() {
    close();
  }

  @override
  Future get done => _controller.done;

  @override
  Future<void> flush() async {
    if (_handle != null) {
      FlushFileBuffers(_handle!);
    }
  }

  @override
  void write(Object? obj) {
    if (obj != null) {
      add(_encoding.encode(obj.toString()));
    }
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object? obj = ""]) {
    write(obj);
    write('\n');
  }

  // Socket properties
  @override
  InternetAddress get address => InternetAddress.anyIPv4;

  @override
  int get port => 0;

  @override
  InternetAddress get remoteAddress => InternetAddress.anyIPv4;

  @override
  int get remotePort => 0;

  @override
  bool setOption(SocketOption option, bool enabled) => true;

  @override
  Uint8List getRawOption(RawSocketOption option) => Uint8List(0);

  @override
  void setRawOption(RawSocketOption option) {}
}

class _ReadingIsolateData {
  final String id;
  final int handle;
  final SendPort sendPort;

  _ReadingIsolateData(this.id, this.handle, this.sendPort);
}
