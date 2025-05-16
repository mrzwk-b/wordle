import 'package:wordle/data/letter_distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

class PositionlessEvaluator extends Evaluator {
  @override
  final int worstValue = 0;

  final Map<String, int> rankings;
  PositionlessEvaluator(Map<String, FrequencyDistribution> distribution):
    rankings = (() {
      final Map<String, int> letterTotals = distribution.map((key, value) => MapEntry(key, value.total));
      return {for (String letter in alphabet) 
        letter: (letterTotals.values.toList()..sort()).indexOf(letterTotals[letter]!)
      };
    })()
  ;

  @override
  int compare(int a, int b) => b - a;

  @override
  int evaluateLetter(String word, int index) => rankings[word[index]]!;
}