import 'package:wordle/data/word_data.dart';
import 'package:wordle/data/data_tree.dart';
import 'package:wordle/data/letter_distribution.dart';
import 'package:wordle/queries/expression_query.dart';
import 'package:wordle/queries/query.dart';

class RestrictQuery extends Query {
  final String pattern;
  final Map<String, int> include;
  final Set<String> exclude;
  final bool negate;

  RestrictQuery(this.pattern, {this.include = const {}, this.exclude = const {}, this.negate = false}) {
    Iterable<RegExpMatch> matches = RegExp('[^a-z0-9${
      (specialCharacters.toSet()..remove('?')).join()
    }]').allMatches(pattern);
    if (matches.length != 0) {
      throw QueryException(
        '"${matches.map((match) => match.group(0)).join('", "')}" '
        '${matches.length > 1 ? 'are not valid characters' : 'is not a valid character'} '
        'of a RestrictQuery'
      );
    }
    for (final String letter in include.keys) {
      if (!alphabet.contains(letter)) {
        throw QueryException(
          '$letter is not a letter, '
          'cannot be a required inclusion for a RestrictQuery'
        );
      }
    }
    for (final String letter in exclude) {
      if (!alphabet.contains(letter)) {
        throw QueryException(
          '$letter is not a letter, '
          'cannot be a required exclusion for a RestrictQuery'
        );
      }
    }
  }

  @override
  String report() {
    branch(
      Data(
        ExpressionQuery(
          pattern,
          include: include,
          exclude: exclude,
          negate: negate
        ).executeFixed().toSet(),
        data.past
      ),
      "$pattern"
      "${include.isEmpty ? "" : " +${include.entries.map((entry) => entry.key * entry.value).join()}"}"
      "${exclude.isEmpty ? "" : " -${exclude.join()}"}"
      "${!negate ? "" : " !"}"
    );
    return "update complete, now ${data.options.length} possible words";
  }
}