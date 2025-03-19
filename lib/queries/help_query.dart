import 'dart:io';

import 'package:wordle/queries/query.dart';
import 'package:yaml/yaml.dart';

class HelpQuery extends Query {
  List<String> path;
  late final YamlList helpMsg = (find(loadYamlNode(File("help.yaml").readAsStringSync()), path) ?? YamlMap())['msg'];
  HelpQuery([pathStr = ""]): path = pathStr.split("");

  YamlMap? find(YamlNode root, List<String> path) {
    if (path.isEmpty) {
      return root as YamlMap;
    }
    if (root is YamlList) {
      for (YamlNode child in root.nodes) {
        YamlMap? result = find(child, path);
        if (result != null) {
          return result;
        }
      }
      return null;
    }
    else if (root is YamlMap) {
      if (root['abbr'] == path[0]) {
        return find(root['abbr'], path.sublist(1));
      }
      else {
        return null;
      }
    }
    else { // root is YamlScalar
      return null;
    }
  }

  @override
  String execute() => [
    for (YamlNode node in helpMsg.nodes) (
      node is String
      ? node
      : ((Map map) => "(${map['abbr']}) ${map['name']}")(node as YamlMap)
    )
  ].join('\n');
  
}