import 'dart:math';

import 'package:wordle/utils/lazy_map.dart';

class LazyListIterator<E> implements Iterator<E> {
  final LazyList<E> lazyList;
  int index;
  LazyListIterator(this.lazyList, [start = 0]): this.index = start;

  @override
  E get current => lazyList[index];

  @override
  bool moveNext() {
    if (index >= lazyList.length) {
      return false;
    }

    index += 1;
    return true;
  }

}

/// doesn't work with nullable types
class LazyList<E> implements List<E> {
  final int length;
  final E Function(int) _constructor;
  final List<E?> _established;
  LazyList(this.length, constructor):
    _constructor = constructor,
    _established = List.filled(length, null)
  ;

  // read
  @override
  E operator [](int index) {
    if (_established[index] == null) {
      _established[index] = _constructor(index);
    }
    return _established[index]!;
  }
  @override
  E elementAt(int index) => this[index];
  @override
  E get first => this[0];
  @override
  void set first(E value) {
    this[0] = value;
  }
  @override
  E get last => this[length - 1];
  @override
  void set last(E value) {
    this[length - 1] = value;
  }
  @override
  bool get isEmpty => length == 0;
  @override
  bool get isNotEmpty => length != 0;
  @override
  E get single {
    if (this.length != 1) {
      throw StateError("single requires length of 1, found $length");
    }
    return this[0];
  }
  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    Iterable<E> satisfying = where(test);
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
  bool any(bool Function(E element) test) {
    for (int i = 0; i < length; i++) {
      if (test(this[i])) {
        return true;
      }
    }
    return false;
  }
  @override
  bool every(bool Function(E element) test) {
    for (int i = 0; i < length; i++) {
      if (!test(this[i])) {
        return false;
      }
    }
    return true;
  }

  // transform
  @override
  Iterable<E> get reversed => [for (int i = length - 1; i >= 0; i--) this[i]];
  @override
  List<E> operator +(List<E> other) => LazyList(
    length + other.length,
    (i) => i < length ? _constructor(i) : other[i]
  );
  @override
  Iterable<E> followedBy(Iterable<E> other) => this + other.toList();
  @override
  Map<int, E> asMap() => LazyMap({for (int i = 0; i < length; i++) i}, (int i) => _constructor(i));
  @override
  List<E> toList({bool growable = true}) => (growable
    ? List.generate(length, (i) => this[i])
    : this
  );
  @override
  Set<E> toSet() => {for (int i = 0; i < length; i++) this[i]};
  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) => [
    for (int i = 0; i < length; i++) toElements(this[i])
  ].reduce((a, b) => a.toList() + b.toList());
  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
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
  E firstWhere(bool Function(E) test, {E Function()? orElse}) {
    for (int i = 0; i < length; i++) {
      E item = this[i];
      if (test(item)) {
        return item;
      }
    }
    return orElse!();
  }
  @override
  Iterable<E> getRange(int start, int end) => 
    [for (int i = start; i < end; i++) 
      this[i]
    ]
  ;
  @override
  int indexOf(E element, [int start = 0]) {
    for (int i = start; i < length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }
  @override
  int indexWhere(bool Function(E) test, [int start = 0]) {
    for (int i = start; i < length; i++) {
      if (test(this[i])) {
        return i;
      }
    }
    return -1;
  }
  @override
  int lastIndexOf(E element, [int? start]) {
    for (int i = start ?? length - 1; i >= 0; i--) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }
  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) {
    for (int i = start ?? length - 1; i >= 0; i--) {
      if (test(this[i])) {
        return i;
      }
    }
    return -1;
  }
  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    for (int i = length - 1; i >= 0; i--) {
      E item = this[i];
      if (test(item)) {
        return item;
      }
    }
    return orElse!();
  }
  @override
  Iterable<T> map<T>(T Function(E e) toElement) =>
    [for (int i = 0; i < length; i++)
      toElement(this[i])
    ]
  ;
  @override
  E reduce(E Function(E value, E element) combine) {
    E result = this[0];
    for (int i = 1; i < length; i++) {
      result = combine(result, this[i]);
    }
    return result;
  }
  @override
  Iterable<E> skip(int count) =>
    [for (int i = count; i < length; i++)
      this[i]
    ]
  ;
  @override
  Iterable<E> skipWhile(bool Function(E value) test) =>
    [for (int i = indexWhere((item) => !test(item)); i < length; i++)
      this[i]
    ]
  ;
  @override
  List<E> sublist(int start, [int? end]) =>
    [for (int i = start; i < (end ?? length); i++)
      this[i]
    ]
  ;
  @override
  Iterable<E> take(int count) =>
    [for (int i = 0; i < count; i++)
      this[i]
    ]
  ;
  @override
  Iterable<E> takeWhile(bool Function(E value) test) =>
    [for (int i = 0; i < length && test(this[i]); i++)
      this[i]
    ]
  ;
  @override
  Iterable<E> where(bool Function(E element) test) =>
    [for (int i = 0; i < length; i++)
      if (test(this[i])) (
        this[i]
      )
    ]
  ;
  @override
  Iterable<T> whereType<T>() => this
    .where((item) => item is T)
    .map((item) => item as T)
  ;

  // iterate
  @override
  void forEach(void Function(E element) action) {
    for (int i = 0; i < length; i++) {
      action(this[i]);
    }
  }
  @override
  Iterator<E> get iterator => LazyListIterator(this);

  // unimplemented
  @override
  List<T> cast<T>() {
    throw UnimplementedError();
  }

  // modification (unsupported)
  @override
  void set length(int newLength) {
    throw UnsupportedError("cannot modify length of LazyList");
  }
  @override
  void operator []=(int index, E value) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void add(E value) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  void clear() {
    throw UnsupportedError("cannot clear LazyList");
  }
  @override
  void fillRange(int start, int end, [E? fillValue]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void insert(int index, E element) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  void insertAll(int index, Iterable<E> iterable) {
    throw UnsupportedError("cannot add to LazyList");
  }
  @override
  bool remove(Object? value) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  E removeAt(int index) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  E removeLast() {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  void removeRange(int start, int end) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  void removeWhere(bool Function(E element) test) {
    throw UnsupportedError("cannot remove from LazyList");
  }
  @override
  void replaceRange(int start, int end, Iterable<E> replacements) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void retainWhere(bool Function(E element) test) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void setAll(int index, Iterable<E> iterable) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void shuffle([Random? random]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
  @override
  void sort([int Function(E a, E b)? compare]) {
    throw UnsupportedError("cannot modify contents of LazyList");
  }
}