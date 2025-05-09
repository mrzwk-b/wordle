import 'dart:io';

import 'package:args/args.dart';
import 'package:wordle/data/data.dart';
import 'package:wordle/data/data_manager.dart';
import 'package:wordle/data/scrape.dart';
import 'package:wordle/parse.dart';
import 'package:wordle/utils/tree.dart';
import 'package:wordle/utils/wordle_exception.dart';

Future<Set<String>> tryUntilSuccess(Future<Set<String>> Function() scrape) async {
  while (true) {
    try {
      return await scrape();
    }
    catch (e) {
      print("error encountered while scraping: $e");
      print("trying again");
    }
  }
}

void main(List<String> argStrs) async {
  final ArgResults args = (ArgParser()..addOption("today", abbr: 't')).parse(argStrs);

  late final Set<String> possible;
  late final Set<String> past;
  for (Future assignment in [
    tryUntilSuccess(getPossibleAnswers).then((value) {
      possible = value;
    }),
    tryUntilSuccess(() => getPastAnswers(args.option("today"))).then((value) {
      past = value;
    }),
  ]) {await assignment;}
  
  dataTree = Tree(TreeEntry('', Data(possible, past)));

  while (true) {
    print("enter a query (h for help):");
    try {
      print(parse(stdin.readLineSync() ?? "").report());
    }
    on WordleException catch (e) {
      print(e);
    }
    print("");
  }
}