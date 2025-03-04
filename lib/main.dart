import 'dart:io';

import 'package:wordle/distribution.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';
import 'package:wordle/optimizer.dart';
import 'package:wordle/scrape.dart';

void main() async {
  final Set<String> possible = await getPossibleAnswers();
  final Set<String> past = await getPastAnswers();
  final Set<String> options = possible.difference(past);
  final Map<String, LetterDistribution> distribution = getDistribution(options);
  print("opener: ${optimal(options, PositionlessEvaluator(distribution))}");
  while (true) {
    print("enter a word to see if it's a possible answer today:");
    print(options.contains(stdin.readLineSync()) ? "yes" : "no");
  }
}