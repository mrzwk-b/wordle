import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/query.dart';

class EvaluatorRankQuery extends Query {
  DataManager dm = DataManager();
  String evaluatorName;
  int count;
  int offset;
  bool decreasing;
  EvaluatorRankQuery(this.evaluatorName, this.count, {this.offset = 0, this.decreasing = true}) {
    if (!dm.data.evaluators.keys.contains(evaluatorName)) {
      throw QueryException('EvaluatorRankQuery requires name of valid evaluator, received "$evaluatorName"');
    }
    if (count < 0 || count > dm.data.options.length) {
      throw QueryException('EvaluatorRankQuery result count must be in range 0-${dm.data.options.length}');
    }
    if (offset < 0 || offset > dm.data.options.length) {
      throw QueryException('EvaluatorRankQuery result offset must be in range 0-${dm.data.options.length}');
    }
    if (dm.data.options.length - offset < count) {
      throw QueryException('EvaluatorRankQuery cannot return $count results from ${dm.data.options.length - offset} options');
    }
  }

  @override
  String execute() => [
    // get a list of a [length] items from the top or bottom of rankings for the given evaluator
    for (String word in 
      (decreasing ? dm.data.rankings[evaluatorName]! : dm.data.rankings[evaluatorName]!.reversed)
      .toList()
      .sublist(offset)
      .take(count)
    ) "$word: ${dm.data.evaluationReport(evaluatorName, word)}"     
  ].join('\n');
}