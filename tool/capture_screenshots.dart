import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ledger/app.dart';

import '../test/support/app_harness.dart';
import '../test/support/samples.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture portfolio screenshots', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final harness = AppHarness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: const RepaintBoundary(
          key: Key('capture'),
          child: PulseLedgerApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final start = DateTime.utc(2026, 10, 15, 12);
    const beats = [66, 68, 71, 74, 78, 86, 92, 88, 81, 76, 73, 70, 68, 67, 69];
    for (var i = 0; i < beats.length; i++) {
      harness.wearable.emit(sample(bpm: beats[i], recordedAt: start.add(Duration(seconds: i * 4))));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    await _writePng(tester, 'docs/screenshots/monitor.png');

    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    await _writePng(tester, 'docs/screenshots/log.png');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Monitor'));
    await tester.pumpAndSettle();
    await _writePng(tester, 'docs/screenshots/monitor_phone.png');
  });
}

Future<void> _writePng(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('capture')));
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  final bytes = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.png));
  final file = File(path);
  await tester.runAsync(() async {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}
