import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:quiz_app/screens/result_screen.dart';
import 'package:quiz_app/screens/home_screen.dart';
import 'package:quiz_app/models/quiz_models.dart';
import 'package:quiz_app/services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String title;
  final int categoryId;

  const QuizScreen({super.key, required this.title, required this.categoryId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int timer = 30;
  Timer? countdown;
  bool answered = false;
  int? selectedIndex;
  int score = 0;

  List<TriviaQuestion> apiQuestions = [];
  List<Map<String, dynamic>> questions = [];
  List<int?> selectedAnswers = [];
  List<List<String>> shuffledAnswersForEachQuestion = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final fetchedQuestions = await TriviaApiService.getQuestions(
        categoryId: widget.categoryId,
        amount: 5,
      );

      // Convert API questions to the format ResultScreen expects
      List<Map<String, dynamic>> formattedQuestions = [];
      List<List<String>> allShuffledAnswers = [];

      for (var apiQ in fetchedQuestions) {
        // Shuffle answers for this question
        final shuffledAnswers = [...apiQ.incorrectAnswers, apiQ.correctAnswer];
        shuffledAnswers.shuffle();
        allShuffledAnswers.add(shuffledAnswers);

        formattedQuestions.add({
          "question": TriviaApiService.decodeHtmlEntities(apiQ.question),
          "options": shuffledAnswers.map((ans) => TriviaApiService.decodeHtmlEntities(ans)).toList(),
          "answer": TriviaApiService.decodeHtmlEntities(apiQ.correctAnswer),
          "description": "Answer explanation for ${TriviaApiService.decodeHtmlEntities(apiQ.correctAnswer)}",
        });
      }

      setState(() {
        apiQuestions = fetchedQuestions;
        questions = formattedQuestions;
        shuffledAnswersForEachQuestion = allShuffledAnswers;
        selectedAnswers = List.filled(questions.length, null);
        isLoading = false;
      });
      startTimer();
    } catch (e) {
      // Handle error - maybe show error dialog or go back
      Navigator.pop(context);
    }
  }

  void startTimer() {
    timer = 30;
    countdown?.cancel();
    countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timer > 0) {
        setState(() {
          timer--;
        });
      } else {
        t.cancel();
        setState(() {
          answered = true;
        });

        Future.delayed(const Duration(seconds: 1), () {
          goToNext();
        });
      }
    });
  }

  void checkAnswer(int index) {
    if (answered || isLoading) return;

    final currentQ = questions[currentQuestion];
    final selectedAnswer = currentQ["options"][index];

    setState(() {
      selectedIndex = index;
      answered = true;
      selectedAnswers[currentQuestion] = index;
      if (selectedAnswer == currentQ["answer"]) {
        score++;
      }
      countdown?.cancel();
    });
  }

  void goToNext() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedIndex = null;
        answered = false;
        startTimer();
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: score,
            questions: questions,
            selectedAnswers: selectedAnswers,
          ),
          settings: RouteSettings(
            arguments: {
              'categoryTitle': widget.title,
              'categoryId': widget.categoryId,
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C0712),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final q = questions[currentQuestion];

    return Scaffold(
      backgroundColor: const Color(0xFF0C0712),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back and progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Text(
                  "${currentQuestion + 1} of ${questions.length}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (currentQuestion + 1) / questions.length,
              color: Colors.orange,
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 20),

            // Timer
            Center(
              child: CircularPercentIndicator(
                radius: 40,
                lineWidth: 8,
                percent: timer / 30,
                center: Text(
                  '$timer',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                progressColor: Colors.orange,
                backgroundColor: Colors.white12,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ),
            const SizedBox(height: 20),

            // Question box with proper space
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: screenHeight * 0.15,
                maxHeight: screenHeight * 0.3,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF20123A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Question ${currentQuestion + 1}".toUpperCase(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(widget.title, style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          q["question"],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options
            ...List.generate(q["options"].length, (index) {
              final option = q["options"][index];
              final isCorrect = option == q["answer"];
              final isSelected = selectedIndex == index;

              Color borderColor = Colors.white12;
              Color textColor = Colors.white;
              Icon? icon;

              if (answered) {
                if (isSelected && isCorrect) {
                  borderColor = Colors.green;
                  textColor = Colors.green;
                  icon = const Icon(Icons.check, color: Colors.green);
                } else if (isSelected && !isCorrect) {
                  borderColor = Colors.red;
                  textColor = Colors.red;
                  icon = const Icon(Icons.close, color: Colors.red);
                } else if (isCorrect) {
                  borderColor = Colors.green;
                  textColor = Colors.green;
                  icon = const Icon(Icons.check, color: Colors.green);
                }
              }

              return GestureDetector(
                onTap: () => checkAnswer(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: answered && isCorrect
                        ? Colors.green.withOpacity(0.2)
                        : (isSelected && answered && !isCorrect)
                        ? Colors.red.withOpacity(0.1)
                        : Colors.white10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      if (icon != null) icon,
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: answered ? goToNext : null,
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}