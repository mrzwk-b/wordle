import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

// past

bool isWebPastRequired = true;

Future<Set<String>> scrapePastFromWeb(int storedCount) async {
  final Set<String> words = {};

  final html = await (
    await Request("get", Uri.https("fiveforks.com", "/wordle")).send()
  ).stream;
  
  // the html every word is encased within
  final String target = r'([A-Z]{5}) ([0-9]+) [0-9]{2}/[0-9]{2}/[0-9]{2}<br />';
  final RegExp regExp = RegExp(target);
  String buffer = "";
  await for (final List<int> chunk in html) {
    buffer += utf8.decode(chunk);
    for (RegExpMatch match in regExp.allMatches(buffer)) {
      if (!words.contains(match[1])) {
        words.add(match[1]!.toLowerCase());
      }
      else {
        throw Exception("why is a word appearing twice on the list? ");
      }

      if (int.parse(match[2]!) <= storedCount) {
        return words;
      }
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


Future<Set<String>> readPastFromFile() async {
  final file = File(['records', 'past.txt'].join(Platform.pathSeparator));
  if (! await file.exists()) {
    return {};
  }
  return file.readAsLinesSync().toSet();
}

Future<Set<String>> getPastAnswers(String? today) async {
  Set<String> filePast = await readPastFromFile();
  Set<String> webPast = await scrapePastFromWeb(filePast.length);

  File(['records', 'past.txt'].join(Platform.pathSeparator)).writeAsStringSync(
    webPast.join('\n') + '\n',
    mode: FileMode.append,
  );

  Set<String> past = filePast.union(webPast);
  if (today != null) {
    past.add(today);
  }
  return past;
}

// possible

bool isWebPossibleRequired = true;

Future<Set<String>> scrapePossibleFromWeb() async {
  final Set<String> words = {};

  final html = await (
    await Request("get", Uri.https("wordletools.azurewebsites.net", "weightedbottles")).send()
  ).stream;
  
  // the html every word is encased within
  final String target = r'<td>([A-Z]{5})</td>';
  final RegExp regExp = RegExp(target);
  String buffer = "";
  await for (final List<int> chunk in html) {
    if (!isWebPossibleRequired) {
      return {};
    }

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

Future<Set<String>?> readPossibleFromFile() async {
  final File file = File(['records', 'possible.txt'].join(Platform.pathSeparator));
  if (! await file.exists()) {
    return null;
  }
  return file.readAsLinesSync().toSet();
}

Future<Set<String>> getPossibleAnswers() async {
  final Future<Set<String>> webPossible = scrapePossibleFromWeb();
  final Set<String>? filePossible = await readPossibleFromFile();
  if (filePossible != null) {
    isWebPossibleRequired = false;
    return filePossible;
  }

  final Set<String> possible = await webPossible;
  File(['records', 'possible.txt'].join(Platform.pathSeparator)).writeAsStringSync(possible.join('\n'));
  return possible;
}