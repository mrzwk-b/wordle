class LetterDistribution {
  int total;
  List<int> positionCounts;
  LetterDistribution(this.positionCounts): total = positionCounts.reduce((a,b)=>a+b);
  void add(int index, [int amount = 1]) {
    positionCounts[index] += amount;
    total += amount;
  }
}

Map<String, LetterDistribution> getDistribution(Set<String> options) {
  Map<String, LetterDistribution> distribution = {};
  for (final String word in options) {
    for (int i = 0; i < word.length; i++) {
      final String letter = word[i];
      if (!distribution.containsKey(letter)) {
        distribution[letter] = LetterDistribution(List.filled(5, 0));
      }
      distribution[letter]!.add(i);
    }
  }
  return distribution;
}