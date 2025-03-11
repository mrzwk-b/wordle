abstract class Query {
  String execute();
}

class QueryException implements Exception {
  String message;
  QueryException(this.message);
  @override String toString() => "QueryException: $message";
}