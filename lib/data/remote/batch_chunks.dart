/// Splits [items] into lists of at most [size].
List<List<T>> chunksOf<T>(List<T> items, int size) {
  if (size <= 0) {
    throw ArgumentError.value(size, 'size', 'Chunk size must be positive.');
  }
  final chunks = <List<T>>[];
  for (var start = 0; start < items.length; start += size) {
    final end = start + size > items.length ? items.length : start + size;
    chunks.add(items.sublist(start, end));
  }
  return chunks;
}
