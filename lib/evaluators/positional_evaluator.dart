import 'package:wordle/data/letter_distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

class PositionalEvaluator extends Evaluator {
  final Map<String, List<int>> rankings = {};
  
  @override
  final int worstValue = 0;

  PositionalEvaluator(Map<String, FrequencyDistribution> distribution) {
    for (final String letter in alphabet) {
      rankings[letter] = List.filled(5, 0);
    }
    for (int i = 0; i < 5; i++) {
      final List<int> letterCountsInPosition = [];
      for (final String letter in alphabet) {
        letterCountsInPosition.add(distribution[letter]!.positionalCounts[i]);
      }
      letterCountsInPosition.sort();
      for (final String letter in alphabet) {
        rankings[letter]![i] = letterCountsInPosition.indexOf(distribution[letter]!.positionalCounts[i]);
      }
    }
  }

  @override
  int compare(int a, int b) => b - a;

  @override
  int evaluateLetter(String word, int index) => rankings[word[index]]![index];
}