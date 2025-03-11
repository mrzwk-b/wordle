import 'dart:io';

import 'package:args/args.dart';
import 'package:wordle/distribution.dart';
import 'package:wordle/evaluators/contextual_evaluator.dart';
import 'package:wordle/evaluators/evaluator.dart';
import 'package:wordle/evaluators/positional_evaluator.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';
import 'package:wordle/scrape.dart';
import 'package:wordle/util.dart';

class QueryException implements Exception {
  String message;
  QueryException(this.message);
  @override String toString() => "QueryException: $message";
}

void main(List<String> argStrs) async {
  final ArgResults args = (ArgParser()
    ..addOption("today", abbr: 't')
  ).parse(argStrs);

  // scrape data and set up basic sets
  late final Set<String> possible;
  late final Set<String> past;
  for (final Future assignment in [
    getPossibleAnswers().then((result) {possible = result;}),
    getPastAnswers().then((result) {past = result;}),
  ]) await assignment;
  if (args.option("today") != null) {
    past.add(args.option("today")!);
  }
  final Set<String> options = possible.difference(past);

  // process interesting data
  final Map<String, FrequencyDistribution> frequencyDistribution = getFrequencyDistributions(options);
  final List<String> frequencyRankings = rank(frequencyDistribution.map(
    (letter, distribution) => MapEntry(letter, distribution.total)
  ));
  final Map<String, ContextualDistribution> contextualDistribution = getContextualDistributions(options);
  final Map<String, Evaluator> evaluators = {
    "positionless": PositionlessEvaluator(frequencyDistribution),
    "positional": PositionalEvaluator(frequencyDistribution),
    "contextual": ContextualEvaluator(contextualDistribution),
  };
  final Map<String, Map<String, int>> evaluations = 
    Map.fromEntries(evaluators.entries.map((entry) => 
      MapEntry(
        entry.key,
        Map.fromIterable(options, 
          key: (word) => word,
          value: (word) => entry.value.evaluate(word)
        )
      )
    ))
  ;
  final Map<String, List<String>> rankings = 
    Map.fromEntries(evaluations.entries.map((entry) => 
      MapEntry(
        entry.key,
        rank(entry.value)
      )
    ));
  ;

  // accept queries
  while (true) {
    print("enter a query:");
    try {
      List<String> query = stdin.readLineSync().toString().split(" ");
      if (query.length == 1) {
        // data on single letter
        if (query.single.length == 1) {
          String letter = query.single;
          if (!RegExp("[a-z]").hasMatch(letter)) {
            throw QueryException("expected letter, found ${letter}");
          }
          print(
            "${frequencyDistribution[letter]!.positionCounts}\n"
            "total: ${frequencyDistribution[letter]!.total}, "
            "${frequencyRankings.indexOf(letter) + 1} / 26"
          );
          print(
            "preceding: {\n  ${[
              for (String? antecedent in contextualDistribution[letter]!.preceding) "${antecedent ?? '#'}"
            ].join(", ")}\n}"
          );
          print(
            "following: {\n  ${[
              for (String? sequent in contextualDistribution[letter]!.following) "${sequent ?? '#'}"
            ].join(", ")}\n}"
          );
        }
        // data on word
        else if (query.single.length == 5) {
          Iterable<RegExpMatch> matches = RegExp("[a-z]{5}").allMatches(query.single);
          if (matches.length != 1) {
            throw QueryException("expected single 5 letter word in query, found ${
              [for (RegExpMatch match in matches) match.group(0)]
            }");
          }
          String word = matches.single.group(0)!;
          // what sets is it in
          if (!options.contains(word)) {
            print(past.contains(word) ? "already been used" : "not an answer");
          }
          // rank and score for a word from each evaluator
          else {
            for (String evaluatorName in evaluators.keys) {
              print(
                "$evaluatorName: "
                "${evaluations[evaluatorName]![word]} pts, "
                "${rankings[evaluatorName]!.indexOf(word) + 1} / ${options.length}"
              );
            }
          }
        }
      }
      // data from evaluator
      else {
        if (query.length > 3) {
          throw (QueryException("expected 2-3 arguments for evaluator query"));
        }
        final String evaluatorName = query[0];
        if (!evaluators.keys.contains(query[0])) {
          throw QueryException("expected $query to be an evaluator name");
        }
        late final int count;
        try {
          count = int.parse(query[1]);
        }
        catch (e) {
          throw QueryException("expected number after evaluator name, found ${query[1]}");
        }
        final bool decreasing = query.length == 2;
        if (!decreasing && query[2] != "inc") {
          throw QueryException('expected "inc", found "${query[2]}');
        }
        // get a list of a [length] items from the top or bottom of rankings for the given evaluator
        for (String word in (decreasing ?
          rankings[evaluatorName]! : rankings[evaluatorName]!.reversed
        ).take(count)) {
          print(
            "$word: "
            "${evaluations[evaluatorName]![word]} pts, "
            "${rankings[evaluatorName]!.indexOf(word) + 1} / ${options.length}"
          );
        }
      }
    }
    catch (e) {
      print(e);
    }
    print("");
  }
}