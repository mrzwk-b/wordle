import 'package:wordle/data/data_manager.dart';
import 'package:wordle/data/distribution.dart';
import 'package:wordle/queries/bot_query.dart';
import 'package:wordle/queries/evaluator_range_query.dart';
import 'package:wordle/queries/evaluator_rank_query.dart';
import 'package:wordle/queries/expression_query.dart';
import 'package:wordle/queries/grid_query.dart';
import 'package:wordle/queries/guess_query.dart';
import 'package:wordle/queries/help_query.dart';
import 'package:wordle/queries/letter_query.dart';
import 'package:wordle/queries/query.dart';
import 'package:wordle/queries/quit_query.dart';
import 'package:wordle/queries/restrict_query.dart';
import 'package:wordle/queries/state_query.dart';
import 'package:wordle/queries/word_query.dart';

bool isValidWord(final String word) =>
  word.length == 5 && RegExp("[a-z]{5}").hasMatch(word)
;

bool isValidResponse(final String response) =>
  response.length == 5 && RegExp("[bgy]{5}").hasMatch(response)
;

Map<String, int> parseInclusion(final String arg) {
  Map<String, int> inclusions = {};
  for (String letter in arg.split("")) {
    if (!alphabet.contains(letter)) {
      throw QueryException('expected only letters in inclusion argument, found "$letter"');
    }
    inclusions.update(letter, (count) => count + 1, ifAbsent: () => 1);
  }
  return inclusions;
}

Set<String> parseExclusion(final String arg) {
  Set<String> exclusions = {};
  for (String letter in arg.split("")) {
    if (!alphabet.contains(letter)) {
      throw QueryException('expected only letters in exclusion argument, found "$letter"');
    }
    exclusions.add(letter);
  }
  return exclusions;
}

typedef Expression = ({
  String pattern,
  Map<String, int>? inclusion,
  Set<String>? exclusion,
  bool negation
});

Expression parseExpression(final List<String> args) {
  if (args.length < 1 || args.length > 4) {
    throw QueryException('expected 1-4 arguments of expression, found ${args.length}');
  }
  final bool negation = args.last == '!';
  Map<String, int>? inclusion = null;
  Set<String>? exclusion = null;
  for (final String arg in args.sublist(1)) {
    if (arg.startsWith('+')) {
      if (inclusion != null) {
        throw QueryException('cannot pass 2 inclusion arguments in expression');
      }
      inclusion = parseInclusion(arg.substring(1));
    }
    if (arg.startsWith('-')) {
      if (exclusion != null) {
        throw QueryException('cannot pass 2 exclusion arguments in expression');
      }
      exclusion = parseExclusion(arg.substring(1));
    }
  }
  return (
    pattern: args[0],
    inclusion: inclusion,
    exclusion: exclusion,
    negation: negation
  );
}

