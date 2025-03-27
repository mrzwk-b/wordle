import 'dart:io';

import 'package:args/args.dart';
import 'package:wordle/data/data.dart';
import 'package:wordle/data/data_manager.dart';
import 'package:wordle/data/scrape.dart';
import 'package:wordle/queries/parse.dart';
import 'package:wordle/queries/query.dart';

void main(List<String> argStrs) async {
  final ArgResults args = (ArgParser()..addOption("today", abbr: 't')).parse(argStrs);

  late final Set<String> possible;
  late final Set<String> past;
  for (Future assignment in [
    scrapePossible().then((value) {possible = value;}),
    scrapePast(args.option("today")).then((value) {past = value;}),
  ]) {await assignment;}
  
  push(Data(possible, past));

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