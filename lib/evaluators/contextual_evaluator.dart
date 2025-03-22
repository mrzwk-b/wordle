import 'package:wordle/data/distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

class ContextualEvaluator implements Evaluator {
  @override
  final int worstValue = 0;

  final Map<String, ContextualDistribution> distribution;
  ContextualEvaluator(this.distribution);

  @override
  int compare(int a, int b) => a - b;

  int evaluateLetter(final String word, final int letterIndex) =>
    distribution[word[letterIndex]]!.preceding.indexWhere(
      (tier) => tier.contains(letterIndex == 0 ? null : word[letterIndex-1])
    ) +
    distribution[word[letterIndex]]!.following.indexWhere(
      (tier) => tier.contains(letterIndex == 4 ? null : word[letterIndex+1])
    )
  ;

  @override
  int evaluate(final String word) {
    Map<String, int> letterValues = {};
    for (int i = 0; i < 5; i++) {
      letterValues.update(word[i],
        (oldValue) {
          int newValue = evaluateLetter(word, i);
          return newValue > oldValue ? newValue : oldValue;
        },
        ifAbsent: () => evaluateLetter(word, i),
      );
    }
    return letterValues.values.reduce((a,b)=>a+b);
  }
}