Query parse(final String input) {
  final List<String> queryArgs = input.split(" ");
  switch (queryArgs[0]) {
    case 'b': {
      if (queryArgs.length != 3) {
        throw QueryException("expected 2 arguments for BotQuery, found ${queryArgs.length - 1}");
      }
      if (!data.evaluators.keys.contains(queryArgs[1])) {
        throw QueryException("expected the name of an evaluator for first argument of BotQuery, found ${queryArgs[1]}");
      }
      if (!isValidWord(queryArgs[2])) {
        throw QueryException('expected 5 letter alphabetic second argument of BotQuery, found "${queryArgs[2]}"');
      }
      return BotQuery(queryArgs[1], queryArgs[2]);
    }
    case 'g': {
      if (!isValidWord(queryArgs[1])) {
        throw QueryException('expected valid word for first argument of GridQuery, found ${queryArgs[1]}');
      }
      bool usePast = queryArgs.last == '*';
      List<String> responses = queryArgs.sublist(2, usePast ? queryArgs.length - 1 : null);
      if (responses.length > 6) {
        throw QueryException('${queryArgs.length - 2} is too many response arguments for GridQuery, max 6');
      }
      for (final String response in responses) {
        if (!isValidResponse(response)) {
          throw QueryException('expected valid guess response for argument of GridQuery, found $response');
        }
      }
      return GridQuery(queryArgs[1], responses, usePast: usePast);
    }
    case 'h': {
      return HelpQuery(queryArgs.sublist(1));
    }
    case 'l': {
      if (queryArgs.length == 1) {
        return LetterQuery();
      }
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for LetterQuery, found ${queryArgs.length - 1}");
      }
      return LetterQuery(queryArgs[1]);
    }
    case 'q': {
      return QuitQuery();
    }
    case 'r': {
      // restrict based on result of guess
      if (
        queryArgs.length == 3 &&
        isValidWord(queryArgs[1]) &&
        isValidResponse(queryArgs[2])
      ) {
        return GuessQuery(queryArgs[1], queryArgs[2]);
      }
      // restrict based on expression
      else {
        Expression expr = parseExpression(queryArgs.sublist(1));
        return RestrictQuery(
          expr.pattern,
          include: expr.inclusion ?? {},
          exclude: expr.exclusion ?? {},
          negate: expr.negation,
        );
      }
    }
    case 's': {
      if (queryArgs.length == 1) {
        return StateQuery();
      }
      else if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for StateQuery, found ${queryArgs.length - 1}");
      }
      
      if (int.tryParse(queryArgs[1]) != null) {
        int count = int.parse(queryArgs[1]);
        if (stack.length <= count) {
          throw QueryException("cannot remove $count elements from a stack of length ${stack.length}");
        }
        return StateQuery(count: count);
      }
      else {
        if (!isValidWord(queryArgs[1])) {
          throw QueryException("expected valid word as argument for StateQuery, found ${queryArgs[1]}");
        }
        if (!stack.map((entry) => entry.name).contains(queryArgs[1])) {
          throw QueryException('can\'t revert to before "${queryArgs[1]}" because it isn\'t in the stack');
        }
        return StateQuery(word: queryArgs[1]);
      }
    }
    case 'v': {
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
        // 1 limit on both sides
        else if (range.startsWith(':') && range.endsWith(':')) {
          String word = range.substring(1, range.length - 1);
          int? score = int.tryParse(word);
          if (score == null) {
            if (!isValidWord(word)) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$word"');
            }
          }
          else {
            if (score < 0) {
              throw QueryException('expected nonnegative score limit, found $score');
            }
          }
          return EvaluatorRangeQuery(queryArgs[1], Range(
            worstWord: score == null ? word : null,
            worstScore: score,
            bestWord: score == null ? word : null,
            bestScore: score
          ));
        }
        // high limit only
        else if (range.startsWith(':')) {
          String highWord = range.substring(1);
          int? highScore = int.tryParse(highWord);
          // word limit
          if (highScore == null) {
            if (!isValidWord(highWord)) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$highWord"');
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(bestWord: highWord));
          }
          // score limit
          else {
            if (highScore < 0) {
              throw QueryException("expected nonnegative score limit, found $highScore");
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(bestScore: highScore));
          }
        }
        // low limit only
        else if (range.endsWith(':')) {
          String lowWord = range.substring(0, range.length - 1);
          int? lowScore = int.tryParse(lowWord);
          // word limit
          if (lowScore == null) {
            if (!isValidWord(lowWord)) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$lowWord"');
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(worstWord: lowWord));
          }
          // score limit
          else {
            if (lowScore < 0) {
              throw QueryException("expected nonnegative score limit, found $lowScore");
            }
            return EvaluatorRangeQuery(queryArgs[1], Range(worstScore: lowScore));
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
            if (!isValidWord(lowWord)) {
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
            if (!isValidWord(highWord)) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "$highWord"');
            }
          }
          else {
            if (highScore < 0) {
              throw QueryException("expected nonnegative score limit, found $highScore");
            }
          }
          return EvaluatorRangeQuery(queryArgs[1], Range(
            worstWord: lowScore == null ? lowWord : null,
            worstScore: lowScore,
            bestWord: highScore == null ? highWord : null,
            bestScore: highScore
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
    }
    case 'w': {
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for WordQuery, found ${queryArgs.length - 1}");
      }
      return WordQuery(queryArgs[1]);
    }
    case 'x': {
      Expression expr = parseExpression(queryArgs.sublist(1));
      return ExpressionQuery(
        expr.pattern,
        include: expr.inclusion ?? {},
        exclude: expr.exclusion ?? {},
        negate: expr.negation,
      );
    }
    default: {
      throw QueryException('"${queryArgs[0]}" does not correspond to a valid query type');
    }
  }
}