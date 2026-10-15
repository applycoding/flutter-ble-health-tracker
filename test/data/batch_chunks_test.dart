import 'package:flutter_test/flutter_test.dart';
import 'package:pulsekeep/data/remote/batch_chunks.dart';

void main() {
  test('splits a Firestore write into sub-500 batches', () {
    final items = List<int>.generate(950, (index) => index);
    final chunks = chunksOf(items, 400);
    expect(chunks.map((chunk) => chunk.length), [400, 400, 150]);
    expect(chunks.first.first, 0);
    expect(chunks.last.last, 949);
  });

  test('returns no chunks for an empty list', () {
    expect(chunksOf<int>(const [], 400), isEmpty);
  });

  test('rejects a non-positive chunk size', () {
    expect(() => chunksOf([1], 0), throwsArgumentError);
  });
}
