import 'package:wordle/data/distribution.dart';
import 'package:wordle/data/scrape.dart';
import 'package:wordle/evaluators/contextual_evaluator.dart';
import 'package:wordle/evaluators/evaluator.dart';
import 'package:wordle/evaluators/positional_evaluator.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';

late final Set<String> possible;
late final Set<String> past;
late final Set<String> options;

late final Map<String, FrequencyDistribution> frequencyDistribution;
late final List<String> frequencyRankings;
late final Map<String, ContextualDistribution> contextualDistribution;

late final Map<String, Evaluator> evaluators;
late final Map<String, Map<String, int>> evaluations;
/// kept in decreasing order
late final Map<String, List<String>> rankings;

Future<void> initializeData(String? today) async{
  // scrape data and set up basic sets
  for (final Future assignment in [
    getPossibleAnswers().then((result) {possible = result;}),
    getPastAnswers().then((result) {past = result;}),
  ]) await assignment;
  if (today != null) {
    past.add(today);
  }
  options = possible.difference(past);

  // process interesting data
  frequencyDistribution = getFrequencyDistributions(options);
  frequencyRankings = rank(frequencyDistribution.map(
    (letter, distribution) => MapEntry(letter, distribution.total)
  ));
  contextualDistribution = getContextualDistributions(options);
  evaluators = {
    "positionless": PositionlessEvaluator(frequencyDistribution),
    "positional": PositionalEvaluator(frequencyDistribution),
    "contextual": ContextualEvaluator(contextualDistribution),
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

List<T> rank<T>(Map<T, int> items, {bool increasing = false}) => (
  items.entries.toList()..sort(increasing ?
    (a, b) => a.value - b.value :
    (a, b) => b.value - a.value
  )
).map((item) => item.key).toList();

String evaluationReport(String evaluatorName, String word) => 
  "${evaluations[evaluatorName]![word]} pts, "
  "${rankings[evaluatorName]!.indexOf(word) + 1} / ${options.length}"
;