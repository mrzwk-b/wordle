import 'package:wordle/data/distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

class ContextualEvaluator extends Evaluator {
  @override
  final int worstValue = 0;

  final Map<String, ContextualDistribution> distribution;
  ContextualEvaluator(this.distribution);

  @override
  int compare(int a, int b) => b - a;

  int evaluateLetter(final String word, final int index) =>
    distribution[word[index]]!.preceding.indexWhere(
      (tier) => tier.contains(index == 0 ? null : word[index-1])
    ) +
    distribution[word[index]]!.following.indexWhere(
      (tier) => tier.contains(index == 4 ? null : word[index+1])
    )
  ;
}