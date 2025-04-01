import 'package:wordle/data/distribution.dart';
import 'package:wordle/evaluators/evaluator.dart';

enum LetterLocation {
  There, Elsewhere, Nowhere
}

class BalancingEvaluator implements Evaluator {
  late final Map<String, List<Map<LetterLocation, int>>> distribution;
  final int optionsCount;
  BalancingEvaluator(final Map<String, FrequencyDistribution> freqDist, this.optionsCount) {
    Map<String, int> nowhereCounts = freqDist.map((letter, dist) => MapEntry(letter, optionsCount - dist.total));
    distribution = freqDist.map((letter, frequencies) => MapEntry(
      letter,
      [for (int i = 0; i < 5; i++) {
        LetterLocation.There: frequencies.positionCounts[i],
        LetterLocation.Elsewhere: frequencies.total - frequencies.positionCounts[i],
        LetterLocation.Nowhere: nowhereCounts[letter]!,
      }]
    ));
  }

  @override
  int compare(int a, int b) => a - b;

  int evaluateLetter(final String letter, final int index) {
    final int there = distribution[letter]![index][LetterLocation.There]!;
    final int elsewhere = distribution[letter]![index][LetterLocation.Elsewhere]!;
    final int nowhere = distribution[letter]![index][LetterLocation.Nowhere]!;
    return 
      (there - elsewhere).abs() +
      (elsewhere - nowhere).abs() +
      (nowhere - there).abs()
    ;
  }

  @override
  int evaluate(String word) {
    Set<String> seen = {};
    int total = 0;
    for (int i = 0; i< 5; i++) {
      total += evaluateLetter(word[i], i);
      if (seen.contains(word[i])) {
        total *= 2;
      }
      else {
        seen.add(word[i]);
      }
    }
    return total;
  }

  @override
  int get worstValue => 
    optionsCount * 2 // maximum sum of differences
    * 5 // for each slot in the word
    * 32 // doubled for each slot in the word
  ;
  
}