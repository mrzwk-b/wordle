import 'package:wordle/data/data.dart';
import 'package:wordle/queries/query.dart';

class LetterQuery extends Query {
  String letter;
  LetterQuery(this.letter) {
    if (letter.length != 1) {
      throw QueryException('LetterQuery requires argument of length 1, received "$letter"');
    }
    letter = letter.toLowerCase();
    if (!RegExp("[a-z]").hasMatch(letter)) {
      throw QueryException('LetterQuery requires alphabetic input, received "$letter"');
    }
  }

  @override
  String execute() =>
    "${frequencyDistribution[letter]!.positionCounts}\n"
    "total: ${frequencyDistribution[letter]!.total}, "
    "${frequencyRankings.indexOf(letter) + 1} / 26\n"
    "preceding: {\n  ${[
      for (String? antecedent in contextualDistribution[letter]!.preceding) "${antecedent ?? '#'}"
    ].join(", ")}\n}\n"
    "following: {\n  ${[
      for (String? sequent in contextualDistribution[letter]!.following) "${sequent ?? '#'}"
    ].join(", ")}\n}"
  ;
}