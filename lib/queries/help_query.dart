import 'package:wordle/data/data.dart';
import 'package:wordle/queries/query.dart';

class HelpQuery extends Query {
  HelpQuery();

  @override
  String execute() => 
    'the following are valid query types:\n'
    '  l: letter\n'
    '     pass a single letter as an argument to see its distribution\n'
    '     total frequency, frequency in each slot,\n'
    '     and letters sorted by how often they precede and follow it,\n'
    '     sorted least to most common (# is the word boundary)\n'
    '     e.g, "l e" to see data for "e"\n'
    '     alternatively, pass no argument to see data for all letters\n'
    '     i.e., "l"\n'
    '  v: evaluator\n'
    '     pass an evaluator name, a number of words to fetch,\n'
    '     optionally an offset, and a - if you want to fetch from the bottom\n'
    '     displays the word along with its score and rank according to that evaluator\n'
    '     e.g., "v positional 10 5 -" to see the bottom 15 words minus the bottom 5 per the positional evaluator\n'
    '     alternatively, pass a range to see results for all words within that range\n'
    '     range boundaries can be specified by either score or word\n'
    '     ranges must contain a ":", but do not require either an upper or lower bound\n'
    '     ranges formatted as "start:end"\n'
    '     e.g., "v positional :50" to see all words with a score less than 50 with no lower bound\n'
    '           "v positional chose:" to see all words with a score at least as high as that of "chose"\n'
    '     list of all evaluator names:\n'
    '     ${[evaluators.keys].join(', ')}\n'
    '  w: word\n'
    '     pass a 5 letter word to see it evaluated by all evaluators\n'
    '     displays the word along with its score and rank according to that evaluator\n'
    '     e.g., "w chose" to see data for "chose"\n'
  ;
}