import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../repositories/contracts.dart';
import 'recording_storage_stub.dart'
    if (dart.library.io) 'recording_storage_io.dart'
    if (dart.library.js_interop) 'recording_storage_web.dart' as storage;

class DeviceAudioRecordingService implements AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Stopwatch _stopwatch = Stopwatch();

  String? _recordingPath;
  String _latestTranscript = '';
  bool _sttInitialized = false;
  bool _isSttAvailable = false;

  @override
  bool get isRecording => _stopwatch.isRunning;

  @override
  String get latestTranscript => _latestTranscript;

  /// Khởi tạo Speech To Text an toàn
  Future<void> _ensureSttInitialized() async {
    if (_sttInitialized) return;
    try {
      _isSttAvailable = await _speechToText.initialize(
        onError: (val) {
          debugPrint('SpeechToText onError: ${val.errorMsg}');
        },
        onStatus: (val) {
          debugPrint('SpeechToText status: $val');
        },
        debugLogging: false,
      );
      _sttInitialized = true;
    } catch (e) {
      debugPrint('SpeechToText init exception (có thể do môi trường thiếu Speech Engine): $e');
      _isSttAvailable = false;
      _sttInitialized = true;
    }
  }

  @override
  Future<void> startRecording({void Function(String recognizedWords)? onTranscriptionUpdated}) async {
    // 1. Kiểm tra quyền micro
    if (!await _recorder.hasPermission()) {
      throw StateError('Bạn chưa cấp quyền sử dụng micro.');
    }

    _latestTranscript = '';

    // 2. Chuẩn bị đường dẫn lưu file ghi âm
    final path = await storage.newRecordingPath();

    // 3. Khởi chạy AudioRecorder (lưu file thật .wav)
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _recordingPath = path;
    _stopwatch
      ..reset()
      ..start();

    // 4. Bắt đầu Speech Recognition thời gian thực (tiếng Anh en_US)
    try {
      await _ensureSttInitialized();
      if (_isSttAvailable) {
        await _speechToText.listen(
          localeId: 'en_US',
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
          onResult: (result) {
            _latestTranscript = result.recognizedWords;
            onTranscriptionUpdated?.call(_latestTranscript);
          },
        );
      }
    } catch (e) {
      debugPrint('Không thể khởi động SpeechToText: $e');
    }
  }

  @override
  Future<AudioRecordResult> stopRecording() async {
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    _stopwatch.stop();

    // Dừng Speech Recognition
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}

    // Dừng AudioRecorder
    final path = await _recorder.stop() ?? _recordingPath;

    if (path == null || !await storage.recordingExists(path)) {
      _recordingPath = null;
      throw StateError('Không lưu được bản thu âm. Hãy kiểm tra micro và thử lại.');
    }

    _recordingPath = null;
    return AudioRecordResult(
      filePath: path,
      durationSeconds: elapsedSeconds < 1 ? 1 : elapsedSeconds,
      recognizedText: _latestTranscript.trim(),
    );
  }

  @override
  Future<void> cancelRecording() async {
    _stopwatch.stop();
    try {
      if (_speechToText.isListening) {
        await _speechToText.cancel();
      }
    } catch (_) {}

    await _recorder.cancel();
    _recordingPath = null;
    _latestTranscript = '';
  }
}
