import 'package:wordle/data/data.dart';
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
  final bool usePast;
  GridQuery(final String answer, this.responses, {this.usePast = false}):
    answer = answer,
    answerLetterCounts = Map.fromIterable(answer.split("").toSet(),
      key: (letter) => letter,
      value: (letter) => answer.split("").where((slot) => slot == letter).length,
    )
  {
    if (usePast) {
      push(Data(data.possible, {}), "GRID_QUERY_CLEAR_PAST");
    }
  }

  bool isValidGuess(final String guess, final String answer, final String response) {
    Map<String, int> guessLetterCounts = Map.fromIterable(guess.split("").toSet(),
      key: (letter) => letter,
      value: (_) => 0,
    );

    // add greens to letter counts before main loop
    for (int i = 0; i < 5; i++) {
      if (answer[i] == guess[i]) {
        guessLetterCounts.update(guess[i], (count) => count + 1);
      }
    }

    for (int i = 0; i < 5; i++) {
      switch (response[i]) {
        case 'g': {
          if (answer[i] != guess[i]) {
            return false;
          }
        }
        case 'y': {
          if (
            answer[i] == guess[i] ||
            !answerLetterCounts.keys.contains(guess[i]) ||
            answerLetterCounts[guess[i]]! <= guessLetterCounts[guess[i]]!
          ) {
            return false;
          }
          guessLetterCounts.update(guess[i], (count) => count + 1);
        }
        case 'b': {
          if (
            answerLetterCounts.keys.contains(guess[i]) &&
            answerLetterCounts[guess[i]]! > guessLetterCounts[guess[i]]!
          ) {
            return false;
          }
        }
        default: {
          throw StateError('cannot process a response with non-"byg" elements');
        }
      }
    }

    return true;
  }

  List<Tree<String>>? explorePossibilities(List<String> grid) {
    if (grid.length == 0 && data.options.length == 1) {
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
        StateQuery(count: 1).execute();
      }
    }
    return (possibilities.length == 0)
      ? null
      : possibilities
    ;
  }

  List<String> displayTree(Tree<String> tree) => [
    "${tree.value}",
    for (Tree<String> child in tree.children)
      for (String line in displayTree(child))
        "| $line"
  ];

  @override
  String report() {
    String result = [
      for (Tree<String> tree in explorePossibilities(responses) ?? []) (
        displayTree(tree).join('\n')
      )
    ].join("\n\n");
    if (usePast) {
      pop(word: "GRID_QUERY_CLEAR_PAST");
    }
    return result;
  }
}