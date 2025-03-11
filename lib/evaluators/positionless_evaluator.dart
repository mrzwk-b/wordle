import 'package:wordle/distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

class PositionlessEvaluator implements Evaluator {
  @override
  final int worstValue = 0;

  final Map<String, int> rankings;
  PositionlessEvaluator(Map<String, FrequencyDistribution> distribution):
    rankings = (() {
      final Map<String, int> letterTotals = distribution.map((key, value) => MapEntry(key, value.total),);
      final List<String> letters = letterTotals.keys.toList();
      final List<int> sortedTotals = letterTotals.values.toList()..sort();
      return Map.fromEntries(List.generate(26, (i) => 
        MapEntry(letters[i], sortedTotals.indexOf(letterTotals[letters[i]]!))
      ));
    })()
  ;

  @override
  int compare(int a, int b) => a - b;

  @override
  int evaluate(String word) {
    final Set<String> seen = {};
    final List<String> letters = word.split("");
    int value = 0;
    for (int i = 0; i < 5; i++) {
      if (!seen.contains(letters[i])) {
        value += rankings[letters[i]]!;
        seen.add(letters[i]);
      }
    }
    return value;
  }
}