import 'package:flutter/material.dart';
import 'dart:async';
import 'models/question.dart';
import 'services/question_service.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

class YarismaSayfasi extends StatefulWidget {
  final String? category;
  final int questionCount;

  const YarismaSayfasi({
    Key? key,
    this.category,
    required this.questionCount,
  }) : super(key: key);

  @override
  _YarismaSayfasiState createState() => _YarismaSayfasiState();
}

class _YarismaSayfasiState extends State<YarismaSayfasi> {
  final QuestionService _questionService = QuestionService();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  bool _isLoading = true;
  Timer? _timer;
  int _timeLeft = 10;
  bool _answered = false;

  static const int _initialTime = 10;
  static const int _correctPoints = 3;
  static const int _wrongPoints = -1;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = _initialTime;
    _answered = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          if (!_answered) {
            _handleTimeOut();
          }
        }
      });
    });
  }

  void _handleTimeOut() {
    _showResultDialog(
      title: 'Süre Doldu! ⏰',
      titleColor: Colors.orange,
      message: 'Bu soruyu cevaplayamadınız.\nDoğru cevap: ${_questions[_currentQuestionIndex].correctAnswer}',
      showStats: false,
    );
  }

  Future<void> _loadQuestions() async {
    try {
      final allQuestions = await _questionService.getQuestions();
      
      final filteredQuestions = widget.category != null
          ? allQuestions.where((q) => q.category == widget.category).toList()
          : allQuestions;
      
      filteredQuestions.shuffle();
      
      final selectedQuestions = filteredQuestions.take(widget.questionCount).toList();
      
      if (mounted) {
        setState(() {
          _questions = selectedQuestions;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sorular yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  void _checkAnswer(String selectedOption) {
    if (_currentQuestionIndex >= _questions.length || _answered) return;

    _answered = true;
    _timer?.cancel();

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = selectedOption == currentQuestion.correctAnswer;

    if (isCorrect) {
      _correctAnswers++;
      _score += _correctPoints;
    } else {
      _wrongAnswers++;
      _score += _wrongPoints;
    }

    _showResultDialog(
      title: isCorrect ? 'Doğru! 🎉' : 'Yanlış! 😔',
      titleColor: isCorrect ? Colors.green : Colors.red,
      message: isCorrect 
        ? 'Tebrikler, +$_correctPoints puan kazandınız!' 
        : 'Maalesef, $_wrongPoints puan kaybettiniz.\nDoğru cevap: ${currentQuestion.correctAnswer}',
      showStats: true,
    );
  }

  void _showResultDialog({
    required String title,
    required Color titleColor,
    required String message,
    required bool showStats,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (showStats) ...[
              SizedBox(height: 10),
              Text(
                'Mevcut Durum:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '✅ Doğru: $_correctAnswers',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '❌ Yanlış: $_wrongAnswers',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '📊 Toplam Puan: $_score',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _nextQuestion();
            },
            child: Text(
              'Sıradaki Soru →',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startTimer();
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Yarışma Tamamlandı! 🎊',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tebrikler, tüm soruları tamamladınız!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '📊 Final Skorunuz:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 10),
            Text(
              '$_score Puan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _score >= 0 ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            _buildStatisticsCard(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Ana Menüye Dön',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatRow('✅ Doğru sayısı:', _correctAnswers),
          SizedBox(height: 8),
          _buildStatRow('❌ Yanlış sayısı:', _wrongAnswers),
          SizedBox(height: 8),
          _buildStatRow('⏳ Boş sayısı:', 
            widget.questionCount - _correctAnswers - _wrongAnswers),
          SizedBox(height: 8),
          _buildStatRow('📊 Başarı oranı:', 
            '${((_correctAnswers / widget.questionCount) * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Soru ${_currentQuestionIndex + 1}/${_questions.length}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 8),
            Text(
              question.question,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.teal),
          ),
        ),
        onPressed: _answered ? null : () => _checkAnswer(option),
        child: Text(
          option,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soru ${_currentQuestionIndex + 1}/${_questions.length}'),
        backgroundColor: Colors.teal,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                'Süre: $_timeLeft',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 3 ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(
                  child: Text(
                    'Bu kategoride soru bulunamadı',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              : Column(
                  children: [
                    // Süre çubuğu
                    LinearProgressIndicator(
                      value: _timeLeft / _initialTime,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timeLeft <= 3 ? Colors.red : Colors.teal,
                      ),
                      minHeight: 8,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 16),
                            _buildQuestionCard(_questions[_currentQuestionIndex]),
                            SizedBox(height: 16),
                            ...(_questions[_currentQuestionIndex].options)
                                .map((option) => _buildOptionButton(option))
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}