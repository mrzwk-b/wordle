import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/query.dart';

class StateQuery extends Query {
  final String? word;
  final int? count;
  StateQuery({this.word, this.count}) {
    if (word != null && count != null) {
      throw QueryException("cannot pass both a word and a count to StateQuery");
    }
  }
  
  @override
  String execute() {
    if (word == null && count == null) {
      return [
        "${stack.length - 1} state${stack.length - 1 == 1 ? "" : "s"} in history",
        if (stack.length != 1) for (String line in [
          "from least to most recent:",
          stack.sublist(1).toString(),
        ]) line
      ].join('\n');
    } 
    else { 
      pop(count: count, word: word);
      return [
        "reverted state back ${
          count != null 
          ? "by $count steps"
          : "to before $word"
        }",
        "now ${data.options.length} options available",
      ].join('\n');
    }
  }
}