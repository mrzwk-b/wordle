import 'package:wordle/queries/expression_query.dart';

abstract class Evaluator {
  final int worstValue = 0;
  int compare(int a, int b);
  int evaluateLetter(String word, int index);

  int evaluate(String word, [int vowelTolerance = 5]) {
    Set<String> seen = {};
    int vowelsSeen = 0;
    int strikes = 0;
    int total = 0;
    for (int i = 0; i < 5; i++) {
      bool isVowel = vowels.contains(word[i]);
      vowelsSeen += isVowel ? 1:0;
      if (isVowel && vowelsSeen > vowelTolerance) {
        strikes += 1;
      }

      if (seen.contains(word[i])) {
        strikes += 1;
      }
      else {
        seen.add(word[i]);
      }

      total += evaluateLetter(word, i);
    }

    int Function(int) adjust = (compare(0, 1) > 0 
      ? (x) => x ~/ 2
      : (x) => x *  2
    );
    for (int i = 0; i < strikes; i++) {
      total = adjust(total);
    }

    return total;
  }
}