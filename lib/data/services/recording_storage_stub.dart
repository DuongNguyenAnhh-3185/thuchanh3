Future<String> newRecordingPath() async =>
    throw UnsupportedError('Audio recording is not supported on this platform.');

Future<bool> recordingExists(String path) async => false;
