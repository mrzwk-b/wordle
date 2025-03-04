import 'package:wordle/distribution.dart';
import 'package:wordle/optimizer.dart';

class PositionlessEvaluator implements Evaluator {
  @override
  int worstValue = 25600;

  Map<String, int> rankings;
  PositionlessEvaluator(Map<String, LetterDistribution> distribution):
    rankings = (() {
      final Map<String, int> letterTotals = distribution.map((key, value) => MapEntry(key, value.total),);
      final List<String> letters = letterTotals.keys.toList()..sort();
      final List<int> sortedTotals = letterTotals.values.toList()..sort(
        (int a, int b) => a == b ? 0 : a > b ? -1 : 1
      );
      return Map.fromEntries(List.generate(26, (i) => 
        MapEntry(letters[i], sortedTotals.indexOf(letterTotals[letters[i]]!))
      ));
    })()
  ;

  @override
  bool betterThan(int a, int b) => a < b;

  @override
  int evaluate(String word) {
    int value = word.split("").map((letter) => rankings[letter]!).reduce((a, b) => a + b);
    // punish double letters
    for (int i = 0; i < 5; i++) {
      for (int j = i + 1; j < 5; j++) {
        if (word[i] == word[j]) {
          value *= 2;
        }
      }
    }
    return value;
  }
}