import 'package:wordle/utils/wordle_exception.dart';

abstract class Query {
  /// executes the query and returns a message containing its results
  String report();
}

class QueryException implements WordleException {
  String message;
  QueryException(this.message);
  @override String toString() => "QueryException: $message";
}