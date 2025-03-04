import 'package:wordle/distribution.dart';
import 'package:wordle/optimizer.dart';

class ContextlessPositionalEvaluator implements Evaluator {
  final Map<String, List<int>> rankings;
  
  @override
  int worstValue = 25600; // TODO

  ContextlessPositionalEvaluator(Map<String, LetterDistribution> distribution):
    rankings = (() {
      final Map<String, List<int>> rankings = {};
      final List<String> letters = distribution.keys.toList();
      for (final String letter in letters) {
        rankings[letter] = List.filled(5, 0);
      }
      for (int i = 0; i < 5; i++) {
        final List<int> countsInPosition = [];
        for (final String letter in letters) {
          countsInPosition.add(distribution[letter]!.positionCounts[i]);
        }
        countsInPosition.sort();
        for (final String letter in letters) {
          rankings[letter]![i] = countsInPosition.indexOf(distribution[letter]!.positionCounts[i]);
        }
      }
      return rankings;
    })()
  ;

  @override
  bool betterThan(int a, int b) => a < b;

  @override
  int evaluate(String word) {
    List<String> letters = word.split("");
    int value = 0;
    for (int i = 0; i < 5; i++) {
      value += rankings[letters[i]]![i];
    }
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