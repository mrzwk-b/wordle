import 'package:wordle/data/distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

class PositionalEvaluator implements Evaluator {
  final Map<String, List<int>> rankings;
  
  @override
  final int worstValue = 0;

  PositionalEvaluator(Map<String, FrequencyDistribution> distribution):
    rankings = (() {
      final Map<String, List<int>> rankings = {};
      for (final String letter in alphabet) {
        rankings[letter] = List.filled(5, 0);
      }
      for (int i = 0; i < 5; i++) {
        final List<int> countsInPosition = [];
        for (final String letter in alphabet) {
          countsInPosition.add(distribution[letter]!.positionCounts[i]);
        }
        countsInPosition.sort();
        for (final String letter in alphabet) {
          rankings[letter]![i] = countsInPosition.indexOf(distribution[letter]!.positionCounts[i]);
        }
      }
      return rankings;
    })()
  ;

  @override
  int compare(int a, int b) => a - b;

  @override
  int evaluate(final String word) {
    final Map<String, int> letterValues = {};
    for (int i = 0; i < 5; i++) {
      letterValues.update(word[i],
        (oldValue) => 
          (rankings[word[i]]![i] > oldValue
            ? rankings[word[i]]![i]
            : oldValue
          )
        ,
        ifAbsent: () => rankings[word[i]]![i]
      );
    }
    return letterValues.values.reduce((a,b)=>a+b);
  }
}