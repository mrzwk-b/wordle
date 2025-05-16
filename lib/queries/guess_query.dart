import 'package:wordle/data/word_data.dart';
import 'package:wordle/data/data_tree.dart';
import 'package:wordle/queries/query.dart';

class GuessQuery extends Query {
  final String word;
  final String result;
  GuessQuery(this.word, this.result);

  Set<String> reflectChange({
    final List<String?> blank = const [],
    final List<String?> yellow = const [],
    final List<String?> green = const []
  }) {
    Set<String> possible = data.possible.toSet();
    // get the letters that need to be included
    final Map<String, int> include = {};
    for (final String? letter in yellow) {
      if (letter != null) {
        include.update(letter, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    // get the letters that need to be excluded
    final Set<String> forbidden = {};
    for (final String? letter in blank) {
      if (letter != null) {
        forbidden.add(letter);
      }
    }
    // filter [possible]
    for (final String word in possible.toList(growable: false)) {
      final Map<String, int> letterCounts = {};
      // scan word for illegal letters
      for (int i = 0; i < 5; i++) {
        // if there is a green to check
        if (green[i] != null) {
          // remove if it's not satisfied
          if (green[i] != word[i]) {
            possible.remove(word);
            break;
          }
        }
        else {
          // if letter in position is illegal, remove
          if (forbidden.contains(word[i]) || yellow[i] == word[i]) {
            possible.remove(word);
            break;
          }
          // take count for comparison with [include]
          letterCounts.update(word[i], (count) => count + 1, ifAbsent: () => 1);
        }
      }
      // make sure all values in [include] are accounted for
      for (final String letter in include.keys) {
        if ((letterCounts[letter] ?? 0) < include[letter]!) {
          possible.remove(word);
          break;
        }
      }
    }
    return possible;
  }

  void execute() {
    List<String?> blank = List.filled(5, null);
    List<String?> yellow = List.filled(5, null);
    List<String?> green = List.filled(5, null);
    for (int i = 0; i < 5; i++) {
      switch (result[i]) {
        case 'b':
          blank[i] = word[i];
        case 'y':
          yellow[i] = word[i];
        case 'g':
          green[i] = word[i];
        default:
          throw QueryException(
            'result argument of GuessQuery must contain only the letters "b", "y", & "g", found ${result[i]}'
          );
      }
    }
    Set<String> possible = reflectChange(blank: blank, yellow: yellow, green: green);
    branch(Data(possible, data.past), "$word $result");
  }

  @override
  String report() {
    execute();
    return "update complete, now ${data.options.length} possible words";
  } 
}