import 'package:wordle/data/word_data.dart';
import 'package:wordle/utils/tree.dart';
import 'package:wordle/utils/wordle_exception.dart';

class _DataException extends WordleException {
  String message;
  _DataException(this.message);
  @override String toString() => "DataException: $message";
}

class Node {
  final String name;
  final Data data;
  Node(this.name, this.data);

  @override
  String toString() => '"$name"';
}

late final Tree<Node> dataTree;
List<int> pathToHead = [];

Tree<Node> get head => navigate(dataTree, pathToHead);
Data get data => head.value.data;

Tree<Node> navigate<T>(final Tree<Node> tree, final List<T> path) =>
  (path.isEmpty
    ? tree
    : (0 is T
      ? navigate(tree.children[(path as List<int>).first], path.sublist(1))
      : navigate(tree.children.firstWhere((entry) => entry.value.name == (path as List<String>).first), path)
    )
  )  
;

void branch(Data data, String name, [bool advance = true]) {
  if (head.children.any((tree) => tree.value.name == name)) {
    throw _DataException("cannot add duplicate name to children");
  }
  head.add(Node(name, data));
  if (advance) {
    moveForward(name);
  }
}

void prune([String? name]) {
  if (name == null) {
    head.children.removeAt(0);
  }
  else {
    int nameIndex = head.children.indexWhere((entry) => entry.value.name == name);
    if (nameIndex == -1) {
      throw _DataException("cannot find child with name $name");
    }
    head.children.removeAt(nameIndex);  
  }
}

void root() {
  pathToHead = [];
}

void moveBack({int? count, String? name}) {
  if (name == null) {
    pathToHead.removeRange(pathToHead.length - count!, pathToHead.length);
  }
  else {
    final List<int> priorHead = pathToHead.toList();
    String? lastRemoved;
    while (!pathToHead.isEmpty && lastRemoved != name) {
      try {
        lastRemoved = head.value.name;
        pathToHead.removeLast();
      }
      on RangeError catch (_) {
        pathToHead = priorHead;
        throw _DataException("cannot move back to nonexistent position $name");
      }
    }
  }
}

void moveForward(String name) {
  int nameIndex = head.children.indexWhere((entry) => entry.value.name == name);
  if (nameIndex == -1) {
    throw _DataException("cannot find child with name $name");
  }
  pathToHead.add(nameIndex);
}