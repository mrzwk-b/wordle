import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/query.dart';

class EvaluatorRankQuery extends Query {
  final String evaluatorName;
  final int count;
  final int offset;
  final bool decreasing;
  final int vowelTolerance;
  EvaluatorRankQuery(
    this.evaluatorName,
    this.count, {
    this.offset = 0,
    this.decreasing = true,
    this.vowelTolerance = 5
  }) {
    if (!data.evaluators.keys.contains(evaluatorName)) {
      throw QueryException('EvaluatorRankQuery requires name of valid evaluator, received "$evaluatorName"');
    }
    if (count < 0 || count > data.options.length) {
      throw QueryException('EvaluatorRankQuery result count must be in range 0-${data.options.length}');
    }
    if (offset < 0 || offset > data.options.length) {
      throw QueryException('EvaluatorRankQuery result offset must be in range 0-${data.options.length}');
    }
    if (data.options.length - offset < count) {
      throw QueryException(
        'EvaluatorRankQuery cannot return $count results from ${data.options.length - offset} options'
      );
    }
    if (vowelTolerance > 5) {
      throw QueryException("vowel tolerance cannot be greater than 5, was $vowelTolerance");
    }
  }

  Iterable<String> execute() => 
    ((final List<String> list) => 
      decreasing ? list : list.reversed
    )(data.rankings[evaluatorName]![vowelTolerance]).toList().sublist(offset).take(count)
  ;

  @override
  String report() => [
    for (final String word in execute()) (
      "$word: ${data.evaluationReport(evaluatorName, word)}"
    )
  ].join('\n');
}