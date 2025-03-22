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
    DataManager dm = DataManager();
    return (letter == null ? 
      [for (String l in dm.data.frequencyRankings)
        "$l: "
        "${dm.data.frequencyDistribution[l]!.positionCounts} "
        "total: ${dm.data.frequencyDistribution[l]!.total}, "
      ].join('\n')
    :
      "${dm.data.frequencyDistribution[letter]!.positionCounts}\n"
      "total: ${dm.data.frequencyDistribution[letter]!.total}, "
      "${dm.data.frequencyRankings.indexOf(letter!) + 1} / 26\n"
      "preceding: {\n${[
        for (Set<String?> antecedentTier in dm.data.contextualDistribution[letter]!.preceding) "  { ${
          [for (String? antecedent in antecedentTier) "${antecedent ?? '#'}"].join(', ')
        } }"
      ].join(",\n")}\n}\n"
      "following: {\n${[
        for (Set<String?> sequentTier in dm.data.contextualDistribution[letter]!.following) "  { ${
          [for (String? sequent in sequentTier) "${sequent ?? '#'}"].join(', ')
        } }"
      ].join(",\n")}\n}"
    );
  }
}