import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/query.dart';

class Range {
  String? worstWord;
  String? bestWord;
  int? worstScore;
  int? bestScore;
  Range({this.worstScore, this.worstWord, this.bestScore, this.bestWord}) {
    if (worstScore != null && worstWord != null) {
      throw QueryException("cannot create Range with 2 starts");
    }
    if (bestScore != null && bestWord != null) {
      throw QueryException("cannot create Range with 2 ends");
    }
  }
}

class EvaluatorRangeQuery extends Query {
  String evaluatorName;
  Range range;
  EvaluatorRangeQuery(this.evaluatorName, this.range) {
    if (!data.evaluators.keys.contains(evaluatorName)) {
      throw QueryException('EvaluatorRangeQuery requires name of valid evaluator, received "$evaluatorName"');
    }
  }

  Iterable<String> execute() {
    Map<String, int> wordEvaluations = data.evaluations[evaluatorName]!;
    List<String> wordRankings = data.rankings[evaluatorName]!;
    int start = 0;
    int end = wordRankings.length;
    // find end index in rankings
    if (range.bestScore != null || range.bestWord != null) {
      // establish bestScore
      if (range.bestWord != null) {
        range.bestScore = wordEvaluations.containsKey(range.bestWord)
          ? wordEvaluations[range.bestWord]!
          : data.evaluators[evaluatorName]!.evaluate(range.bestWord!)
        ;
      }
      // find latest index of word with score at best bestScore
      start = wordRankings.indexOf(wordRankings.firstWhere(
        (word) => data.evaluators[evaluatorName]!.compare(wordEvaluations[word]!, range.bestScore!) > -1,
        orElse: () => "",
      ));
      start = start == -1 ? wordRankings.length : start;
    }
    // find end index in rankings
    if (range.worstScore != null || range.worstWord != null) {
      // establish worstScore
      if (range.worstWord != null) {
        range.worstScore = wordEvaluations.containsKey(range.worstWord)
          ? wordEvaluations[range.worstWord]!
          : data.evaluators[evaluatorName]!.evaluate(range.worstWord!)
        ;
      }
      // find earliest index of word with score at worst worstScore
      end = wordRankings.lastIndexWhere(
        (word) => data.evaluators[evaluatorName]!.compare(wordEvaluations[word]!, range.worstScore!) < 1 
      );
      end = end == -1 ? 0 : end + 1;
    }
    
    return start < end ? wordRankings.sublist(start, end) : [];
  }

  @override
  String report() =>
    [for (String word in execute())
      '$word: ${data.evaluationReport(evaluatorName, word)}',
    ].join('\n')
  ;
}