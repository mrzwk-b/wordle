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
    return [
      if (!data.options.contains(word)) 
        '${(data.past.contains(word) 
          ? 'already been used'
          : (stack.first.data.possible.contains(word)
            ? 'impossible due to a previous guess'
            : 'not an answer'
          )
        )}, but hypothetically:'
      ,
      for (String evaluatorName in data.evaluators.keys) 
        '$evaluatorName: ${data.evaluationReport(evaluatorName, word)}'
      ,
    ].join('\n');
  }
}