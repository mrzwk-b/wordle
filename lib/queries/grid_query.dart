import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/guess_query.dart';
import 'package:wordle/queries/query.dart';
import 'package:wordle/queries/state_query.dart';

class Tree<T> {
  final T value;
  final List<Tree<T>> children;
  Tree(this.value, [this.children = const []]);
}

class GridQuery extends Query {
  final String answer;
  final List<String> responses;
  final Map<String, int> answerLetterCounts;
  GridQuery(final String answer, this.responses):
    answer = answer,
    answerLetterCounts = Map.fromIterable(answer.split("").toSet(),
      key: (letter) => letter,
      value: (letter) => answer.split("").where((slot) => slot == letter).length,
    )
  ;

  bool isValidGuess(final String guess, final String answer, final String response) {
    Map<String, int> guessLetterCounts = Map.fromIterable(guess.split("").toSet(),
      key: (letter) => letter,
      value: (_) => 0,
    );

    for (int i = 0; i < 5; i++) {
      switch (response[i]) {
        case 'b': {
          if (
            answerLetterCounts.keys.contains(guess[i]) &&
            answerLetterCounts[guess[i]]! > guessLetterCounts[guess[i]]!
          ) {
            return false;
          }
        }
        case 'g': {
          if (answer[i] != guess[i]) {
            return false;
          }
          guessLetterCounts.update(guess[i], (count) => count + 1);
        }
        case 'y': {
          if (
            !answerLetterCounts.keys.contains(guess[i]) ||
            answerLetterCounts[guess[i]]! <= guessLetterCounts[guess[i]]!
          ) {
            return false;
          }
          guessLetterCounts.update(guess[i], (count) => count + 1);
        }
        default: {
          throw StateError('cannot process a response with non-"byg" elements');
        }
      }
    }

    return true;
  }

  List<Tree<String>>? explorePossibilities(List<String> grid) {
    if (grid.length == 0) {
      return [];
    }
    if (data.options.length == 0) {
      return null;
    }

    List<Tree<String>> possibilities = [];
    for (final String guess in data.options) {
      if (isValidGuess(guess, answer, grid.first)) {
        GuessQuery(guess, grid.first).execute();
        List<Tree<String>>? pathsFromGuess = explorePossibilities(grid.sublist(1));
        if (pathsFromGuess != null) {
          possibilities.add(Tree(guess, pathsFromGuess));
        }
        StateQuery(word: guess).execute();
      }
    }
    return (possibilities.length == 0)
      ? null
      : possibilities
    ;
  }

  String displayTree(Tree<String> tree) => [
    "${tree.value}",
    for (Tree<String> child in tree.children) "  ${displayTree(child)}"
  ].join('\n');

  @override
  String report() => [
    for (Tree<String> tree in explorePossibilities(responses) ?? []) (
      displayTree(tree)
    )
  ].join("\n\n");
}