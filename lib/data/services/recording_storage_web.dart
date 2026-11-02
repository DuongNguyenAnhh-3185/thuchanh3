Future<String> newRecordingPath() async =>
    'practice_${DateTime.now().millisecondsSinceEpoch}.wav';

Future<bool> recordingExists(String path) async => path.startsWith('blob:');
