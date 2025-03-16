import 'package:wordle/data/data.dart';

class StackEntry {
  final String name;
  final Data data;
  StackEntry(this.name, this.data);
}

class DataManager {
  final List<StackEntry> stack;

  DataManager._internal(): stack = [];
  static DataManager dm = DataManager._internal();
  factory DataManager() => dm;

  Data get data => stack.last.data;

  void push(Data data, [String name = ""]) {
    stack.add(StackEntry(name, data));
  }
}