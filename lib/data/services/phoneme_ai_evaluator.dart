import 'dart:math';
import '../models/practice_result.dart';

/// Service phụ trách phân tích âm vị (Phoneme Analysis) & Chấm điểm phát âm AI
/// Sử dụng thuật toán Levenshtein Distance & Ma trận tương đồng âm vị (Phonetic Similarity Matrix).
class PhonemeAiEvaluator {
  // Từ điển ánh xạ từ vựng sang IPA chuẩn cho các bài học và từ thông dụng
  static final Map<String, String> _cmuIpaDictionary = {
    // Lesson 1: Voiceless TH /θ/ - Think & Thought
    'i': 'aɪ',
    'think': 'θɪŋk',
    'this': 'ðɪs',
    'is': 'ɪz',
    'the': 'ðə',
    'right': 'raɪt',
    'path': 'pæθ',
    'thought': 'θɔːt',
    'thanks': 'θæŋks',
    'thank': 'θæŋk',

    // Lesson 2: Voiced TH /ð/ - Weather & Mother
    'my': 'maɪ',
    'mother': 'ˈmʌðər',
    'loves': 'lʌvz',
    'love': 'lʌv',
    'warm': 'wɔːrm',
    'weather': 'ˈwɛðər',
    'together': 'təˈɡɛðər',
    'father': 'ˈfɑːðər',
    'brother': 'ˈbrʌðər',

    // Lesson 3: Distinguishing /ʃ/ and /s/ - Sea Shells
    'she': 'ʃiː',
    'sells': 'sɛlz',
    'sell': 'sɛl',
    'seashells': 'ˈsiːˌʃɛlz',
    'seashell': 'ˈsiːˌʃɛl',
    'by': 'baɪ',
    'seashore': 'ˈsiːˌʃɔːr',
    'sea': 'siː',
    'shore': 'ʃɔːr',
    'shine': 'ʃaɪn',
    'sun': 'sʌn',

    // Lesson 4: Ending Sounds /t/ and /d/ - Walked & Decided
    'we': 'wiː',
    'walked': 'wɔːkt',
    'walk': 'wɔːk',
    'home': 'hoʊm',
    'and': 'ænd',
    'decided': 'dɪˈsaɪdɪd',
    'decide': 'dɪˈsaɪd',
    'to': 'tuː',
    'stay': 'steɪ',
    'inside': 'ɪnˈsaɪd',
    'played': 'pleɪd',
    'play': 'pleɪ',
    'wanted': 'ˈwɑːntɪd',

    // Lesson 5: Vowel Contrast /iː/ vs /ɪ/ - Sheep vs Ship
    'sheep': 'ʃiːp',
    'boarded': 'ˈbɔːrdɪd',
    'board': 'bɔːrd',
    'big': 'bɪɡ',
    'ship': 'ʃɪp',
    'peacefully': 'ˈpiːsfəli',
    'peaceful': 'ˈpiːsfəl',
    'eat': 'iːt',
    'it': 'ɪt',
    'seat': 'siːt',
    'sit': 'sɪt',

    // Lesson 6: Connected Speech & Linking Words
    'can': 'kæn',
    'have': 'hæv',
    'an': 'ən',
    'apple': 'ˈæpəl',
    'orange': 'ˈɔːrɪndʒ',
    'please': 'pliːz',
    'a': 'ə',
    'you': 'juː',
    'good': 'ɡʊd',
    'morning': 'ˈmɔːrnɪŋ',
    'hello': 'hɛˈloʊ',
    'world': 'wɜːrld',
  };

  /// Tập hợp các âm vị IPA phổ biến để tokenizer nhận diện chính xác
  static final List<String> _multiCharPhonemes = [
    'tʃ', 'dʒ', 'iː', 'uː', 'ɔː', 'ɑː', 'ɜː', 'aɪ', 'eɪ', 'ɔɪ', 'aʊ', 'oʊ', 'əʊ',
    'ɪə', 'eə', 'ʊə', 'kt', 'dɪd', 'st', 'lz', 'vz', 'ŋk', 'ks'
  ];

