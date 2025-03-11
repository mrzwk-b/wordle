import 'package:wordle/data/data.dart';
import 'package:wordle/queries/query.dart';

class EvaluatorRankQuery extends Query {
  String evaluatorName;
  int count;
  int offset;
  bool decreasing;
  EvaluatorRankQuery(this.evaluatorName, this.count, {this.offset = 0, this.decreasing = true}) {
    if (!evaluators.keys.contains(evaluatorName)) {
      throw QueryException('EvaluatorRankQuery requires name of valid evaluator, received "$evaluatorName"');
    }
    if (count < 0 || count > options.length) {
      throw QueryException('EvaluatorRankQuery result count must be in range 0-${options.length}');
    }
    if (offset < 0 || offset > options.length) {
      throw QueryException('EvaluatorRankQuery result offset must be in range 0-${options.length}');
    }
    if (options.length - offset < count) {
      throw QueryException('EvaluatorRankQuery cannot return $count results from ${options.length - offset} options');
    }
  }

  @override
  String execute() => [
    // get a list of a [length] items from the top or bottom of rankings for the given evaluator
    for (String word in 
      (decreasing ? rankings[evaluatorName]! : rankings[evaluatorName]!.reversed)
      .toList()
      .sublist(offset)
      .take(count)
    ) "$word: ${evaluationReport(evaluatorName, word)}"     
  ].join('\n');
}