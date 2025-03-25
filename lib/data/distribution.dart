import 'package:wordle/data/data.dart';

final Set<String> alphabet = "abcdefghijklmnopqrstuvwxyz".split("").toSet();

class FrequencyDistribution {
  int total;
  List<int> positionCounts;
  FrequencyDistribution(this.positionCounts): total = positionCounts.reduce((a,b)=>a+b);
  void add(int index, [int amount = 1]) {
    positionCounts[index] += amount;
    total += amount;
  }
}

Map<String, FrequencyDistribution> getFrequencyDistributions(Iterable<String> words) {
  final Map<String, FrequencyDistribution> distributions = {
    for (String letter in alphabet) letter: FrequencyDistribution(List.filled(5, 0))
  };
  for (final String word in words) {
    for (int i = 0; i < word.length; i++) {
      distributions[word[i]]!.add(i);
    }
  }
  return distributions;
}

/// contains lists of letters sorted by how common they are preceding and following a letter,
/// least common to most common
/// 
/// the `null` item in each list indicates a word boundary
class ContextualDistribution {
  List<Set<String?>> preceding;
  List<Set<String?>> following;
  ContextualDistribution(this.preceding, this.following);
}

Map<String, ContextualDistribution> getContextualDistributions(Iterable<String> words) {
  // maps for counting frequencies of occurrence for each letter combination
  final Map<String, Map<String?, int>> antecedents = {
    for (final String letter in alphabet) letter: {
      for (final String letter in alphabet) letter: 0
    }..[null] = 0
  };
  final Map<String, Map<String?, int>> sequents = {
    for (final String letter in alphabet) letter: {
      for (final String letter in alphabet) letter: 0
    }..[null] = 0
  };
  // count frequencies
  for (final String word in words) {
    for (int i = 0; i < 5; i++) {
      // antecedent
      if (i == 0) {
        antecedents[word[i]]!.update(null, (count) => count + 1);
      }
      else {
        antecedents[word[i]]!.update(word[i-1], (count) => count + 1);
      }
      // sequent
      if (i == 4) {
        sequents[word[i]]!.update(null, (count) => count + 1);
      }
      else {
        sequents[word[i]]!.update(word[i+1], (count) => count + 1);
      }
    }
  }
  return {
    for (final String letter in alphabet) letter: ContextualDistribution(
      rankWithTies(antecedents[letter]!, increasing: true),
      rankWithTies(sequents[letter]!, increasing: true)
    )
  };
}