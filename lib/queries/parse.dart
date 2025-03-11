import 'package:wordle/queries/evaluator_query.dart';
import 'package:wordle/queries/help_query.dart';
import 'package:wordle/queries/letter_query.dart';
import 'package:wordle/queries/query.dart';
import 'package:wordle/queries/word_query.dart';

Query parse(String input) {
  List<String> queryArgs = input.split(" ");
  switch (queryArgs[0]) {
    case 'h':
      return HelpQuery();

    case 'l':
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for LetterQuery, found ${queryArgs.length - 1}");
      }
      return LetterQuery(queryArgs[1]);

    case 'v':
      if (queryArgs.length < 3 || queryArgs.length > 5) {
        throw QueryException("expected 2-4 arguments for EvaluatorQuery, found ${queryArgs.length - 1}");
      }

      int count;
      try {
        count = int.parse(queryArgs[2]);
      }
      on FormatException {
        throw QueryException("expected int argument in position 3, found ${queryArgs[2]}");
      }

      // evaluator count
      if (queryArgs.length == 3) {
        return EvaluatorQuery(queryArgs[1], count);
      }
      // evaluator count -
      else if (queryArgs[3] == '-') {
        if (queryArgs.length != 4) {
          throw QueryException('expected "-" as final argument to EvaluatorQuery, found ${queryArgs[4]}');
        }
        return EvaluatorQuery(queryArgs[1], count, decreasing: false);
      }
      else {
        int offset;
        try {
          offset = int.parse(queryArgs[3]);
        }
        on FormatException {
          throw QueryException("expected int argument in position 4, found ${queryArgs[3]}");
        }
        // evaluator count offset
        if (queryArgs.length == 4) {
          return EvaluatorQuery(queryArgs[1], count, offset: offset);
        }
        // evaluator count offset -
        else {
          if (queryArgs[4] != '-') {
            throw QueryException('expected "-" as final argument to EvaluatorQuery, found ${queryArgs[4]}');
          }
          return EvaluatorQuery(queryArgs[1], count, offset: offset, decreasing: false);
        }
      }

    case 'w':
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for WordQuery, found ${queryArgs.length - 1}");
      }
      return WordQuery(queryArgs[1]);

    case 'x':
      throw UnimplementedError("ExpressionQuery is not yet implemented");
      
    default:
      throw QueryException('"${queryArgs[0]}" does not correspond to a valid query type');
  }  
}