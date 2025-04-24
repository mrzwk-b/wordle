import 'package:collection/collection.dart';

UnorderedIterableEquality eq = UnorderedIterableEquality();
bool setEquals<T>(Iterable<T> a, Iterable<T> b) => eq.equals(a, b);

class LazyMap<K, V> implements Map<K, V> {
  final Map<K, V> _established = {};
  final Map<K, V Function()> _constructors;
  LazyMap(Map<K, V Function()> constructors): _constructors = constructors;

  // getters
  @override
  Iterable<K> get keys => _constructors.keys.toSet().union(_established.keys.toSet());
  @override
  Iterable<V> get values => [for (K key in keys) this[key]!];
  @override
  Iterable<MapEntry<K, V>> get entries => [for (K key in keys) MapEntry(key, this[key]!)];

  // contains
  @override
  bool containsKey(Object? key) => keys.contains(key);
  @override
  bool containsValue(Object? value) {
    for (K key in keys) {
      if (this[key] == value) {
        return true;
      }
    }
    return false;
  }

  // read
  @override
  V? operator [](Object? key) {
    if (!(key is K && _constructors.containsKey(key))) {
      return null;
    }

    if (!_established.containsKey(key)) {
      _established[key] = _constructors[key]!();
    }
    return _established[key];
  }
  @override
  int get length => keys.length;
  @override
  bool get isEmpty => keys.isEmpty;
  @override
  bool get isNotEmpty => keys.isNotEmpty;

  // add
  @override
  void addAll(Map<K, V> other) {
    for (MapEntry<K, V> entry in other.entries) {
      this[entry.key] = entry.value;
    }
  }
  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    for (MapEntry<K, V> entry in newEntries) {
      this[entry.key] = entry.value;
    }
  }
  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (!this.containsKey(key)) {
      _constructors[key] = ifAbsent;
    }
    return this[key]!;
  }
  
  // edit
  @override
  void operator []=(K key, V value) {
    _established[key] = value;
  }
  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    this[key] = update(this[key] ?? ifAbsent!());
    return this[key]!;
  }
  @override
  void updateAll(V Function(K key, V value) update) {
    for (K key in keys) {
      update(key, this[key]!);
    }
  }

  // remove
  @override
  V? remove(Object? key) {
    if (!keys.contains(key)) {
      return null;
    }

    V value = this[key]!;
    _established.remove(key);
    _constructors.remove(key);
    return value;
  }
  @override
  void removeWhere(bool Function(K key, V value) test) {
    for (K key in keys.where((key) => test(key, this[key]!))) {
      remove(key);
    }
  }
  @override
  void clear() {
    _established.clear();
    _constructors.clear();
  }

  // iteration
  @override
  void forEach(void Function(K key, V value) action) {
    for (K key in keys) {
      action(key, this[key]!);
    }
  }
  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) => 
    Map.fromEntries([for (K key in keys) convert(key, this[key]!)])
  ;

  // type
  @override
  Map<RK, RV> cast<RK, RV>() {
    throw UnimplementedError();
  }
  @override
  Type get runtimeType => LazyMap<K, V>;

  // general
  @override
  bool operator ==(Object other) =>
    other is Map<K, V> &&
    setEquals(other.keys, keys) &&
    keys.every((key) => other[key] == this[key])
  ;
  @override
  int get hashCode => _constructors.hashCode;
  @override
  String toString() => "{${
    [for (K key in keys)
      "$key: ${_established.containsKey(key) ? _established[key] : "__UNINITIALIZED__"}"
    ].join(', ')
  }}";
}