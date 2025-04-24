import 'dart:math';

import 'package:wordle/utils/lazy_map.dart';

/// doesn't work with nullable types
class LazyList<T> implements List<T> {
  final T Function(int) _constructor;
  final int length;
  final List<T?> _established;
  LazyList(this.length, this._constructor): 
    _established = List.filled(length, null)
  ;

  // read
  @override
  T operator [](int index) {
    if (_established[index] == null) {
      _established[index] = _constructor(index);
    }
    return _established[index]!;
  }
  @override
  T elementAt(int index) => this[index];
  @override
  T get first => this[0];
  @override
  void set first(T value) {
    this[0] = value;
  }
  @override
  T get last => this[length - 1];
  @override
  void set last(T value) {
    this[length - 1] = value;
  }
  @override
  bool get isEmpty => length == 0;
  @override
  bool get isNotEmpty => length != 0;
  @override
  T get single {
    if (this.length != 1) {
      throw StateError("single requires length of 1, found $length");
    }
    return this[0];
  }
  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) {
    Iterable<T> satisfying = where(test);
    if (satisfying.length == 0) {
      return (orElse ?? (throw StateError("expected orElse for unsatisfied test")))();
    }
    return satisfying.single;
  }

  // logic
  @override
  bool contains(Object? element) {
    for (int i = 0; i < length; i++) {
      if (this[i] == element) {
        return true;
      }
    }
    return false;
  }
  @override
  bool any(bool Function(T element) test) {
    for (int i = 0; i < length; i++) {
      if (test(this[i])) {
        return true;
      }
    }
    return false;
  }
  @override
  bool every(bool Function(T element) test) {
    for (int i = 0; i < length; i++) {
      if (!test(this[i])) {
        return false;
      }
    }
    return true;
  }

  // transform
  @override
  Iterable<T> get reversed => [for (int i = length - 1; i >= 0; i--) this[i]];
  @override
  List<T> operator +(List<T> other) => LazyList(
    length + other.length,
    (i) => i < length ? _constructor(i) : other[i]
  );
  @override
  Iterable<T> followedBy(Iterable<T> other) => this + other.toList();
  @override
  Map<int, T> asMap() => LazyMap({for (int i = 0; i < length; i++) i: () => _constructor(i)});
  @override
  List<T> toList({bool growable = true}) => (growable
    ? List.generate(length, (i) => this[i])
    : this
  );
  @override
  Set<T> toSet() => {for (int i = 0; i < length; i++) this[i]};
  @override
  Iterable<R> expand<R>(Iterable<R> Function(T element) toElements) => [
    for (int i = 0; i < length; i++) toElements(this[i])
  ].reduce((a, b) => a.toList() + b.toList());
  @override
  R fold<R>(R initialValue, R Function(R previousValue, T element) combine) {
    var value = initialValue;
    for (int i = 0; i < length; i++) {
      value = combine(value, this[i]);
    }
    return value;
  }
  @override
  String join([String separator = ""]) => [
    for (int i = 0; i < length; i ++) this[i]
  ].join(separator);

  // select
  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement firstWhere
    throw UnimplementedError();
  }
  @override
  Iterable<T> getRange(int start, int end) {
    // TODO: implement getRange
    throw UnimplementedError();
  }
  @override
  int indexOf(T element, [int start = 0]) {
    // TODO: implement indexOf
    throw UnimplementedError();
  }
  @override
  int indexWhere(bool Function(T element) test, [int start = 0]) {
    // TODO: implement indexWhere
    throw UnimplementedError();
  }
  @override
  int lastIndexOf(T element, [int? start]) {
    // TODO: implement lastIndexOf
    throw UnimplementedError();
  }
  @override
  int lastIndexWhere(bool Function(T element) test, [int? start]) {
    // TODO: implement lastIndexWhere
    throw UnimplementedError();
  }
  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) {
    // TODO: implement lastWhere
    throw UnimplementedError();
  }
  @override
  Iterable<R> map<R>(R Function(T e) toElement) {
    // TODO: implement map
    throw UnimplementedError();
  }
  @override
  T reduce(T Function(T value, T element) combine) {
    // TODO: implement reduce
    throw UnimplementedError();
  }
  @override
  Iterable<T> skip(int count) {
    // TODO: implement skip
    throw UnimplementedError();
  }
  @override
  Iterable<T> skipWhile(bool Function(T value) test) {
    // TODO: implement skipWhile
    throw UnimplementedError();
  }
  @override
  List<T> sublist(int start, [int? end]) {
    // TODO: implement sublist
    throw UnimplementedError();
  }
  @override
  Iterable<T> take(int count) {
    // TODO: implement take
    throw UnimplementedError();
  }
  @override
  Iterable<T> takeWhile(bool Function(T value) test) {
    // TODO: implement takeWhile
    throw UnimplementedError();
  }
  @override
  Iterable<T> where(bool Function(T element) test) {
    // TODO: implement where
    throw UnimplementedError();
  }
  @override
  Iterable<R> whereType<R>() => this
    .where((item) => item is R)
    .map((item) => item as R)
  ;

  // iterate
  @override
  void forEach(void Function(T element) action) {
    // TODO: implement forEach
  }
  @override
  // TODO: implement iterator
  Iterator<T> get iterator => throw UnimplementedError();

  // unimplemented
  @override
  List<R> cast<R>() {
    throw UnimplementedError();
  }

  // modification (unsupported)
  @override
  void set length(int newLength) {
    throw UnsupportedError("cannot modify length of LazyList");
  }
  @override
  void operator []=(int index, T value) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void add(T value) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  void addAll(Iterable<T> iterable) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  void clear() {
    throw UnsupportedError("cannot clear LazyList");
  }
  @override
  void fillRange(int start, int end, [T? fillValue]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void insert(int index, T element) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  void insertAll(int index, Iterable<T> iterable) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  bool remove(Object? value) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  T removeAt(int index) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  T removeLast() {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  void removeRange(int start, int end) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  void removeWhere(bool Function(T element) test) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  void replaceRange(int start, int end, Iterable<T> replacements) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void retainWhere(bool Function(T element) test) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void setAll(int index, Iterable<T> iterable) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void shuffle([Random? random]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void sort([int Function(T a, T b)? compare]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
}