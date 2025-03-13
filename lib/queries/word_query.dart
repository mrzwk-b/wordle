import 'package:wordle/data/data.dart';
import 'package:wordle/queries/query.dart';

class WordQuery extends Query {
  String word;
  WordQuery(this.word) {
    if (word.length != 5) {
      throw QueryException('WordQuery requires argument of length 5, received "$word"');
    }
    word = word.toLowerCase();
    if (!RegExp("[a-z]{5}").hasMatch(word)) {
      throw QueryException('WordQuery requires alphabetic input, received "$word"');
    }
  }

  @override
  String execute() => [
    options.contains(word)
      ? ''
      : '${past.contains(word) ? 'already been used' : 'not an answer'}, but hypothetically:'
    ,
    for (String evaluatorName in evaluators.keys) 
      '$evaluatorName: ${evaluationReport(evaluatorName, word)}'
    ,
  ].join('\n');
}