class Tree<T> {
  final T value;
  final List<Tree<T>> children;
  Tree(this.value, [this.children = const []]);

  /// constructs a new `Tree` with value `child` and stores it in `children`
  void add(T child) {
    children.add(Tree(child));
  }
}