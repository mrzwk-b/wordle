import 'dart:io';

import 'package:args/args.dart';
import 'package:wordle/data/data.dart';
import 'package:wordle/queries/parse.dart';
import 'package:wordle/queries/query.dart';

void main(List<String> argStrs) async {
  final ArgResults args = (ArgParser()..addOption("today", abbr: 't')).parse(argStrs);
  await initializeData(args.option("today"));

  while (true) {
    print("enter a query (h for help):");
    try {
      print(parse(stdin.readLineSync() ?? "").execute());
    }
    on QueryException catch (e) {
      print(e);
    }
    print("");
  }
}