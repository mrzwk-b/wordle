import 'package:wordle/data/data_manager.dart';
import 'package:wordle/data/distribution.dart';
import 'package:wordle/queries/bot_query.dart';
import 'package:wordle/queries/evaluator_range_query.dart';
import 'package:wordle/queries/evaluator_rank_query.dart';
import 'package:wordle/queries/expression_query.dart';
import 'package:wordle/queries/guess_query.dart';
import 'package:wordle/queries/help_query.dart';
import 'package:wordle/queries/letter_query.dart';
import 'package:wordle/queries/query.dart';
import 'package:wordle/queries/quit_query.dart';
import 'package:wordle/queries/restrict_query.dart';
import 'package:wordle/queries/state_query.dart';
import 'package:wordle/queries/word_query.dart';

bool isValidWord(String word) =>
  word.length == 5 && RegExp("[a-z]{5}").hasMatch(word)
;

Map<String, int> parseInclusion(String arg) {
  Map<String, int> inclusions = {};
  for (String letter in arg.split("")) {
    if (!alphabet.contains(letter)) {
      throw QueryException('expected only letters in inclusion argument, found "$letter"');
    }
    inclusions.update(letter, (count) => count + 1, ifAbsent: () => 1);
  }
  return inclusions;
}

Set<String> parseExclusion(String arg) {
  Set<String> inclusions = {};
  for (String letter in arg.split("")) {
    if (!alphabet.contains(letter)) {
      throw QueryException('expected only letters in inclusion argument, found "$letter"');
    }
    inclusions.add(letter);
  }
  return inclusions;
}

Query parse(String input) {
  List<String> queryArgs = input.split(" ");
  switch (queryArgs[0]) {
    case 'b':
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

    case 'g':
      if (queryArgs.length != 3) {
        throw QueryException("expected 2 arguments for ExpressionQuery, found ${queryArgs.length - 1}");
      }
      if (!isValidWord(queryArgs[1])) {
        throw QueryException('expected 5 letter alphabetic argument for word of GuessQuery, found "${queryArgs[1]}"');
      }
      if (!(queryArgs[2].length == 5 && RegExp("[bgy]{5}").hasMatch(queryArgs[2]))) {
        throw QueryException('expected 5 letter "bgy"-only argument for result of GuessQuery, found "${queryArgs[2]}"');
      }
      return GuessQuery(queryArgs[1], queryArgs[2]);

    case 'h':
      return HelpQuery(queryArgs.sublist(1));

    case 'l':
      if (queryArgs.length == 1) {
        return LetterQuery();
      }
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for LetterQuery, found ${queryArgs.length - 1}");
      }
      return LetterQuery(queryArgs[1]);

    case 'q':
      return QuitQuery();

    case 'r':
      if (queryArgs.length == 2) {
        return RestrictQuery(queryArgs[1]);
      }
      else if (queryArgs.length == 3) {
        if (queryArgs[2].startsWith('+')) {
          return RestrictQuery(queryArgs[1], include: parseInclusion(queryArgs[2].substring(1)));
        }
        else if (queryArgs[2].startsWith('-')) {
          return RestrictQuery(queryArgs[1], exclude: parseExclusion(queryArgs[2].substring(1)));
        }
        else {
          throw QueryException('expected inclusion or exclusion argument, found "${queryArgs[2]}"');
        }
      }
      else if (queryArgs.length == 4) {
        if (queryArgs[2].startsWith('+') && queryArgs[3].startsWith('-')) {
          return RestrictQuery(queryArgs[1],
            include: parseInclusion(queryArgs[2].substring(1)),
            exclude: parseExclusion(queryArgs[3].substring(1))
          );
        }
        else if (queryArgs[3].startsWith('+') && queryArgs[2].startsWith('-')) {
          return RestrictQuery(queryArgs[1],
            include: parseInclusion(queryArgs[3].substring(1)),
            exclude: parseExclusion(queryArgs[2].substring(1))
          );
        }
        else {
          throw QueryException('expected inclusion and exclusion argument, found ${queryArgs.sublist(2)}');
        }

      }
      else {
        throw QueryException('expected 1-3 arguments to RestrictQuery, found ${queryArgs.length}');
      }

    case 's':
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

    case 'w':
      if (queryArgs.length != 2) {
        throw QueryException("expected 1 argument for WordQuery, found ${queryArgs.length - 1}");
      }
      return WordQuery(queryArgs[1]);

    case 'x':
      if (queryArgs.length == 2) {
        return ExpressionQuery(queryArgs[1]);
      }
      else if (queryArgs.length == 3) {
        if (queryArgs[2].startsWith('+')) {
          return ExpressionQuery(queryArgs[1], include: parseInclusion(queryArgs[2].substring(1)));
        }
        else if (queryArgs[2].startsWith('-')) {
          return ExpressionQuery(queryArgs[1], exclude: parseExclusion(queryArgs[2].substring(1)));
        }
        else {
          throw QueryException('expected inclusion or exclusion argument, found "${queryArgs[2]}"');
        }
      }
      else if (queryArgs.length == 4) {
        if (queryArgs[2].startsWith('+') && queryArgs[3].startsWith('-')) {
          return ExpressionQuery(queryArgs[1],
            include: parseInclusion(queryArgs[2].substring(1)),
            exclude: parseExclusion(queryArgs[3].substring(1))
          );
        }
        else if (queryArgs[3].startsWith('+') && queryArgs[2].startsWith('-')) {
          return ExpressionQuery(queryArgs[1],
            include: parseInclusion(queryArgs[3].substring(1)),
            exclude: parseExclusion(queryArgs[2].substring(1))
          );
        }
        else {
          throw QueryException('expected inclusion and exclusion argument, found ${queryArgs.sublist(2)}');
        }

      }
      else {
        throw QueryException('expected 1-3 arguments to ExpressionQuery, found ${queryArgs.length}');
      }
      
    default:
      throw QueryException('"${queryArgs[0]}" does not correspond to a valid query type');
  }  
}