  /// Chuẩn hóa văn bản: bỏ dấu câu, chuyển chữ thường, bỏ khoảng trắng thừa
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Lấy phiên âm IPA cho 1 từ
  static String getIpaForWord(String word) {
    final clean = normalizeText(word);
    if (_cmuIpaDictionary.containsKey(clean)) {
      return _cmuIpaDictionary[clean]!;
    }
    // Grapheme-to-phoneme rule-based heuristic fallback nếu từ chưa có trong từ điển
    return _heuristicG2P(clean);
  }

  /// Tách một chuỗi IPA thành danh sách các âm vị (tokens)
  static List<String> tokenizeIpa(String ipa) {
    String cleanIpa = ipa.replaceAll(RegExp(r'[/\ˈ\ˌ\.\s]'), '');
    final List<String> tokens = [];
    int i = 0;

    while (i < cleanIpa.length) {
      bool matched = false;
      // Thử khớp các âm vị đa ký tự (nguyên âm dài, nguyên âm đôi, tổ hợp phụ âm)
      for (final multi in _multiCharPhonemes) {
        if (cleanIpa.startsWith(multi, i)) {
          tokens.add(multi);
          i += multi.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        tokens.add(cleanIpa[i]);
        i++;
      }
    }
    return tokens;
  }

  /// Tính ma trận tương đồng ngữ âm giữa 2 âm vị (0.0 đến 1.0)
  static double getPhoneticSimilarity(String p1, String p2) {
    if (p1 == p2) return 1.0;

    // Các cặp âm dễ gây nhầm lẫn của người học tiếng Anh:
    final Map<String, Set<String>> confusionGroups = {
      // Âm vô thanh /θ/ (think) thường bị nhầm thành /s/ hoặc /t/
      'θ': {'s', 't', 'f'},
      's': {'θ', 'ʃ', 'z'},
      't': {'θ', 'd'},

      // Âm hữu thanh /ð/ (this, mother) thường bị nhầm thành /d/ hoặc /z/
      'ð': {'d', 'z', 'v'},
      'd': {'ð', 't'},
      'z': {'ð', 's'},

      // Phân biệt /ʃ/ và /s/
      'ʃ': {'s', 'tʃ'},
      'tʃ': {'ʃ', 'dʒ', 't'},

      // Phân biệt nguyên âm dài /iː/ và ngắn /ɪ/
      'iː': {'ɪ', 'i'},
      'ɪ': {'iː', 'e', 'i'},

      // Phân biệt /uː/ và /ʊ/
      'uː': {'ʊ', 'u'},
      'ʊ': {'uː', 'oʊ'},

      // Âm đuôi bị nuốt/bỏ qua (ví dụ walked /kt/ thành /k/)
      'kt': {'k', 't'},
      'dɪd': {'d', 'ɪd'},
      'dʒ': {'tʃ', 'ʒ', 'd'},
    };

    if (confusionGroups.containsKey(p1) && confusionGroups[p1]!.contains(p2)) {
      return 0.65; // Gần đúng (cần cải thiện)
    }
    if (confusionGroups.containsKey(p2) && confusionGroups[p2]!.contains(p1)) {
      return 0.65;
    }

    // Levenshtein ký tự thông thường cho các âm vị còn lại
    final lev = _levenshteinDistance(p1, p2);
    final maxLen = max(p1.length, p2.length);
    if (maxLen == 0) return 1.0;
    return max(0.0, 1.0 - (lev / maxLen));
  }

  /// Thuật toán Levenshtein Distance
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  /// Đánh giá phát âm câu nói dựa trên mục tiêu (Target) và kết quả nhận diện (Spoken)
  static PracticeResult evaluate({
    required String targetText,
    required String expectedIpa,
    required String spokenText,
    required String lessonId,
    required int activeDurationSeconds,
    bool simulateLowScore = false,
  }) {
    final normTarget = normalizeText(targetText);
    final normSpoken = normalizeText(spokenText);

    final targetWords = normTarget.split(' ').where((w) => w.isNotEmpty).toList();
    final spokenWords = normSpoken.split(' ').where((w) => w.isNotEmpty).toList();

    // Nếu người dùng chọn mô phỏng điểm thấp cho QA/test
    if (simulateLowScore) {
      return _generateSimulatedLowScoreResult(
        targetText: targetText,
        expectedIpa: expectedIpa,
        lessonId: lessonId,
        activeDurationSeconds: activeDurationSeconds,
      );
    }

    final List<WordEvaluation> evaluatedWords = [];
    final List<String> detectedMistakes = [];
    double totalWordScore = 0;

    // So sánh từng từ mục tiêu với các từ thực tế nhận diện được
    for (int i = 0; i < targetWords.length; i++) {
      final targetWord = targetWords[i];
      final targetWordIpa = getIpaForWord(targetWord);
      final targetPhonemes = tokenizeIpa(targetWordIpa);

      String? matchedSpokenWord;
      if (i < spokenWords.length) {
        matchedSpokenWord = spokenWords[i];
      } else {
        // Tìm từ gần nhất trong danh sách spokenWords nếu có hiện tượng nhảy từ
        double bestDist = 999;
        String? bestCandidate;
        for (final sp in spokenWords) {
          final dist = _levenshteinDistance(targetWord, sp).toDouble();
          if (dist < bestDist) {
            bestDist = dist;
            bestCandidate = sp;
          }
        }
        if (bestDist <= 2 && bestCandidate != null) {
          matchedSpokenWord = bestCandidate;
        }
      }

      if (matchedSpokenWord == null || matchedSpokenWord.isEmpty) {
        // Từ bị bỏ sót (Missing word)
        final phonemeEvals = targetPhonemes.map((ph) {
          return PhonemeEvaluation(
            phoneme: ph,
            ipaExpected: ph,
            ipaActual: '—',
            score: 0.0,
            isCorrect: false,
          );
        }).toList();

        evaluatedWords.add(
          WordEvaluation(
            word: targetWord,
            ipa: '/$targetWordIpa/',
            score: 0.0,
            status: 'incorrect',
            phonemes: phonemeEvals,
          ),
        );
        detectedMistakes.add('Từ "$targetWord" bị bỏ qua hoặc phát âm chưa rõ.');
        continue;
      }

      final spokenWordIpa = getIpaForWord(matchedSpokenWord);
      final spokenPhonemes = tokenizeIpa(spokenWordIpa);

      // So sánh âm vị của từ
      final List<PhonemeEvaluation> phonemeEvals = [];
      double wordPhonemeScoreSum = 0;

      for (int pIdx = 0; pIdx < targetPhonemes.length; pIdx++) {
        final expectedP = targetPhonemes[pIdx];
        String actualP = (pIdx < spokenPhonemes.length) ? spokenPhonemes[pIdx] : '—';

        double sim = getPhoneticSimilarity(expectedP, actualP);
        double phScore = (sim * 100).clamp(0.0, 100.0);
        bool isCorrect = phScore >= 80.0;

        phonemeEvals.add(
          PhonemeEvaluation(
            phoneme: expectedP,
            ipaExpected: expectedP,
            ipaActual: actualP,
            score: phScore,
            isCorrect: isCorrect,
          ),
        );

        wordPhonemeScoreSum += phScore;

        // Lưu vết lỗi để tạo AI gợi ý cụ thể
        if (!isCorrect) {
          if (expectedP == 'θ' && (actualP == 's' || actualP == 't')) {
            detectedMistakes.add('Nhầm âm vô thanh /θ/ trong "$targetWord" thành /$actualP/.');
          } else if (expectedP == 'ð' && (actualP == 'd' || actualP == 'z')) {
            detectedMistakes.add('Nhầm âm hữu thanh /ð/ trong "$targetWord" thành /$actualP/.');
          } else if (expectedP == 'iː' && actualP == 'ɪ') {
            detectedMistakes.add('Phát âm nguyên âm dài /iː/ trong "$targetWord" quá ngắn giống /ɪ/.');
          } else if (expectedP == 'ʃ' && actualP == 's') {
            detectedMistakes.add('Nhầm âm /ʃ/ (chu môi) trong "$targetWord" thành âm /s/.');
          } else if (actualP == '—' || actualP.isEmpty) {
            detectedMistakes.add('Thiếu âm đuôi /$expectedP/ ở cuối từ "$targetWord".');
          }
        }
      }

      double avgWordScore = targetPhonemes.isNotEmpty
          ? (wordPhonemeScoreSum / targetPhonemes.length).clamp(0.0, 100.0)
          : 0.0;

      String wordStatus = avgWordScore >= 80.0
          ? 'correct'
          : avgWordScore >= 50.0
              ? 'warning'
              : 'incorrect';

      evaluatedWords.add(
        WordEvaluation(
          word: targetWord,
          ipa: '/$targetWordIpa/',
          score: avgWordScore,
          status: wordStatus,
          phonemes: phonemeEvals,
        ),
      );

      totalWordScore += avgWordScore;
    }

    // 1. Accuracy: Trung bình điểm các từ
    double accuracy = targetWords.isNotEmpty
        ? (totalWordScore / targetWords.length).clamp(0.0, 100.0)
        : 0.0;

    // 2. Completeness: Tỷ lệ số từ người dùng đọc được so với câu gốc
    int matchedCount = 0;
    for (final tw in targetWords) {
      if (spokenWords.any((sw) => _levenshteinDistance(tw, sw) <= 1)) {
        matchedCount++;
      }
    }
    double completeness = targetWords.isNotEmpty
        ? ((matchedCount / targetWords.length) * 100).clamp(0.0, 100.0)
        : 0.0;

    // 3. Fluency: Đánh giá nhịp độ đọc theo thời gian
    // Ước lượng 1 câu tiếng Anh trung bình đọc với tốc độ 2.5 - 3 từ/giây là tự nhiên
    double targetSec = max(2, targetWords.length * 0.6);
    double ratio = activeDurationSeconds / targetSec;
    double fluency = 92.0;
    if (ratio < 0.4) {
      // Đọc quá vội
      fluency = 65.0;
    } else if (ratio > 2.5) {
      // Đọc quá chậm hoặc ngập ngừng
      fluency = 70.0;
    } else {
      fluency = min(96.0, max(75.0, 95.0 - (ratio - 1.0).abs() * 15));
    }

    // 4. Overall score: Bình quân gia quyền
    double overall = (accuracy * 0.55 + fluency * 0.20 + completeness * 0.25).clamp(0.0, 100.0);

    // Sinh gợi ý cải thiện tự nhiên
    final feedbackTips = _generateFeedbackTips(
      overall: overall,
      detectedMistakes: detectedMistakes,
      targetWords: targetWords,
    );

    return PracticeResult(
      sessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      lessonId: lessonId,
      userId: 'usr_dev_01',
      completedAt: DateTime.now().toUtc().toIso8601String(),
      activeDurationSeconds: activeDurationSeconds,
      status: 'completed',
      scores: ScoreBreakdown(
        overall: (overall * 10).round() / 10.0,
        accuracy: (accuracy * 10).round() / 10.0,
        fluency: (fluency * 10).round() / 10.0,
        completeness: (completeness * 10).round() / 10.0,
      ),
      transcript: spokenText.isNotEmpty ? spokenText : '(Không nhận diện được giọng nói)',
      targetText: targetText,
      words: evaluatedWords,
      feedbackTips: feedbackTips,
    );
  }

  /// Sinh danh sách feedback thông minh
  static List<String> _generateFeedbackTips({
    required double overall,
    required List<String> detectedMistakes,
    required List<String> targetWords,
  }) {
    final List<String> tips = [];

    if (overall >= 85) {
      tips.add('Phát âm rất xuất sắc và tự nhiên! Bạn giữ đúng nhịp điệu và ngữ điệu câu.');
    } else if (overall >= 70) {
      tips.add('Bạn đọc khá tốt và rõ ràng! Hãy hoàn thiện thêm các âm vị còn chưa chuẩn.');
    } else {
      tips.add('Cần luyện tập thêm về khẩu hình miệng và tốc độ đọc để đạt điểm cao hơn.');
    }

    // Lọc lấy các lỗi âm vị tiêu biểu (tối đa 3 lời khuyên cụ thể)
    final distinctMistakes = detectedMistakes.toSet().take(3);
    for (final mistake in distinctMistakes) {
      if (mistake.contains('/θ/')) {
        tips.add('Cách phát âm /θ/: Hãy đặt nhẹ đầu lưỡi giữa hai hàm răng và đẩy luồng hơi ra, tránh đọc thành /s/ hoặc /t/.');
      } else if (mistake.contains('/ð/')) {
        tips.add('Cách phát âm /ð/: Đặt đầu lưỡi giữa hai hàm răng tương tự /θ/ nhưng làm rung dây thanh quản (voiced).');
      } else if (mistake.contains('/iː/')) {
        tips.add('Khẩu hình /iː/: Cười mỉm và kéo dài âm hơn để phân biệt rõ với âm ngắn /ɪ/.');
      } else if (mistake.contains('/ʃ/')) {
        tips.add('Khẩu hình /ʃ/: Chu nhẹ môi về phía trước và đẩy hơi êm ái, khác với âm /s/ miệng dẹp.');
      } else if (mistake.contains('Thiếu âm đuôi')) {
        tips.add('Âm đuôi (Ending sound): Đừng quên bật rõ các phụ âm cuối (/t/, /d/, /s/) để câu nói chuẩn bản xứ.');
      } else {
        tips.add(mistake);
      }
    }

    if (tips.length == 1) {
      tips.add('Mẹo: Nhấn nút "Nghe giọng đọc mẫu" để lắng nghe ngữ điệu chuẩn trước khi thu âm lại.');
    }

    return tips;
  }

  /// Kết quả mô phỏng điểm thấp cho TV3/QA
  static PracticeResult _generateSimulatedLowScoreResult({
    required String targetText,
    required String expectedIpa,
    required String lessonId,
    required int activeDurationSeconds,
  }) {
    return PracticeResult(
      sessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      lessonId: lessonId,
      userId: 'usr_dev_01',
      completedAt: DateTime.now().toUtc().toIso8601String(),
      activeDurationSeconds: activeDurationSeconds,
      status: 'completed',
      scores: ScoreBreakdown(
        overall: 58.0,
        accuracy: 54.0,
        fluency: 62.0,
        completeness: 60.0,
      ),
      transcript: 'I sink dis is de right pat',
      targetText: targetText,
      words: [
        WordEvaluation(
          word: 'I',
          ipa: '/aɪ/',
          score: 95.0,
          status: 'correct',
          phonemes: [
            PhonemeEvaluation(phoneme: 'aɪ', ipaExpected: 'aɪ', ipaActual: 'aɪ', score: 95.0, isCorrect: true),
          ],
        ),
        WordEvaluation(
          word: 'think',
          ipa: '/θɪŋk/',
          score: 48.0,
          status: 'incorrect',
          phonemes: [
            PhonemeEvaluation(phoneme: 'θ', ipaExpected: 'θ', ipaActual: 's', score: 45.0, isCorrect: false),
            PhonemeEvaluation(phoneme: 'ɪ', ipaExpected: 'ɪ', ipaActual: 'ɪ', score: 90.0, isCorrect: true),
            PhonemeEvaluation(phoneme: 'ŋk', ipaExpected: 'ŋk', ipaActual: 'ŋk', score: 85.0, isCorrect: true),
          ],
        ),
        WordEvaluation(
          word: 'this',
          ipa: '/ðɪs/',
          score: 52.0,
          status: 'warning',
          phonemes: [
            PhonemeEvaluation(phoneme: 'ð', ipaExpected: 'ð', ipaActual: 'd', score: 40.0, isCorrect: false),
            PhonemeEvaluation(phoneme: 'ɪ', ipaExpected: 'ɪ', ipaActual: 'ɪ', score: 92.0, isCorrect: true),
            PhonemeEvaluation(phoneme: 's', ipaExpected: 's', ipaActual: 's', score: 94.0, isCorrect: true),
          ],
        ),
        WordEvaluation(
          word: 'is',
          ipa: '/ɪz/',
          score: 88.0,
          status: 'correct',
          phonemes: [
            PhonemeEvaluation(phoneme: 'ɪ', ipaExpected: 'ɪ', ipaActual: 'ɪ', score: 90.0, isCorrect: true),
            PhonemeEvaluation(phoneme: 'z', ipaExpected: 'z', ipaActual: 'z', score: 86.0, isCorrect: true),
          ],
        ),
        WordEvaluation(
          word: 'the',
          ipa: '/ðə/',
          score: 50.0,
          status: 'warning',
          phonemes: [
            PhonemeEvaluation(phoneme: 'ð', ipaExpected: 'ð', ipaActual: 'd', score: 40.0, isCorrect: false),
            PhonemeEvaluation(phoneme: 'ə', ipaExpected: 'ə', ipaActual: 'ə', score: 90.0, isCorrect: true),
          ],
        ),
        WordEvaluation(
          word: 'right',
          ipa: '/raɪt/',
          score: 85.0,
          status: 'correct',
          phonemes: [
            PhonemeEvaluation(phoneme: 'r', ipaExpected: 'r', ipaActual: 'r', score: 88.0, isCorrect: true),
            PhonemeEvaluation(phoneme: 'aɪ', ipaExpected: 'aɪ', ipaActual: 'aɪ', score: 90.0, isCorrect: true),
            PhonemeEvaluation(phoneme: 't', ipaExpected: 't', ipaActual: 't', score: 80.0, isCorrect: true),
          ],
        ),
        WordEvaluation(
          word: 'path',
          ipa: '/pæθ/',
          score: 42.0,
          status: 'incorrect',
          phonemes: [
            PhonemeEvaluation(phoneme: 'p', ipaExpected: 'p', ipaActual: 'p', score: 90.0, isCorrect: true),
            PhonemeEvaluation(phoneme: 'æ', ipaExpected: 'æ', ipaActual: 'æ', score: 85.0, isCorrect: true),
            PhonemeEvaluation(phoneme: 'θ', ipaExpected: 'θ', ipaActual: 't', score: 35.0, isCorrect: false),
          ],
        ),
      ],
      feedbackTips: [
        'Điểm phát âm đạt 58/100. Bạn cần chú ý đặc biệt các âm xát răng /θ/ và /ð/.',
        'Âm /θ/ trong "think" và "path" đang bị phát âm nhầm thành /s/ hoặc /t/. Hãy kẹp nhẹ đầu lưỡi giữa hai hàm răng và thổi hơi.',
        'Âm /ð/ trong "this" và "the" đang bị đọc thành /d/. Hãy làm rung nhẹ thanh quản khi để lưỡi giữa hai răng.',
      ],
    );
  }

  /// Grapheme to Phoneme quy tắc đơn giản cho từ ngoại lệ
  static String _heuristicG2P(String word) {
    String res = word
        .replaceAll('tion', 'ʃən')
        .replaceAll('sh', 'ʃ')
        .replaceAll('ch', 'tʃ')
        .replaceAll('th', 'θ')
        .replaceAll('ph', 'f')
        .replaceAll('ee', 'iː')
        .replaceAll('ea', 'iː')
        .replaceAll('oo', 'uː')
        .replaceAll('ay', 'eɪ')
        .replaceAll('ai', 'eɪ')
        .replaceAll('igh', 'aɪ');
    return res;
  }
}
