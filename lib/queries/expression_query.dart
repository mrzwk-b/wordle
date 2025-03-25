import 'package:wordle/data/data.dart';
import 'package:wordle/data/data_manager.dart';
import 'package:wordle/data/distribution.dart';
import 'package:wordle/queries/query.dart';

const Set<String> specialCharacters = {r'@', r'#', r'$', r'_', r'?'};
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

bool isWordMatch(final String word, final String pattern) {
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
            if (!vowels.contains(word[wordIndex])) {
              matching = false;
            }
            else {
              wordIndex++;
            }
          case r'$':
            if (!consonants.contains(word[wordIndex])) {
              matching = false;
            }
            else {
              wordIndex++;
            }
          case '?':
            throw QueryException('"?" cannot occur in fixed expression query');
          case '_':
            wordIndex++;
          default:
            matching &= word[wordIndex] == pattern[patternIndex];
            wordIndex++;
        }
      }
      else {matching = false;}
      if (!matching) {break;}
    }

    if (matching) return true;
  }
  return false;
}

List<String> getMatchingLetters(final String word, final String pattern) {
  final List<String> matchingLetters = [];
  for (String letter in alphabet) {
    if (isWordMatch(word, pattern.replaceAll('?', letter))) {
      matchingLetters.add(letter);
    }
  }
  return matchingLetters;
}

class ExpressionQuery extends Query {
  final String pattern;
  final Map<String, int> include;
  final Set<String> exclude;

  ExpressionQuery(this.pattern, {this.include = const {}, this.exclude = const {}}) {
    Iterable<RegExpMatch> matches = RegExp('[^a-z${specialCharacters.join()}]').allMatches(pattern);
    if (matches.length != 0) {
      throw QueryException(
        '"${matches.map((match) => match.group(0)).join('", "')}" '
        '${matches.length > 1 ? 'are not valid characters' : 'is not a valid character'} '
        'of an ExpressionQuery'
      );
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
  }

  @override
  String execute() {
    final DataManager dm = DataManager();

    // create a set of options that fulfills include/exclude requirements
    final Set<String> illegal = {};
    for (final String word in dm.data.options) {
      for (final String letter in exclude) {
        if (word.contains(letter)) {
          illegal.add(word);
          break;
        }
      }
      if (illegal.contains(word)) {
        continue;
      }
      for (final String letter in include.keys) {
        if (word.split("").where((slot) => slot == letter).length < include[letter]!) {
          illegal.add(word);
          break;
        }
      }
    }
    Set<String> options = dm.data.options.difference(illegal);

    // evaluate query
    
    // variable
    if (pattern.contains('?')) {
      int unmatchedWordCount = 0;
      final Iterable<List<String>> letterMatchesByWord = options.map((word) => getMatchingLetters(word, pattern));
      final Map<String, int> letterMatchCounts = Map.fromIterable(alphabet,
        key: (letter) => letter,
        value: (letter) => 0,
      );
      for (final List<String> matchedLetters in letterMatchesByWord) {
        if (matchedLetters.length == 0) {
          unmatchedWordCount += 1;
        }
        for (final String letter in matchedLetters) {
          letterMatchCounts.update(letter, (count) => count + 1);
        }
      }
      return [
        for (final String letter in rank(letterMatchCounts))
          if (letterMatchCounts[letter]! != 0) "$letter: ${letterMatchCounts[letter]}"
        ,
        "letters that matched with no words: "
          "${letterMatchCounts.keys.where((letter) => letterMatchCounts[letter]! == 0)}"
        ,
        "words that matched with no letters: $unmatchedWordCount"
      ].join('\n');
    }
    // fixed
    else {
      final List<String> results = [
        for (final String word in options.where((word) => isWordMatch(word, pattern))) word
      ];
      return 
        "${results.join('\n')}\n\n"
        "total: ${results.length}"
      ;
    }
  }
}