import 'dart:io';

import 'package:wordle/queries/query.dart';

class QuitQuery extends Query {
  QuitQuery();
  
  @override
  String report() {
    exit(0);
  }
}