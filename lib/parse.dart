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

int parseVowelTolerance(String arg) {
  if (!arg.startsWith('@')) {
    throw QueryException('${arg[0]} is invalid start to vowel tolerance argument');
  }
  int? tolerance = int.tryParse(arg.substring(1));
  if (tolerance == null) {
    throw QueryException('${arg.substring(1)} cannot be parsed as integer vowel tolerance');
  }
  if (tolerance < 0 || tolerance > 5) {
    throw QueryException('$tolerance is not a valid vowel tolerance value');
  }
  return tolerance;
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
      else if (queryArgs.length == 2) {
        if (queryArgs[1] != '#') {
          throw QueryException('Root "#" is the only valid StateQuery with 1 argument');
        }
        return StateQuery(mode: NavMode.Root);
      }
      else {
        return StateQuery(name: queryArgs.sublist(2).join(' '), mode: switch (queryArgs[1]) {
          '<' => NavMode.Return,
          '>' => NavMode.Advance,
          '-' => NavMode.Delete,
          _ => throw QueryException("${queryArgs[2]} is not a valid mode for StateQuery")
        });
      }
    }
    case 'v': {
      if (queryArgs.length < 3 || queryArgs.length > 6) {
        throw QueryException("expected 2-5 arguments for evaluator query, found ${queryArgs.length - 1}");
      }

      // range query
      if (queryArgs[2].contains(':')) {
        if (queryArgs.length > 4) {
          throw QueryException(
            'only vowel tolerance may be passed after range to evaluator query, found ${queryArgs.sublist(4)}'
          );
        }

        List<String> wordBounds = queryArgs[2].split(':');
        if (wordBounds.length != 2) {
          if (wordBounds.length != 3) {
            throw QueryException(
              'range argument must contain exactly 1 or 2 colons ":", found ${wordBounds.length - 1}'
            );
          }
          if (wordBounds[0] != "") {
            throw QueryException(
              '2 colons must completely surround word or value, found ${wordBounds[0]} before'
            );
          }
          if (wordBounds[2] != "") {
            throw QueryException(
              '2 colons must completely surround word or value, found ${wordBounds[2]} before'
            );
          }
          wordBounds = [wordBounds[1], wordBounds[1]];
        }

        List<int?> scoreBounds = List.filled(2, null);
        for (int i = 0; i < 2; i ++) {
          scoreBounds[i] = int.tryParse(wordBounds[i]);
          if (scoreBounds[i] == null) {
            if (!isValidWord(wordBounds[i])) {
              throw QueryException('expected 5 letter alphabetic word as limit, found "${wordBounds[i]}"');
            }
          }
          else {
            if (scoreBounds[i]! < 0) {
              throw QueryException('expected nonnegative score limit, found ${scoreBounds[i]}');
            }
          }
        }

        return EvaluatorRangeQuery(
          queryArgs[1],
          Range(
            worstWord: wordBounds[0] == "" ? null : wordBounds[0],
            worstScore: scoreBounds[0],
            bestWord: wordBounds[1] == "" ? null : wordBounds[1],
            bestScore: scoreBounds[1],
          ),
          queryArgs.length == 4 ? parseVowelTolerance(queryArgs[3]) : 5
        );
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