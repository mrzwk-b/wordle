abstract interface class Evaluator {
  final int worstValue = 0;
  bool betterThan(int a, int b);
  int evaluate(String word);
}

String optimal(
  Iterable<String> options,
  Evaluator evaluator,
) {
  int bestValue = evaluator.worstValue;
  String bestWord = "";
  for (String word in options) {
    int value = evaluator.evaluate(word);
    if (evaluator.betterThan(value, bestValue)) {
      bestValue = value;
      bestWord = word;
    }
  }
  if (bestWord.length != 5) throw ArgumentError("no word with value better than [start] found");
  return bestWord;
}