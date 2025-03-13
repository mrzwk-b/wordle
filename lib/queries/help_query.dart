import 'dart:io';

import 'package:wordle/queries/query.dart';

class HelpQuery extends Query {
  HelpQuery();

  @override
  String execute() => 
    File("help.txt").readAsLinesSync().join('\n')
  ;
}