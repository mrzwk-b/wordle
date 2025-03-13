import 'package:wordle/data/data.dart';
import 'package:wordle/data/distribution.dart';
import 'package:wordle/queries/query.dart';

const Set<String> specialCharacters = {r'@', r'#', r'$', r'_', r'*', r'+', r'?'};
const Set<String> vowels = {'a', 'e', 'i', 'o', 'u', 'y'};
const Set<String> consonants = {'b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','y','z'};

bool isLetterMatch(final String letter, final String pattern) => 
  pattern.length == 1 && letter.length == 1 && alphabet.contains(letter) &&
  switch (pattern) {
    '@' => vowels.contains(letter),
    r'$' => consonants.contains(letter),
    '_' => true,
    '?' => true,
    _ => letter == pattern
  }
;

class ExpressionQuery extends Query {  
  String pattern;

  ExpressionQuery(this.pattern) {
    if (RegExp('[^a-z${specialCharacters.join()}]').hasMatch(pattern)) {
      throw QueryException('ExpressionQuery requires valid pattern, received $pattern');
    }
  }

  bool isMatch(final String word) { // TODO fix issues with @ and $
    // loop through the whole word
    for (int wordStart = 0; wordStart < 5; wordStart++) {
      // start trying to match the pattern from where we are in the word
      int wordIndex = wordStart;
      bool matching = true;
      for (int patternIndex = 0; patternIndex < pattern.length; patternIndex++) {
        if (pattern[patternIndex] == '#') {
          matching = wordIndex == 0 || wordIndex == 5;
        }
        else if (wordIndex < 5) {
          switch (pattern[patternIndex]) {
            case '@':
              if (patternIndex + 1 < pattern.length && pattern[patternIndex+1] == '*') {
                while (wordIndex < 5 && isLetterMatch(word[wordIndex], pattern[patternIndex])) {
                  wordIndex++;
                }
                patternIndex++;
              }
              else {
                if (!vowels.contains(word[wordIndex])) {
                  wordIndex++;
                  matching = false;
                }
                if (patternIndex + 1 < pattern.length && pattern[patternIndex+1] == '+') {
                  while (wordIndex < 5 && isLetterMatch(word[wordIndex], pattern[patternIndex])) {
                    wordIndex++;
                  }
                  patternIndex++;
                }
              }
            ;
            case r'$':
              if (patternIndex + 1 < pattern.length && pattern[patternIndex+1] == '*') {
                while (wordIndex < 5 && isLetterMatch(word[wordIndex], pattern[patternIndex])) {
                  wordIndex++;
                }
                patternIndex++;
              }
              else {
                if (!consonants.contains(word[wordIndex])) {
                  wordIndex++;
                  matching = false;
                }
                if (patternIndex + 1 < pattern.length && pattern[patternIndex+1] == '+') {
                  while (wordIndex < 5 && isLetterMatch(word[wordIndex], pattern[patternIndex])) {
                    wordIndex++;
                  }
                  patternIndex++;
                }
              }
            ;
            case '?':
              throw QueryException('"?" cannot occur in fixed expression query');
            case '_':
              if (patternIndex + 1 < pattern.length && pattern[patternIndex+1] == '*') {
                while (wordIndex < 5 && isLetterMatch(word[wordIndex], pattern[patternIndex])) {
                  wordIndex++;
                }
                patternIndex++;
              }
              else if (pattern[patternIndex] == '+') {
                if (wordIndex >= 5) {
                  return false;
                }
                while (wordIndex < 5 && isLetterMatch(word[wordIndex], pattern[patternIndex])) {
                  wordIndex++;
                }
                patternIndex++;
              }
              else {
                wordIndex++;
              }
            ;
            default:
              matching &= word[wordIndex] == pattern[patternIndex];
              wordIndex++;
            ;
          }
        }
        else {matching = false;}
        if (!matching) {break;}
      }

      if (matching) return true;
    }
    return false;
  }

  List<String> getMatchingLetters(final String word) {
    return [""]; // TODO
  }

  @override
  String execute() {
    if (pattern.contains('?')) {
      throw UnimplementedError("variable ExpressionQueries are not implemented yet"); // TODO
      // int unmatchedWordCount = 0;
      // final Iterable<List<String>> letterMatchesByWord = options.map(getMatchingLetters);
      // final Map<String, int> letterMatchCounts = Map.fromIterable(alphabet,
      //   key: (letter) => letter,
      //   value: (letter) => 0,
      // );
      // for (final List<String> matchedLetters in letterMatchesByWord) {
      //   if (matchedLetters.length == 0) {
      //     unmatchedWordCount += 1;
      //   }
      //   for (final String letter in matchedLetters) {
      //     letterMatchCounts.update(letter, (count) => count + 1);
      //   }
      // }
      // return [
      //   for (final String letter in rank(letterMatchCounts)) 
      //     "$letter: ${letterMatchCounts[letter]}"
      //   ,
      //   "words that matched with no letters: $unmatchedWordCount"
      // ].join('\n');
    }
    else {
      List<String> results = [for (final String word in options.where(isMatch)) word];
      return 
        "${results.join('\n')}\n\n"
        "total: ${results.length}"
      ;
    }
  }
}