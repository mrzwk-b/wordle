import 'package:wordle/data/word_data.dart';
import 'package:wordle/data/data_tree.dart';
import 'package:wordle/data/letter_distribution.dart';
import 'package:wordle/queries/query.dart';

const Set<String> specialCharacters = {r'@', r'#', r'$', r'_', r'?', r'^', r'&', r'*'};
const Set<String> quantifiers = {r'^', r'&', r'*'};
const Set<String> vowels = {'a', 'e', 'i', 'o', 'u', 'y'};
const Set<String> consonants = {'b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','y','z'};

(bool, int) quantifyMatch(int maxMatchLength, String pattern) {
  bool matching = true;
  int actualMatchLength = 0;
  // unquantified
  if (pattern.length == 0) {
    if (maxMatchLength == 0) {
      matching = false;
    }
    else {
      actualMatchLength = 1;
    }
  }
  // quantified
  else {
    if (pattern.length != 1) {
      throw QueryException(
        "expected exactly 1 quantifier, "
        "found ${pattern.length}: ${pattern}"
      );
    }
    if (!quantifiers.contains(pattern)) {
      throw QueryException('$pattern is not a valid quantifier');
    }
    switch (pattern) {
      case '^':
        if (maxMatchLength > 0) {
          actualMatchLength = 1;
        }
      case '&':
        if (maxMatchLength == 0) {
          matching = false;
        }
        else {
          actualMatchLength = maxMatchLength;
        }
      case '*':
        actualMatchLength = maxMatchLength;
      default:
        throw QueryException(
          "$pattern is not a valid quantifier"
        );
    }
  }
  return (matching, actualMatchLength);
}

bool isWordMatch(final String word, final String pattern) {
  wordLoop: // try to match starting from each letter of the word
  for (int wordStart = 0; wordStart < 5; wordStart++) {
    int wordIndex = wordStart;
    bool matching = true;
    List<String?> numbereds = List.filled(5, null);
    // start going through the pattern
    for (int patternIndex = 0; patternIndex < pattern.length;) {
      if (pattern[patternIndex] == '#') {
        matching = 
          (wordIndex == 0 && patternIndex == 0) ||
          (wordIndex == 5 && patternIndex == pattern.length - 1)
        ;
        patternIndex += 1;
      }
      else if (wordIndex < 5) {
        int matchLength;
        int tokenSize = (
          patternIndex < pattern.length - 1 && 
          quantifiers.contains(pattern[patternIndex + 1])
        ) ? 2 : 1;
        String token = pattern.substring(patternIndex + 1, patternIndex + tokenSize);

        switch (pattern[patternIndex]) {
          case '@': {
            (matching, matchLength) = quantifyMatch(
              word.substring(wordIndex).split("").indexWhere((letter) => !vowels.contains(letter)),
              token
            );
          }
          case r'$': {
            (matching, matchLength) = quantifyMatch(
              word.substring(wordIndex).split("").indexWhere((letter) => !consonants.contains(letter)),
              token
            );
          }
          case '_': {
            (matching, matchLength) = quantifyMatch(
              word.substring(wordIndex).length,
              token
            );
          }
          case '?': {
            throw QueryException('"?" cannot occur in fixed expression query');
          }
          case String token when int.tryParse(token) != null: {
            int num = int.parse(token) - 1;
            if ((numbereds.toList()..removeAt(num)).contains(word[wordIndex])) {
              continue wordLoop;
            }
            else {  
              if (numbereds[num] == null) {
                numbereds[num] = word[wordIndex];
              }
              (matching, matchLength) = quantifyMatch(
                word.substring(wordIndex).split("").indexWhere((letter) => letter != numbereds[num]),
                token
              );
            }
          }
          default: {
            (matching, matchLength) = quantifyMatch(
              word.substring(wordIndex).split("").indexWhere((letter) => letter != pattern[patternIndex]),
              token
            );
          }
        }
        patternIndex += tokenSize;
        wordIndex += matchLength;
      }
      else {matching = false;}
      if (!matching) {break;}
    }
    if (matching) return true;
  }
  return false;
}

Set<String?> getMatchingLetters(final String word, final String pattern) {
  final Set<String?> matchingLetters = {};
  for (String letter in alphabet..add('#')) {
    if (isWordMatch(word, pattern.replaceAll('?', letter))) {
      matchingLetters.add(letter == '#' ? null : letter);
    }
  }
  return matchingLetters;
}

class ExpressionQuery extends Query {
  final String pattern;
  final Map<String, int> include;
  final Set<String> exclude;
  final bool negate;
  late final Set<String> options;

  ExpressionQuery(this.pattern, {this.include = const {}, this.exclude = const {}, this.negate = false}) {
    Iterable<RegExpMatch> matches = RegExp(
      '[^1-5a-z${specialCharacters.join()}]'
    ).allMatches(pattern);
    if (matches.length != 0) {
      throw QueryException(
        '"${matches.map((match) => match.group(0)).join('", "')}" '
        '${matches.length > 1 ? 'are not valid characters' : 'is not a valid character'} '
        'of an ExpressionQuery'
      );
    }
    if (negate && pattern.contains('?')) {
      throw QueryException('cannot negate variable expression query');
    }
    for (final String letter in include.keys) {
      if (!alphabet.contains(letter)) {
        throw QueryException(
          '$letter is not a letter, '
          'cannot be a required inclusion for an ExpressionQuery'
        );
      }
    }
    for (final String letter in exclude) {
      if (!alphabet.contains(letter)) {
        throw QueryException(
          '$letter is not a letter, '
          'cannot be a required exclusion for an ExpressionQuery'
        );
      }
    }

    // create a set of options that fulfills include/exclude requirements
    final Set<String> illegal = {};
    wordLoop:
    for (final String word in data.options) {
      for (final String letter in exclude) {
        if (getNegation(word.contains(letter))) {
          illegal.add(word);
          continue wordLoop;
        }
      }
      for (final String letter in include.keys) {
        if (getNegation(word.split("").where((slot) => slot == letter).length < include[letter]!)) {
          illegal.add(word);
          continue wordLoop;
        }
      }
    }
    options = data.options.difference(illegal);
  }

  /// negates a bool if this expression is negated
  bool getNegation(bool value) => negate ? !value : value;

  /// get all words that match this expression
  Iterable<String> executeFixed() => 
    options.where((word) => getNegation(isWordMatch(word, pattern)))
  ;

  @override
  String report() {
    // variable
    if (pattern.contains('?')) {
      int unmatchedWordCount = 0;
      final Map<String?, int> letterMatchCounts = Map.fromIterable(
        {null, for (String letter in alphabet) letter},
        key: (letter) => letter,
        value: (letter) => 0,
      );
      for (final Set<String?> matchedLetters in options.map((word) => getMatchingLetters(word, pattern))) {
        if (matchedLetters.length == 0) {
          unmatchedWordCount += 1;
        }
        for (final String? letter in matchedLetters) {
          letterMatchCounts.update(letter, (count) => count + 1);
        }
      }
      return [
        for (final String? letter in rank(letterMatchCounts, (a, b) => b - a))
          if (letterMatchCounts[letter]! != 0) "${letter == null ? '#' : letter}: ${letterMatchCounts[letter]}"
        ,
        "letters that matched with no words: "
          "${letterMatchCounts.keys.where((letter) => letterMatchCounts[letter]! == 0)}"
        ,
        "words that matched with no letters: $unmatchedWordCount"
      ].join('\n');
    }
    // fixed
    else {
      final Iterable<String> results = executeFixed();
      return 
        "${results.join('\n')}\n\n"
        "total: ${results.length}"
      ;
    }
  }
}