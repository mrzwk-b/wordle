import 'package:wordle/queries/query.dart';

class HelpQuery extends Query {
  HelpQuery();

  @override
  String execute() => 
    "the following are valid query types:\n"
    "  l: letter\n"
    "     pass a single letter as an argument to see its distribution\n"
    "     total frequency, frequency in each slot,\n"
    "     and letters sorted by how often they precede and follow it,\n"
    "     sorted least to most common (# is the word boundary)\n"
    "  v: evaluator\n" // TODO
  ;
}