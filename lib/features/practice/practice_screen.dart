import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/lesson.dart';

class PracticeScreen extends StatefulWidget {
  final PracticeScreenArgs args;

  const PracticeScreen({super.key, required this.args});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with TickerProviderStateMixin {
  final _services = AppServices();
  final _textToSpeech = FlutterTts();
  Lesson? _lesson;
  bool _isLoadingLesson = true;

  // Recording & STT state
  bool _isRecording = false;
  int _activeSeconds = 0;
  Timer? _timer;
  String? _recordedFilePath;
  String _currentTranscript = '';

  // AI Evaluation state
  bool _isEvaluating = false;
  bool _isPlayingSample = false;
  String? _errorMessage;

  // Testing switches for TV3 / QA
  bool _simulateLowScore = false;
  bool _simulateError = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _initLesson();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      unawaited(_services.audioRecordingService.cancelRecording());
    }
    unawaited(_textToSpeech.stop());
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _initLesson() async {
    if (widget.args.initialLesson != null) {
      setState(() {
        _lesson = widget.args.initialLesson;
        _isLoadingLesson = false;
      });
      return;
    }
    final lesson = await _services.lessonRepo.getLessonById(widget.args.lessonId);
    setState(() {
      _lesson = lesson;
      _isLoadingLesson = false;
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _errorMessage = null;
      _recordedFilePath = null;
      _currentTranscript = '';
      _activeSeconds = 0;
    });

    try {
      await _services.audioRecordingService.startRecording(
        onTranscriptionUpdated: (text) {
          if (mounted) {
            setState(() {
              _currentTranscript = text;
            });
          }
        },
      );
      if (!mounted) {
        await _services.audioRecordingService.cancelRecording();
        return;
      }
      setState(() => _isRecording = true);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _activeSeconds++);
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _errorMessage = 'Không thể bắt đầu thu âm: ${_friendlyError(error)}';
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final result = await _services.audioRecordingService.stopRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedFilePath = result.filePath;
        _activeSeconds = result.durationSeconds;
        if (result.recognizedText != null && result.recognizedText!.isNotEmpty) {
          _currentTranscript = result.recognizedText!;
        }
        if (result.durationSeconds < 1) {
          _errorMessage = 'Bản thu quá ngắn. Hãy đọc hết câu rồi thử lại nhé.';
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = null;
          _errorMessage = 'Không thể lưu bản thu: ${_friendlyError(error)}';
        });
      }
    }
  }

  Future<void> _submitForEvaluation() async {
    if (_lesson == null || _recordedFilePath == null) return;

    if (_activeSeconds < 1) {
      setState(() {
        _errorMessage = 'Thời gian thu âm quá ngắn. Hãy đọc lại toàn bộ câu mẫu nhé.';
      });
      return;
    }

    setState(() {
      _isEvaluating = true;
      _errorMessage = null;
    });

    try {
      // 1. Call AI service to evaluate phonemes and score pronunciation
      var result = await _services.speechAiService.evaluatePronunciation(
        audioFilePath: _recordedFilePath!,
        lessonId: _lesson!.id,
        targetText: _lesson!.text,
        expectedIpa: _lesson!.ipa,
        activeDurationSeconds: _activeSeconds,
        simulateLowScore: _simulateLowScore,
        simulateError: _simulateError,
        spokenText: _currentTranscript.isNotEmpty ? _currentTranscript : null,
      );

      // 2. Lấy thông tin user đang đăng nhập và gán đúng userId để hiển thị trong Lịch sử
      final user = await _services.authRepo.getCurrentUser();
      result = result.copyWith(userId: user.id);

      // 3. SINGLE SOURCE OF TRUTH: Lưu kết quả phiên luyện tập vào SQLite Database
      await _services.practiceRepo.savePracticeResult(result);

      // 4. Cập nhật tiến độ của người dùng (tổng buổi học, số phút active)
      await _services.authRepo.updateProfile(
        user.copyWith(
          totalSessions: user.totalSessions + 1,
          totalActiveMinutes: user.totalActiveMinutes + (_activeSeconds ~/ 60),
          lastPracticeDate: DateTime.now().toIso8601String().split('T').first,
        ),
      );

      // 5. Tính toán lại Streak (chuỗi ngày học)
      await _services.streakRepo.recalculateStreak(user.id);

      // 4. Navigate to ResultScreen
      if (mounted) {
        setState(() => _isEvaluating = false);
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: ResultScreenArgs(result: result),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEvaluating = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _friendlyError(Object error) =>
      error.toString().replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '');

  Future<void> _playSampleAudio() async {
    final text = _lesson?.text;
    if (text == null || text.isEmpty || _isPlayingSample) return;

    setState(() => _isPlayingSample = true);
    try {
      await _textToSpeech.awaitSpeakCompletion(true);
      await _textToSpeech.getVoices;
      await _textToSpeech.setLanguage('en-US');
      await _textToSpeech.setSpeechRate(0.42);
      await _textToSpeech.setVolume(1.0);
      final result = await _textToSpeech.speak(text);
      if (result != null && result != 1) {
        throw StateError('Thiết bị không có giọng đọc English khả dụng.');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không phát được giọng mẫu: ${_friendlyError(error)}. '
              'Hãy kiểm tra/cài giọng English trong cài đặt TTS của thiết bị.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlayingSample = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLesson || _lesson == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson!.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Phonemes Badge
            Wrap(
              spacing: 8,
              children: _lesson!.targetPhonemes
                  .map(
                    (p) => Chip(
                      label: Text('/$p/'),
                      backgroundColor: AppTheme.accentIndigo.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        color: AppTheme.accentIndigo,
                        fontWeight: FontWeight.w700,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),

            // MAIN SENTENCE HERO CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.accentIndigo, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _lesson!.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lesson!.ipa,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.secondaryTeal,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _lesson!.translationVi,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(
                        _isPlayingSample
                            ? Icons.volume_up_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      label: const Text('Nghe giọng đọc mẫu'),
                      onPressed: _playSampleAudio,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // REAL-TIME SPEECH RECOGNITION (STT) BOX
            if (_isRecording || _currentTranscript.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRecording ? AppTheme.accentIndigo : const Color(0xFFCBD5E1),
                    width: _isRecording ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentIndigo.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isRecording ? AppTheme.errorRed : AppTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRecording
                              ? 'Đang nhận diện giọng nói (STT en-US):'
                              : 'Văn bản đã nhận diện từ Microphone:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isRecording ? AppTheme.errorRed : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentTranscript.isNotEmpty
                          ? _currentTranscript
                          : 'Hãy đọc câu tiếng Anh vào micro...',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: _currentTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
                        color: _currentTranscript.isNotEmpty ? AppTheme.textMain : AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // RECORDING VISUALIZER & TIMER
            Column(
              children: [
                Text(
                  _isRecording
                      ? 'Đang lắng nghe giọng đọc...'
                      : (_recordedFilePath != null
                          ? 'Đã ghi âm xong! Nhấn chấm điểm bên dưới.'
                          : 'Nhấn vào Micro để bắt đầu đọc'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isRecording ? AppTheme.errorRed : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_activeSeconds ~/ 60}:${(_activeSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _isRecording ? AppTheme.errorRed : AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 12),

                // AUDIO WAVEFORM ANIMATION WHEN RECORDING
                if (_isRecording)
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      final v = _waveController.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildWaveBar(12 + 16 * v),
                          _buildWaveBar(20 + 20 * (1 - v)),
                          _buildWaveBar(14 + 26 * v),
                          _buildWaveBar(26 + 18 * (1 - v)),
                          _buildWaveBar(16 + 24 * v),
                          _buildWaveBar(22 + 14 * (1 - v)),
                          _buildWaveBar(10 + 18 * v),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 16),

                // PULSING MICROPHONE BUTTON
                GestureDetector(
                  onTap: _isEvaluating
                      ? null
                      : () {
                          if (_isRecording) {
                            _stopRecording();
                          } else {
                            _startRecording();
                          }
                        },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRecording ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: _isRecording ? AppTheme.errorRed : AppTheme.accentIndigo,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? AppTheme.errorRed : AppTheme.accentIndigo)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ERROR DISPLAY WITH RETRY
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // SUBMIT FOR AI EVALUATION BUTTON
            if (_recordedFilePath != null && !_isRecording) ...[
              ElevatedButton(
                onPressed: _isEvaluating ? null : _submitForEvaluation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isEvaluating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'AI đang phân tích âm vị...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Chấm điểm phát âm bằng AI',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
            ],

            // TESTING TOOLBOX CARD (FOR TV3 & TV4 VALIDATION)
            Card(
              color: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.developer_mode, size: 18, color: AppTheme.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'Công cụ Kiểm thử Dữ liệu Giả (TV3/TV4):',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mô phỏng Điểm thấp & Có lỗi âm vị', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Trả về âm /s/ thay vì /θ/ để test ResultScreen', style: TextStyle(fontSize: 11)),
                      value: _simulateLowScore,
                      onChanged: (val) {
                        setState(() {
                          _simulateLowScore = val;
                          if (val) _simulateError = false;
                        });
                      },
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mô phỏng Lỗi AI (SPEECH_NOT_DETECTED)', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Kiểm tra xử lý lỗi mạng và nút thử lại', style: TextStyle(fontSize: 11)),
                      value: _simulateError,
                      onChanged: (val) {
                        setState(() {
                          _simulateError = val;
                          if (val) _simulateLowScore = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 4,
      height: height.clamp(8.0, 40.0),
      decoration: BoxDecoration(
        color: AppTheme.accentIndigo,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
