import 'package:wordle/data/data_manager.dart';
import 'package:wordle/queries/query.dart';
import 'package:wordle/utils.dart';

enum NavMode {
  Advance, Return, Delete
}

class StateQuery extends Query {
  NavMode? mode;
  final String name;
  StateQuery([this.name = "", this.mode]);

  void execute() {
    switch (mode) {
      case NavMode.Advance:
        moveForward(name);
      case NavMode.Return:
        moveBack(name: name);
      case NavMode.Delete:
        prune(name);
      case null:
    }
  }
  
  @override
  String report() {
    if (mode == null) {
      return [
        "${pathToHead.length} node${pathToHead.length == 1 ? "" : "s"} in path",
        for (String line in [
          if (pathToHead.length != 0) 
            "from least to most recent:"
          ,
          for (int i = 0; i < pathToHead.length; i++)
            navigate(dataTree, pathToHead.take(i).toList()).value.name
          ,
        ]) "  $line",
        "${head.children.length} branch${head.children.length == 1 ? "" : "es"} forward",
        for (Tree<TreeEntry> child in head.children) "  ${child.value.name}",
      ].join('\n');
    }
    else {
      execute();
      return [
        "reverted state back to before $name",
        "now ${data.options.length} options available",
      ].join('\n');
    }
  }
}