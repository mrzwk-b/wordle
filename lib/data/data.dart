import 'package:wordle/data/distribution.dart';
import 'package:wordle/evaluators/contextual_evaluator.dart';
import 'package:wordle/evaluators/evaluator.dart';
import 'package:wordle/evaluators/positional_evaluator.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';

class Data {
  final Set<String> possible;
  final Set<String> past;
  final Set<String> options;

  late final Map<String, FrequencyDistribution> frequencyDistributions;
  late final List<String> frequencyRankings;
  late final Map<String, ContextualDistribution> contextualDistributions;

  late final Map<String, Evaluator> evaluators;
  late final Map<String, Map<String, int>> evaluations;
  /// kept in decreasing order
  late final Map<String, List<String>> rankings;

  Data(this.possible, this.past):
    options = possible.difference(past)
  {
    frequencyDistributions = getFrequencyDistributions(options);
    frequencyRankings = rank(frequencyDistributions.map(
      (letter, distribution) => MapEntry(letter, distribution.total)
    ));
    contextualDistributions = getContextualDistributions(options);
    evaluators = {
      "positionless": PositionlessEvaluator(frequencyDistributions),
      "positional": PositionalEvaluator(frequencyDistributions),
      "contextual": ContextualEvaluator(contextualDistributions),
    };
    evaluations = 
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
    rankings = 
      Map.fromEntries(evaluations.entries.map((entry) => 
        MapEntry(
          entry.key,
          rank(entry.value)
        )
      ));
    ;
  }

  String evaluationReport(String evaluatorName, String word) => 
    (options.contains(word)
      ? (
        '${evaluations[evaluatorName]![word]} pts, '
        '${rankings[evaluatorName]!.indexOf(word) + 1} / ${options.length}'
      )
      : ( 
        '${evaluators[evaluatorName]!.evaluate(word)} pts'   
      )
    )
  ;
}

List<T> rank<T>(Map<T, int> items, {bool increasing = false}) => (
  items.entries.toList()..sort(increasing ?
    (a, b) => a.value - b.value :
    (a, b) => b.value - a.value
  )
).map((item) => item.key).toList();

List<Set<T>> rankWithTies<T>(Map<T, int> items, {bool increasing = false}) {
  List<T> ranked = rank(items, increasing: increasing);
  List<Set<T>> output = [];
  Set<T> currentTier = {};
  for (T item in ranked) {
    if (currentTier.isEmpty || items[item] == items[currentTier.first]) {
      currentTier.add(item);
    }
    else {
      output.add(currentTier);
      currentTier = {item};
    }
  }
  output.add(currentTier);
  return output;
}