import 'dart:math';

import 'package:wordle/data/data.dart';
import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/evaluator_range_query.dart';
import 'package:wordle/queries/evaluator_rank_query.dart';
import 'package:wordle/queries/guess_query.dart';
import 'package:wordle/queries/query.dart';

class Guess {
  final String word;
  final String response;
  const Guess(this.word, this.response);
}

class BotQuery extends Query {
  final String evaluator;
  final String answer;
  BotQuery(this.evaluator, this.answer) {
    // ensure that the state of [data] allows for [answer]
    branch(Data(
      data.possible.contains(answer)
        ? data.possible
        : data.possible.toSet()..add(answer)
      ,
      data.past.contains(answer)
        ? (data.past.toSet()..remove(answer))
        : data.past
      ,
    ), "BOT_QUERY_INIT");
  }

  String guessResponse(final String guess) {
    List<String> response = List.filled(5, 'b');
    Map<String, int> letterCounts = {};
    for (int i = 0; i < 5; i++) {
      letterCounts.update(guess[i], (count) => count + 1, ifAbsent: () => 1);
      if (answer[i] == guess[i]) {
        response[i] = 'g';
      }
      else if (
        answer.contains(guess[i]) && 
        letterCounts[guess[i]]! <= answer.split("").where((letter) => letter == guess[i]).length
      ) {
        response[i] = 'y';
      }
    }
    return response.join();
  }

  @override
  String report() {
    List<Guess> guesses = [];
    Random random = Random();
    try {
      for (int i = 0; i < 6; i++) {
        final String goodWord = EvaluatorRankQuery(evaluator, 1).execute().single;
        final List<String> bestWords = EvaluatorRangeQuery(
          evaluator, Range(bestWord: goodWord, worstWord: goodWord)
        ).execute().toList();
        final String guess = bestWords[random.nextInt(bestWords.length)];
        final String response = guessResponse(guess);

        guesses.add(Guess(guess, response));
        GuessQuery(guess, response).execute();
        if (response == 'ggggg') {
          break;
        }
      }
    }
    finally {
      moveBack(name: "BOT_QUERY_INIT");
    }
    
    return [
      for (Guess guess in guesses) (
        "${guess.word}\n"
        "${guess.response}\n"
      ),
      guesses.length == 6 && guesses.last.word != answer
      ? "failed to guess the given word"
      : "solved in ${guesses.length} guesses"
    ].join('\n');
  }
}