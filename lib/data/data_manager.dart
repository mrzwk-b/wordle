import 'package:wordle/data/data.dart';

class StackEntry {
  final String name;
  final Data data;
  StackEntry(this.name, this.data);

  @override
  String toString() => '"$name"';
}

final List<StackEntry> stack = [];

Data get data => stack.last.data;

void push(Data data, [String name = ""]) {
  stack.add(StackEntry(name, data));
}

List<Data> pop({int? count, String? word}) {
  if (word == null) {
    List<Data> removed = stack
      .sublist(stack.length - count!)
      .map((entry) => entry.data)
      .toList()
    ;
    stack.removeRange(stack.length - count, stack.length);
    return removed;
  }
  else {
    int removalIndex = stack.indexWhere((entry) => entry.name == word);
    List<Data> removed = stack
      .sublist(removalIndex)
      .map((entry) => entry.data)
      .toList()
    ;
    stack.removeRange(removalIndex, stack.length);
    return removed;
  }
}