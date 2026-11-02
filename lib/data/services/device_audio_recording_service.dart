import 'package:record/record.dart';

import '../repositories/contracts.dart';
import 'recording_storage_stub.dart'
    if (dart.library.io) 'recording_storage_io.dart'
    if (dart.library.js_interop) 'recording_storage_web.dart' as storage;

class DeviceAudioRecordingService implements AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final Stopwatch _stopwatch = Stopwatch();
  String? _recordingPath;

  @override
  bool get isRecording => _stopwatch.isRunning;

  @override
  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw StateError('Bạn chưa cấp quyền sử dụng micro.');
    }

    final path = await storage.newRecordingPath();

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
  }

  @override
  Future<AudioRecordResult> stopRecording() async {
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    _stopwatch.stop();
    final path = await _recorder.stop() ?? _recordingPath;

    if (path == null || !await storage.recordingExists(path)) {
      _recordingPath = null;
      throw StateError('Không lưu được bản thu âm. Hãy kiểm tra micro và thử lại.');
    }

    _recordingPath = null;
    return AudioRecordResult(filePath: path, durationSeconds: elapsedSeconds);
  }

  @override
  Future<void> cancelRecording() async {
    _stopwatch.stop();
    await _recorder.cancel();
    _recordingPath = null;
  }
}
