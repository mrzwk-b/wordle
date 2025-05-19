import 'package:wordle/data/data_tree.dart';
import 'package:wordle/data/letter_distribution.dart';
import 'package:wordle/queries/query.dart';

class LetterQuery extends Query {
  String? letter;
  LetterQuery([this.letter]) {
    if (letter != null) {
      if (letter!.length != 1) {
        throw QueryException('LetterQuery requires argument of length 1, received "$letter"');
      }
      letter = letter!.toLowerCase();
      if (!alphabet.contains(letter!)) {
        throw QueryException('LetterQuery requires alphabetic input, received "$letter"');
      }
    }
  }

  @override
  String report() {
    if (letter == null) {
      return [for (String l in data.frequencyRankings)
        "$l: "
        "${data.frequencyDistributions[l]!.positionalCounts} "
        "total: ${data.frequencyDistributions[l]!.total}, "
      ].join('\n');
    }
    else {
      return [
          "${data.frequencyDistributions[letter]!.positionalCounts} occurences in each position",
          "${[for (int i = 0; i < 5; i++)
            (
              data.frequencyDistributions.values.map(
                (v) => v.positionalCounts[i]
              ).toList()..sort()
            ).reversed.toList().indexOf(
              data.frequencyDistributions[letter]!.positionalCounts[i]
            ) + 1
          ]}th most common out of 26 in each position",

          "total: ${data.frequencyDistributions[letter]!.total}, "
          "${data.frequencyRankings.indexOf(letter!) + 1} / 26",

          "preceding:",
          for (String line in [
            for (Set<String?> antecedentTier in data.contextualDistributions[letter]!.preceding.reversed) 
              "{ ${[for (String? antecedent in antecedentTier) "${antecedent ?? '#'}"].join(', ')} }: "
              "${data.contextualDistributions[letter]!.precedingCounts[antecedentTier.first]}"
            ,
          ]) "  $line",

          "following:",
          for (String line in [
            for (Set<String?> sequentTier in data.contextualDistributions[letter]!.following.reversed) 
              "{ ${[for (String? sequent in sequentTier) "${sequent ?? '#'}"].join(', ')} }: "
              "${data.contextualDistributions[letter]!.followingCounts[sequentTier.first]}"
            ,
          ]) "  $line",
        ].join('\n');
    }
  }
}