import 'dart:convert';

import 'package:http/http.dart';

Future<Set<String>> getPastAnswers() async {
  final Set<String> words = {};

  final html = await (
    await Request("get", Uri.https("rockpapershotgun.com", "/wordle-past-answers")).send()
  ).stream;
  
  // the html every word is encased within
  final String target = r'<li>([A-Z]{5})</li>\n';
  final RegExp regExp = RegExp(target);
  String buffer = "";
  await for (final chunk in html) {
    buffer += utf8.decode(chunk);
    for (RegExpMatch match in regExp.allMatches(buffer)) {
      assert(match.groupCount == 2);
      assert(match[1]!.length == 5);
      if (!words.contains(match[1])) words.add(match[1]!);
    }
    // cut the buffer down to just big enough to almost hold another copy of the target string
    final int newStart = buffer.length - target.length; 
    buffer = buffer.substring(
      newStart < 0 ? 0 : newStart,
      buffer.length
    );
  }

  return words.map((word) => word.toLowerCase()).toSet();
}

Future<Set<String>> getPossibleAnswers() async {
  final Set<String> words = {};

  final html = await (
    await Request("get", Uri.https("wordunscrambler.net", "/word-list/wordle-word-list")).send()
  ).stream;
  
  // the html every word is encased within
  final String target = 
    r'<li class="invert light">\s*'
      r'<a href="/unscramble/([a-z]{5})">([a-z]{5})</a>\s*'
    r'</li?>\s*'
  ;
  final RegExp regExp = RegExp(target, multiLine: true);
  String buffer = "";
  await for (final chunk in html) {
    buffer += utf8.decode(chunk);
    for (RegExpMatch match in regExp.allMatches(buffer)) {
      assert(match.groupCount == 3);
      assert(match[1] == match[2]);
      assert(match[1]!.length == 5);
      if (!words.contains(match[1])) words.add(match[1]!);
    }
    // cut the buffer down to just big enough to almost hold another copy of the target string
    final int newStart = buffer.length - target.length; 
    buffer = buffer.substring(
      newStart < 0 ? 0 : newStart,
      buffer.length
    );
  }

  return words.map((word) => word.toLowerCase()).toSet();
}