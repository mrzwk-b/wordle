import 'package:wordle/data/data.dart';
import 'package:wordle/utils.dart';

class DataException {
  String message;
  DataException(this.message);
  @override String toString() => "DataException: $message";
}

class TreeEntry {
  final String name;
  final Data data;
  TreeEntry(this.name, this.data);

  @override
  String toString() => '"$name"';
}

late final Tree<TreeEntry> dataTree;
List<int> pathToHead = [];

Tree<TreeEntry> get head => navigate(dataTree, pathToHead);
Data get data => head.value.data;

Tree<TreeEntry> navigate<T>(final Tree<TreeEntry> tree, final List<T> path) =>
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
    throw DataException("cannot add duplicate name to children");
  }
  head.add(TreeEntry(name, data));
  if (advance) {
    moveForward(name);
  }
}

void prune(String name) {
  int nameIndex = head.children.indexWhere((entry) => entry.value.name == name);
  if (nameIndex == -1) {
    throw DataException("cannot find child with name $name");
  }
  head.children.removeAt(nameIndex);
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
        throw DataException("cannot move back to nonexistent position $name");
      }
    }
  }
}

void moveForward(String name) {
  int nameIndex = head.children.indexWhere((entry) => entry.value.name == name);
  if (nameIndex == -1) {
    throw DataException("cannot find child with name $name");
  }
  pathToHead.add(nameIndex);
}