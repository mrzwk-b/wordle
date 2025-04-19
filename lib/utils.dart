import 'dart:math';

class Tree<T> {
  final T value;
  final List<Tree<T>> children;
  Tree(this.value, [List<Tree<T>>? children]): children = children ?? [];

  /// constructs a new `Tree` with value `child` and stores it in `children`
  void add(T child) {
    children.add(Tree(child));
  }

  int get height => (children.isEmpty)
    ? 1
    : children.map((child) => child.height).reduce((a, b) => max(a, b))
  ;
}