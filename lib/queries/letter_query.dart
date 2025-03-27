import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/query.dart';

class LetterQuery extends Query {
  String? letter;
  LetterQuery([this.letter]) {
    if (letter != null) {
      if (letter!.length != 1) {
        throw QueryException('LetterQuery requires argument of length 1, received "$letter"');
      }
      letter = letter!.toLowerCase();
      if (!RegExp("[a-z]").hasMatch(letter!)) {
        throw QueryException('LetterQuery requires alphabetic input, received "$letter"');
      }
    }
  }

  @override
  String execute() {
    return (letter == null ? 
      [for (String l in data.frequencyRankings)
        "$l: "
        "${data.frequencyDistribution[l]!.positionCounts} "
        "total: ${data.frequencyDistribution[l]!.total}, "
      ].join('\n')
    :
      "${data.frequencyDistribution[letter]!.positionCounts}\n"
      "total: ${data.frequencyDistribution[letter]!.total}, "
      "${data.frequencyRankings.indexOf(letter!) + 1} / 26\n"
      "preceding: {\n${[
        for (Set<String?> antecedentTier in data.contextualDistribution[letter]!.preceding) "  { ${
          [for (String? antecedent in antecedentTier) "${antecedent ?? '#'}"].join(', ')
        } }"
      ].join(",\n")}\n}\n"
      "following: {\n${[
        for (Set<String?> sequentTier in data.contextualDistribution[letter]!.following) "  { ${
          [for (String? sequent in sequentTier) "${sequent ?? '#'}"].join(', ')
        } }"
      ].join(",\n")}\n}"
    );
  }
}