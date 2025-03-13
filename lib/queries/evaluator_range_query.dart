import 'package:wordle/data/data.dart';
import 'package:wordle/queries/query.dart';

class Range {
  String? lowWord;
  String? highWord;
  int? lowScore;
  int? highScore;
  Range({this.lowScore, this.lowWord, this.highScore, this.highWord}) {
    if (lowScore != null && lowWord != null) {
      throw QueryException("cannot create Range with 2 starts");
    }
    if (highScore != null && highWord != null) {
      throw QueryException("cannot create Range with 2 ends");
    }
  }
}

class EvaluatorRangeQuery extends Query {
  String evaluatorName;
  Range range;
  EvaluatorRangeQuery(this.evaluatorName, this.range) {
    if (!evaluators.keys.contains(evaluatorName)) {
      throw QueryException('EvaluatorRangeQuery requires name of valid evaluator, received "$evaluatorName"');
    }
  }

  Iterable<String> getWordsInRange() {
    Map<String, int> wordEvaluations = evaluations[evaluatorName]!;
    List<String> wordRankings = rankings[evaluatorName]!;
    int start = 0;
    int end = wordRankings.length;
    // find end index in rankings
    if (range.highScore != null || range.highWord != null) {
      // establish highScore
      if (range.highWord != null) {
        range.highScore = wordEvaluations.containsKey(range.highWord)
          ? wordEvaluations[range.highWord]!
          : evaluators[evaluatorName]!.evaluate(range.highWord!)
        ;
      }
      // find latest index of word with score at most highScore
      start = wordRankings.indexOf(wordRankings.firstWhere(
        (word) => wordEvaluations[word]! <= range.highScore!,
        orElse: () => "",
      ));
      start = start == -1 ? wordRankings.length : start;
    }
    // find end index in rankings
    if (range.lowScore != null || range.lowWord != null) {
      // establish lowScore
      if (range.lowWord != null) {
        range.lowScore = wordEvaluations.containsKey(range.lowWord)
          ? wordEvaluations[range.lowWord]!
          : evaluators[evaluatorName]!.evaluate(range.lowWord!)
        ;
      }
      // find earliest index of word with score at least lowScore
      end = wordRankings.lastIndexWhere((word) => 
        wordEvaluations[word]! >= range.lowScore!
      );
      end = end == -1 ? 0 : end + 1;
    }
    
    return start < end ? wordRankings.sublist(start, end) : [];
  }

  @override
  String execute() =>
    [for (String word in getWordsInRange())
      '$word: ${evaluationReport(evaluatorName, word)}',
    ].join('\n')
  ;
}