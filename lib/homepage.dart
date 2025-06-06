import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bilgi_yarismasi/yarisma_sayfasi.dart';
import 'services/question_service.dart';
import 'providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final QuestionService _questionService = QuestionService();
  List<String> categories = [];
  String? selectedCategory;
  int selectedQuestionCount = 10;
  bool _isLoading = true;

  static const List<int> questionCounts = [5, 10, 15, 20,25];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final questions = await _questionService.getQuestions();
      final uniqueCategories = questions.map((q) => q.category).toSet().toList()..sort();
      setState(() {
        categories = uniqueCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategoriler yüklenirken bir hata oluştu')),
      );
    }
  }

  Widget _buildCategorySelector() {
    return Column(
      children: [
        Text(
          'Kategori Seçin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal),
          ),
          child: DropdownButton<String>(
            value: selectedCategory,
            hint: Text('Kategori seçiniz'),
            isExpanded: true,
            underline: SizedBox(),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Tüm Kategoriler'),
              ),
              ...categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ],
            onChanged: (value) => setState(() => selectedCategory = value),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCountSelector() {
    return Column(
      children: [
        Text(
          'Soru Sayısı',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: questionCounts.map((count) {
            return GestureDetector(
              onTap: () => setState(() => selectedQuestionCount = count),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: selectedQuestionCount == count
                      ? Colors.teal
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: selectedQuestionCount == count
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Bilgi Yarışması'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Bilgi yarışmasına hoşgeldiniz.',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _buildCategorySelector(),
                          SizedBox(height: 20),
                          _buildQuestionCountSelector(),
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => YarismaSayfasi(
                                    category: selectedCategory,
                                    questionCount: selectedQuestionCount,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Yarışmaya Başla',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '• Her doğru cevap 3 puan\n• Her yanlış cevap -1 puan\n• Başarılar dileriz...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}