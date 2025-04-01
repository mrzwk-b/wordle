import 'package:wordle/data/data_manager.dart';
import 'package:wordle/data/distribution.dart';
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
        "${data.frequencyDistributions[l]!.positionCounts} "
        "total: ${data.frequencyDistributions[l]!.total}, "
      ].join('\n');
    }
    else {
      return [
          "${data.frequencyDistributions[letter]!.positionCounts} occurences in each position",
          "${[for (int i = 0; i < 5; i++)
            (
              data.frequencyDistributions.values.map(
                (v) => v.positionCounts[i]
              ).toList()..sort()
            ).reversed.toList().indexOf(
              data.frequencyDistributions[letter]!.positionCounts[i]
            ) + 1
          ]}th most common out of 26 in each position",

          "total: ${data.frequencyDistributions[letter]!.total}, "
          "${data.frequencyRankings.indexOf(letter!) + 1} / 26",

          "preceding: {\n${[
            for (Set<String?> antecedentTier in data.contextualDistributions[letter]!.preceding.reversed) "  { ${
              [for (String? antecedent in antecedentTier) "${antecedent ?? '#'}"].join(', ')
            } }"
          ].join(",\n")}\n}",

          "following: {\n${[
            for (Set<String?> sequentTier in data.contextualDistributions[letter]!.following.reversed) "  { ${
              [for (String? sequent in sequentTier) "${sequent ?? '#'}"].join(', ')
            } }"
          ].join(",\n")}\n}"
        ].join('\n');
    }
  }
}