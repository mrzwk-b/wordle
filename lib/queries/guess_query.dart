import 'package:wordle/data/data.dart';
import 'package:wordle/queries/query.dart';

class GuessQuery extends Query {
  String word;
  String result;
  GuessQuery(this.word, this.result);

  @override
  String execute() {
    List<String?> blank = List.filled(5, null);
    List<String?> yellow = List.filled(5, null);
    List<String?> green = List.filled(5, null);
    for (int i = 0; i < 5; i++) {
      switch (result[i]) {
        case 'b':
          blank[i] = word[i];
        case 'y':
          yellow[i] = word[i];
        case 'g':
          green[i] = word[i];
        default:
          throw QueryException(
            'result argument of GuessQuery must contain only the letters "b", "y", & "g", found ${result[i]}'
          );
      }
    }
    reflectChange(blank: blank, yellow: yellow, green: green);
    return "update complete";
  }
  
}