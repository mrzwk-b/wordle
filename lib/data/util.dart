List<T> rank<T>(Map<T, int> items, {bool increasing = false}) => (
  items.entries.toList()..sort(increasing ?
    (a, b) => a.value - b.value :
    (a, b) => b.value - a.value
  )
).map((item) => item.key).toList();