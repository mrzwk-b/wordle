import 'package:wordle/data/data_manager.dart';
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
  String execute() {
    DataManager dm = DataManager();
    return [
      dm.data.options.contains(word)
        ? ''
        : '${dm.data.past.contains(word) ? 'already been used' : 'not an answer'}, but hypothetically:'
      ,
      for (String evaluatorName in dm.data.evaluators.keys) 
        '$evaluatorName: ${dm.data.evaluationReport(evaluatorName, word)}'
      ,
    ].join('\n');
  }
}