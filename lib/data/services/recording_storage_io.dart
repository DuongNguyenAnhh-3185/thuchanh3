import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> newRecordingPath() async {
  final directory = await getTemporaryDirectory();
  return '${directory.path}${Platform.pathSeparator}'
      'practice_${DateTime.now().millisecondsSinceEpoch}.wav';
}

Future<bool> recordingExists(String path) => File(path).exists();
