import 'package:wordle/distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

class ContextualEvaluator implements Evaluator {
  @override
  final int worstValue = 0;

  final Map<String, ContextualDistribution> distribution;
  ContextualEvaluator(this.distribution);

  @override
  int compare(int a, int b) => a - b;

  @override
  int evaluate(String word) {
    Set<String> seen = {};
    int value = 0;
    for (int i = 0; i < 5; i++) {
      if (!seen.contains(word[i])) {
        String? context;
        // preceding
        context = i == 0 ? null : word[i-1];
        value += distribution[word[i]]!.preceding.indexOf(context);
        // following
        context = i == 4 ? null : word[i+1];
        value += distribution[word[i]]!.following.indexOf(context);

        seen.add(word[i]);
      }
    }
    return value;
  }
}