import 'package:collection/collection.dart';

UnorderedIterableEquality eq = UnorderedIterableEquality();
bool setEquals<T>(Iterable<T> a, Iterable<T> b) => eq.equals(a, b);

class LazyMap<K, V> implements Map<K, V> {
  final Set<K> _domain;
  final V Function(K) _constructor;
  final Map<K, V> _established = {};
  LazyMap(Set<K> domain, V Function(K) constructor): 
    _domain = domain,
    _constructor = constructor
  ;

  // getters
  @override
  Iterable<K> get keys => _domain;
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
    if (!(key is K && keys.contains(key))) {
      return null;
    }

    if (!_established.containsKey(key)) {
      _established[key] = _constructor(key);
    }
    return _established[key];
  }
  @override
  int get length => keys.length;
  @override
  bool get isEmpty => keys.isEmpty;
  @override
  bool get isNotEmpty => keys.isNotEmpty;

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
  int get hashCode => _domain.hashCode ^ (31 * _constructor.hashCode);
  @override
  String toString() => "{${
    [for (K key in keys)
      "$key: ${_established.containsKey(key) ? _established[key] : "__UNINITIALIZED__"}"
    ].join(', ')
  }}";

  // unsupported
  @override
  void addAll(Map<K, V> other) {
    throw UnsupportedError("cannot add to LazyMap");
  }
  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    throw UnsupportedError("cannot add to LazyMap");
  }
  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    throw UnsupportedError("cannot add to LazyMap");
  }
  @override
  void operator []=(K key, V value) {
    throw UnsupportedError("cannot modify contents of LazyMap");
  }
  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    throw UnsupportedError("cannot modify contents of LazyMap");
  }
  @override
  void updateAll(V Function(K key, V value) update) {
    throw UnsupportedError("cannot modify contents of LazyMap");
  }
  @override
  V? remove(Object? key) {
    throw UnsupportedError("cannot remove from LazyMap");
  }
  @override
  void removeWhere(bool Function(K key, V value) test) {
    throw UnsupportedError("cannot remove from LazyMap");
  }
  @override
  void clear() {
    throw UnsupportedError("cannot remove from LazyMap");
  }
}