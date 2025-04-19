import 'dart:math';

import 'package:wordle/data/data.dart';
import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/guess_query.dart';
import 'package:wordle/queries/query.dart';
import 'package:wordle/utils.dart';

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
      branch(Data(data.possible, {}), "GRID_QUERY_CLEAR_PAST");
    }
  }

  /// determines whether `guess` would've yielded `response` given `answer`
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

  /// gets all possible sequences of guesses for `grid`
  /// given the current state of `data.options`
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
        moveBack(count: 1);
        prune();
      }
    }
    return (possibilities.length == 0)
      ? null
      : possibilities
    ;
  }

  /// generates a list of lines for displaying the contents of `tree`
  List<String> treeAsLines(Tree<String> tree) => [
    "${tree.value}",
    for (Tree<String> child in tree.children)
      for (String line in treeAsLines(child))
        "| $line"
  ];

  /// generates a list of the set of words that match the response given at each guess
  List<Set<String>> orderedGuessOptions(List<Tree<String>> trees) => [
    if (trees.isNotEmpty) {for (Tree<String> tree in trees) tree.value},
    for (Set<String> guesses in (trees.isEmpty
      ? []
      : (trees
        .map((tree) => orderedGuessOptions(tree.children))
        .reduce((a, b) => [for (int i = 0; i < max(a.length, b.length); i++)
          (i < a.length && i < b.length
            ? a[i].union(b[i])
            : (i < a.length
              ? a[i]
              : b[i]
            )
          )
        ])
      )
    )) guesses
  ];

  @override
  String report() {
    List<Set<String>> orderedGuesses = orderedGuessOptions(explorePossibilities(responses) ?? []);
    String result = [
      for (int i = 0; i < orderedGuesses.length; i++) [
        "guess ${i+1}:",
        for (String guess in orderedGuesses[i]) "- $guess"
      ].join('\n')
    ].join('\n');
    if (usePast) {
      moveBack(name: "GRID_QUERY_CLEAR_PAST");
      prune("GRID_QUERY_CLEAR_PAST");
    }
    return result;
  }
}