import 'dart:io';

import 'package:wordle/queries/query.dart';
import 'package:yaml/yaml.dart';

final YamlList msgTree = loadYamlNode(File("help.yaml").readAsStringSync()) as YamlList;

/// searches the message tree for the entry containing the message to be displayed
YamlList? find(YamlNode root, List<String> path) {
  if (root is YamlMap) {
    // determine if this entry matches the head of path
    if (root['abbr'] == path[0]) {
      return find(root['msg'], path.sublist(1));
    }
    else {
      return null;
    }
  }
  else if (root is YamlList) {
    if (path.isEmpty) { // nothing left to search for
      return root;
    }
    else {
      for (YamlNode child in root.nodes) {
        YamlList? result = find(child, path);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }
  else { // root is YamlScalar
    return null;
  }
}

String displayNestedList(List<dynamic> list, [int indentation = 1]) => [
  for (var item in list) (item is List
    ? displayNestedList(item, indentation + 1)
    : "${'  ' * indentation}${item}"
  )
].join('\n');

class HelpQuery extends Query {
  List<String> path;
  HelpQuery(this.path);

  @override
  String execute() => [
    for (YamlNode node in find(msgTree, path)?.nodes ?? 
      (throw QueryException("unable to find help message for $path"))
    ) (
      node is YamlList ?
        displayNestedList(node)
      :
      node is YamlScalar ?
        node
      : // node is YamlMap
        ((Map map) => "(${map['abbr']}) ${map['name']}")(node as YamlMap)
    )
  ].join('\n');  
}