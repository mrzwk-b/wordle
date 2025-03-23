import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/query.dart';

class StateQuery extends Query {
  final String? word;
  final int? count;
  StateQuery({this.word, this.count}) {
    if (word == null && count == null) {
      throw QueryException("must pass either a word or a count to StateQuery");
    }
    else if (word != null && count != null) {
      throw QueryException("cannot pass both a word and a count to StateQuery");
    }
  }
  
  @override
  String execute() {
    DataManager dm = DataManager();
    dm.pop(count: count, word: word);
    return 
      "reverted state back ${
        count != null 
        ? "by $count steps"
        : "to before $word"
      }\n"
      "now ${dm.data.options.length} options available"
    ;
  }
}