import 'package:wordle/data/distribution.dart';
import 'package:wordle/evaluators/balancing_evaluator.dart';
import 'package:wordle/evaluators/contextual_evaluator.dart';
import 'package:wordle/evaluators/evaluator.dart';
import 'package:wordle/evaluators/positional_evaluator.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';
import 'package:wordle/utils/lazy_list.dart';
import 'package:wordle/utils/lazy_map.dart';

class Data {
  final Set<String> possible;
  final Set<String> past;
  final Set<String> options;

  Map<String, FrequencyDistribution>? _frequencyDistributions;
  Map<String, FrequencyDistribution> get frequencyDistributions {
    _frequencyDistributions ??= getFrequencyDistributions(options);
    return _frequencyDistributions!;
  }

  List<String>? _frequencyRankings;
  List<String> get frequencyRankings {
    _frequencyRankings ??= rank(
      frequencyDistributions.map(
        (letter, distribution) => MapEntry(letter, distribution.total),
      ),
      (a, b) => b - a
    );
    return _frequencyRankings!;
  }

  Map<String, ContextualDistribution>? _contextualDistributions;
  Map<String, ContextualDistribution> get contextualDistributions {
    _contextualDistributions ??= getContextualDistributions(options);
    return _contextualDistributions!;
  }

  Map<String, Evaluator>? _evaluators;
  Map<String, Evaluator> get evaluators {
    final Map<String, Evaluator Function()> evaluatorConstructors = {
      "positionless": () => PositionlessEvaluator(frequencyDistributions),
      "positional": () => PositionalEvaluator(frequencyDistributions),
      "contextual": () => ContextualEvaluator(contextualDistributions),
      "balancing": () => BalancingEvaluator(frequencyDistributions, options.length),
    };
    _evaluators ??= LazyMap(
      evaluatorConstructors.keys.toSet(),
      (String name) => evaluatorConstructors[name]!()
    );
    return _evaluators!;
  }

  Map<String, List<Map<String, int>>>? _evaluations;
  Map<String, List<Map<String, int>>> get evaluations {
    _evaluations ??= LazyMap(
      evaluators.keys.toSet(),
      (name) => LazyList(
        6,
        (i) => LazyMap(
          options,
          (word) => evaluators[name]!.evaluate(word, i)
        )
      )
    );
    return _evaluations!;
  }

  Map<String, List<List<String>>>? _rankings;
  /// kept in best to worst order
  Map<String, List<List<String>>> get rankings {
    _rankings ??= LazyMap(
      evaluators.keys.toSet(),
      (name) => LazyList(
        6,
        (i) => rank(evaluations[name]![i], (a, b) => evaluators[name]!.compare(a, b))
      )
    );
    return _rankings!;
  }

  Data(this.possible, this.past): options = possible.difference(past);

  String evaluationReport(String evaluatorName, String word, [int vowelTolerance = 5]) => 
    (options.contains(word)
      ? (
        '${evaluations[evaluatorName]![vowelTolerance][word]} pts, '
        '${rankings[evaluatorName]![vowelTolerance].indexOf(word) + 1} / ${options.length}'
      )
      : ( 
        '${evaluators[evaluatorName]!.evaluate(word)} pts'   
      )
    )
  ;
}

List<T> rank<T>(Map<T, int> items, int Function(int, int) comparator) => (
  items.entries.toList()..sort((MapEntry<T, int> a, MapEntry<T, int> b) =>
    comparator(a.value, b.value)
  )
).map((item) => item.key).toList();

List<Set<T>> rankWithTies<T>(Map<T, int> items, int Function(int, int) comparator) {
  List<T> ranked = rank(items, comparator);
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