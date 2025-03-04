import 'dart:io';

import 'package:args/args.dart';
import 'package:wordle/distribution.dart';
import 'package:wordle/evaluators/contextless_positional_evaluator.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';
import 'package:wordle/optimizer.dart';
import 'package:wordle/scrape.dart';

void main(List<String> argStrs) async {
  ArgResults args = (ArgParser()..addOption("today", abbr: 't')).parse(argStrs);

  late final Set<String> possible;
  late final Set<String> past;
  for (Future assignment in [
    getPossibleAnswers().then((result) {possible = result;}),
    getPastAnswers().then((result) {past = result;}),
  ]) await assignment;

  if (args.option("today") != null) {
    past.add(args.option("today")!);
  }

  final Set<String> options = possible.difference(past);
  final Map<String, LetterDistribution> distribution = getDistribution(options);
  print(
    "opener (Positionless): "
    "${optimal(options, PositionlessEvaluator(distribution))}"
  );
  print(
    "opener (ContextlessPositional): "
    "${optimal(options, ContextlessPositionalEvaluator(distribution))}"
  );
  while (true) {
    print("enter a word to see if it's a possible answer:");
    print(options.contains(stdin.readLineSync()) ? "yes" : "no");
  }
}