import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';

class QuestionService {
  Future<List<Question>> getQuestions() async {
    try {
      // JSON dosyasını oku
      final String response = await rootBundle.loadString('assets/questions.json');
      final data = await json.decode(response);
      
      // JSON'dan Question listesi oluştur
      List<Question> questions = (data['questions'] as List)
          .map((questionJson) => Question.fromJson(questionJson))
          .toList();
      
      // Soruları karıştır
      questions.shuffle();
      
      return questions;
    } catch (e) {
      print('Hata: $e');
      return [];
    }
  }
} 