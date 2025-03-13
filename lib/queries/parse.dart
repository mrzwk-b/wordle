import 'package:wordle/queries/evaluator_range_query.dart';
import 'package:wordle/queries/evaluator_rank_query.dart';
import 'package:wordle/queries/expression_query.dart';
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
      if (queryArgs.length == 1) {
        return LetterQuery();
      }
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for LetterQuery, found ${queryArgs.length - 1}");
      }
      return LetterQuery(queryArgs[1]);

    case 'v':
      if (queryArgs.length < 3 || queryArgs.length > 5) {
        throw QueryException("expected 2-4 arguments for evaluator query, found ${queryArgs.length - 1}");
      }

      // range query
      if (queryArgs[2].contains(':')) {
        String range = queryArgs[2];
        // no limit
        if (range.length == 1) {
          return EvaluatorRangeQuery(queryArgs[1], Range());
        }
        // high limit only
        else if (range.startsWith(':')) {
          String highWord = range.substring(1);
          int? highScore = int.tryParse(highWord);
          // word limit
          if (highScore == null) {
            if (!(highWord.length == 5 && RegExp("[a-z]{5}").hasMatch(highWord))) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$highWord"');
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(highWord: highWord));
          }
          // score limit
          else {
            if (highScore < 0) {
              throw QueryException("expected nonnegative score limit, found $highScore");
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(highScore: highScore));
          }
        }
        // low limit only
        else if (range.endsWith(':')) {
          String lowWord = range.substring(0, range.length - 1);
          int? lowScore = int.tryParse(lowWord);
          // word limit
          if (lowScore == null) {
            if (!(lowWord.length == 5 && RegExp("[a-z]{5}").hasMatch(lowWord))) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$lowWord"');
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(lowWord: lowWord));
          }
          // score limit
          else {
            if (lowScore < 0) {
              throw QueryException("expected nonnegative score limit, found $lowScore");
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(lowScore: lowScore));
          }
        }
        // both limits
        else {
          List<String> wordLimits = range.split(':');
          if (wordLimits.length != 2) {
            throw QueryException("expected 2 limits, received ${wordLimits.length}");
          }
          String lowWord = wordLimits[0];
          String highWord = wordLimits[1];
          int? lowScore = int.tryParse(lowWord);
          if (lowScore == null) {
            if (!(lowWord.length == 5 && RegExp("[a-z]{5}").hasMatch(lowWord))) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$lowWord"');
            }
          }
          else {
            if (lowScore < 0) {
              throw QueryException("expected nonnegative score limit, found $lowScore");
            }
          }
          int? highScore = int.tryParse(highWord);
          if (highScore == null) {
            if (!(highWord.length == 5 && RegExp("[a-z]{5}").hasMatch(highWord))) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$highWord"');
            }
          }
          else {
            if (highScore < 0) {
              throw QueryException("expected nonnegative score limit, found $highScore");
            }
          }
          return EvaluatorRangeQuery(queryArgs[1], Range(
            lowWord: lowScore == null ? lowWord : null,
            lowScore: lowScore,
            highWord: highScore == null ? highWord : null,
            highScore: highScore
          ));
        }
      }
      // rank query
      else {  
        int count;
        try {
          count = int.parse(queryArgs[2]);
        }
        on FormatException {
          throw QueryException("expected int argument in position 3, found ${queryArgs[2]}");
        }

        // evaluator count
        if (queryArgs.length == 3) {
          return EvaluatorRankQuery(queryArgs[1], count);
        }
        // evaluator count -
        else if (queryArgs[3] == '-') {
          if (queryArgs.length != 4) {
            throw QueryException('expected "-" as final argument to EvaluatorRankQuery, found ${queryArgs[4]}');
          }
          return EvaluatorRankQuery(queryArgs[1], count, decreasing: false);
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
            return EvaluatorRankQuery(queryArgs[1], count, offset: offset);
          }
          // evaluator count offset -
          else {
            if (queryArgs[4] != '-') {
              throw QueryException('expected "-" as final argument to EvaluatorRankQuery, found ${queryArgs[4]}');
            }
            return EvaluatorRankQuery(queryArgs[1], count, offset: offset, decreasing: false);
          }
        }
      }

    case 'w':
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for WordQuery, found ${queryArgs.length - 1}");
      }
      return WordQuery(queryArgs[1]);

    case 'x':
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for ExpressionQuery, found ${queryArgs.length - 1}");
      }
      return ExpressionQuery(queryArgs[1]);
      
    default:
      throw QueryException('"${queryArgs[0]}" does not correspond to a valid query type');
  }  
}