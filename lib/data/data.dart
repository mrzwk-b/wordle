import 'package:wordle/data/distribution.dart';
import 'package:wordle/data/scrape.dart';
import 'package:wordle/evaluators/contextual_evaluator.dart';
import 'package:wordle/evaluators/evaluator.dart';
import 'package:wordle/evaluators/positional_evaluator.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';

late final Set<String> possible;
late final Set<String> past;
late Set<String> options;

late Map<String, FrequencyDistribution> frequencyDistribution;
late List<String> frequencyRankings;
late Map<String, ContextualDistribution> contextualDistribution;

late Map<String, Evaluator> evaluators;
late Map<String, Map<String, int>> evaluations;
/// kept in decreasing order
late Map<String, List<String>> rankings;

Future<void> scrapeData(String? today) async {
  // scrape data and set up basic sets
  for (final Future assignment in [
    getPossibleAnswers().then((result) {possible = result;}),
    getPastAnswers().then((result) {past = result;}),
  ]) await assignment;

  if (today != null) {
    past.add(today);
  }
}

void initializeData() {
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

void reflectChange({
  List<String?> blank = const [],
  List<String?> yellow = const [],
  List<String?> green = const []
}) {
  // get the letters that need to be included
  final Map<String, int> include = {};
  for (String? letter in yellow) {
    if (letter != null) {
      include.update(letter, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  // get the letters that need to be excluded
  final Set<String> forbidden = {};
  for (String? letter in blank) {
    if (letter != null) {
      forbidden.add(letter);
    }
  }
  // filter [possible]
  for (String word in possible.toList(growable: false)) {
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
    for (String letter in include.keys) {
      if ((letterCounts[letter] ?? 0) < include[letter]!) {
        possible.remove(word);
        break;
      }
    }
  }
  initializeData();
}

List<T> rank<T>(Map<T, int> items, {bool increasing = false}) => (
  items.entries.toList()..sort(increasing ?
    (a, b) => a.value - b.value :
    (a, b) => b.value - a.value
  )
).map((item) => item.key).toList();

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