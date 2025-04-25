import 'package:wordle/data/distribution.dart';
import 'package:wordle/evaluators/balancing_evaluator.dart';
import 'package:wordle/evaluators/contextual_evaluator.dart';
import 'package:wordle/evaluators/evaluator.dart';
import 'package:wordle/evaluators/positional_evaluator.dart';
import 'package:wordle/evaluators/positionless_evaluator.dart';
import 'package:wordle/utils/lazy_map.dart';

class EvaluatorMap {
  static final Map<String, Evaluator Function(Data)> evaluatorConstructors = {
    "positionless": (data) => PositionlessEvaluator(data.frequencyDistributions),
    "positional": (data) => PositionalEvaluator(data.frequencyDistributions),
    "contextual": (data) => ContextualEvaluator(data.contextualDistributions),
    "balancing": (data) => BalancingEvaluator(data.frequencyDistributions, data.options.length),
  };
  Map<String, Evaluator> evaluators = {};
  Data data;
  EvaluatorMap(this.data);

  Iterable<String> get keys => evaluatorConstructors.keys;
  /// requires name to be a valid evaluator name
  Evaluator operator [](String name) {
    if (!evaluators.containsKey(name)) {
      evaluators[name] = evaluatorConstructors[name]!(data);
    }
    return evaluators[name]!;
  }
}

class EvaluationsList {

}

class EvaluationsMap {

}

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

  Map<String, Map<String, int>>? _evaluations;
  Map<String, Map<String, int>> get evaluations {
    _evaluations ??= LazyMap(
      evaluators.keys.toSet(),
      (name) => LazyMap(
        options,
        (word) => evaluators[name]!.evaluate(word)
      )
    );
    return _evaluations!;
  }

  Map<String, List<String>>? _rankings;
  /// kept in best to worst order
  Map<String, List<String>> get rankings {
    _rankings ??= LazyMap(
      evaluators.keys.toSet(),
      (name) => rank(evaluations[name]!, (a, b) => evaluators[name]!.compare(a, b))
    );
    return _rankings!;
  }

  Data(this.possible, this.past): options = possible.difference(past);

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