
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_models.dart';

class TriviaApiService {
  static const String baseUrl = 'https://opentdb.com';

  // Get all available categories
  static Future<List<TriviaCategory>> getCategories() async {
    final url = Uri.parse('$baseUrl/api_category.php');
    final response = await http.get(url);

    final data = json.decode(response.body);
    final List<dynamic> categoriesJson = data['trivia_categories'];

    return categoriesJson
        .map((json) => TriviaCategory.fromJson(json))
        .toList();
  }

  // Get questions for a specific category
  static Future<List<TriviaQuestion>> getQuestions({
    required int categoryId,
    int amount = 10,
  }) async {
    String url = '$baseUrl/api.php?amount=$amount&category=$categoryId';
    final response = await http.get(Uri.parse(url));

    final data = json.decode(response.body);
    final List<dynamic> questionsJson = data['results'];

    return questionsJson
        .map((json) => TriviaQuestion.fromJson(json))
        .toList();
  }

  // Decode HTML entities
  static String decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}