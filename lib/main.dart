import 'dart:io';

import 'package:args/args.dart';
import 'package:wordle/data/data.dart';
import 'package:wordle/data/data_manager.dart';
import 'package:wordle/data/scrape.dart';
import 'package:wordle/queries/parse.dart';
import 'package:wordle/queries/query.dart';

Future<Set<String>> tryUntilSuccess(Future<Set<String>> Function() scrape) async {
  while (true) {
    try {
      return await scrape();
    }
    catch (e) {
      print("error encountered: $e");
      print("trying again");
    }
  }
}

void main(List<String> argStrs) async {
  final ArgResults args = (ArgParser()..addOption("today", abbr: 't')).parse(argStrs);

  late final Set<String> possible;
  late final Set<String> past;
  for (Future assignment in [
    tryUntilSuccess(scrapePossible).then((value) {possible = value;}),
    tryUntilSuccess(() => scrapePast(args.option("today"))).then((value) {past = value;}),
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