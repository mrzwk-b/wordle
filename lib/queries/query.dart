abstract class Query {
  /// executes the query and returns a message containing its results
  String report();
}

class QueryException implements Exception {
  String message;
  QueryException(this.message);
  @override String toString() => "QueryException: $message";
}