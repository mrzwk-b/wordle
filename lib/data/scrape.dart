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
      if (!words.contains(match[1])) words.add(match[1]!.toLowerCase());
    }
    // cut the buffer down to just big enough to almost hold another copy of the target string
    final int newStart = buffer.length - target.length; 
    buffer = buffer.substring(
      newStart < 0 ? 0 : newStart,
      buffer.length
    );
  }

  return words;
}

Future<Set<String>> scrapePossible() async {
  final Set<String> words = {};

  final html = await (
    await Request("get", Uri.https("wordletools.azurewebsites.net", "weightedbottles")).send()
  ).stream;
  
  // the html every word is encased within
  final String target = r'<td>([A-Z]{5})</td>';
  final RegExp regExp = RegExp(target);
  String buffer = "";
  await for (final chunk in html) {
    buffer += utf8.decode(chunk);
    for (RegExpMatch match in regExp.allMatches(buffer)) {
      if (!words.contains(match[1])) words.add(match[1]!.toLowerCase());
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

Future<Set<String>> scrapePast(String? today) async {
  Set<String> past = await getPastAnswers();
  if (today != null) {
    past.add(today);
  }
  return past;
}