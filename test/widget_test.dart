import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yor_news_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Category add, validate, edit, delete flow has no FlutterError', (
    tester,
  ) async {
    await tester.pumpWidget(const YorNewsApp());
    await tester.pumpAndSettle();

    // Switch to Sport category first, then open Settings
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();

    // Tap Tambah kategori and test empty + duplicate validation
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama kategori wajib diisi.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sport');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama kategori itu sudah digunakan.'), findsOneWidget);

    // Add valid category
    await tester.enterText(find.byType(TextField), 'Teknologi');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Teknologi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Teknologi'), findsOneWidget);

    // Edit category
    await tester.scrollUntilVisible(
      find.byTooltip('Edit kategori').last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Edit kategori').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tech');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tech'), findsOneWidget);

    // Delete the new category AND the previously selected 'Sport' category
    await tester.tap(find.byTooltip('Hapus kategori').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus kategori'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tech'), findsNothing);

    await tester.scrollUntilVisible(
      find.textContaining('Sport'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.textContaining('Sport'),
          matching: find.byType(Row),
        ),
        matching: find.byTooltip('Hapus kategori'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus kategori'));
    await tester.pumpAndSettle();

    // Double tap back button safely returns to DirectoryPage without popping root
    await tester.tap(find.byTooltip('Kembali ke YorNews'));
    await tester.tap(
      find.byTooltip('Kembali ke YorNews'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Semua situs berita'), findsOneWidget);
  });

  testWidgets('Add, edit, delete news site and switch category flow', (
    tester,
  ) async {
    await tester.pumpWidget(const YorNewsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tambah manual'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tambah manual'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama situs'),
      'YorTest',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL situs'),
      'https://:80',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Negara asal media'),
      'indonesia',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Deskripsi singkat'),
      'Situs berita uji coba.',
    );

    await tester.tap(find.text('Simpan situs'));
    await tester.pumpAndSettle();
    expect(
      find.text('Masukkan URL lengkap, misalnya https://contoh.com'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'URL situs'),
      'https://yortest.id',
    );
    await tester.tap(find.text('Simpan situs'));
    await tester.pumpAndSettle();

    // Edit the newly added site
    await tester.scrollUntilVisible(
      find.text('YorTest'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Edit situs').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama situs'),
      'YorTest Updated',
    );
    await tester.tap(find.text('Simpan situs'));
    await tester.pumpAndSettle();

    // Back to directory
    await tester.tap(find.byTooltip('Kembali ke YorNews'));
    await tester.pumpAndSettle();

    // Switch to Nasional (must include lowercase 'indonesia')
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nasional'));
    await tester.pumpAndSettle();

    final directoryScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('YorTest Updated'),
      300,
      scrollable: directoryScrollable,
    );
    expect(find.text('YorTest Updated'), findsOneWidget);

    // Delete the site
    await tester.scrollUntilVisible(
      find.byTooltip('Pengaturan'),
      -300,
      scrollable: directoryScrollable,
    );
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('YorTest Updated'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Hapus situs').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('YorTest Updated'), findsNothing);
  });

  testWidgets('Render with 1.3x and 1.5x text scale without overflow', (
    tester,
  ) async {
    for (final scale in [1.3, 1.5]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            textScaler: TextScaler.linear(scale),
          ),
          child: const YorNewsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down and back up, then switch categories
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -600),
        1000,
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 800),
        1000,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Sport'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Liputan6.com is present and migrated when missing in saved prefs', (
    tester,
  ) async {
    await tester.pumpWidget(const YorNewsApp());
    await tester.pumpAndSettle();

    expect(find.text('Liputan6.com'), findsOneWidget);

    // Simulate existing saved sites without Liputan6 and no migration flag yet.
    final legacySites = defaultSites
        .where((site) => site.host != 'liputan6.com')
        .map((site) => site.toJson())
        .toList();
    SharedPreferences.setMockInitialValues({
      'yornews_sites': jsonEncode(legacySites),
    });

    await tester.pumpWidget(const YorNewsApp(key: ValueKey('migrated')));
    await tester.pumpAndSettle();

    expect(find.text('Liputan6.com'), findsOneWidget);
  });

  testWidgets('Website catalog picker allows selecting and adding websites', (
    tester,
  ) async {
    await tester.pumpWidget(const YorNewsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pilih atau tambah website'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Website'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Tribunnews');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tribunnews.com'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan Pilihan'));
    await tester.pumpAndSettle();

    final directoryScrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Tribunnews.com'),
      300,
      scrollable: directoryScrollable,
    );
    expect(find.text('Tribunnews.com'), findsOneWidget);
  });

  testWidgets(
    'Android browser chooser supports Just Once, Always, and resetting default',
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    (tester) async {
      final launchedCalls = <(String url, String? pkg)>[];
      const channel = MethodChannel('yornews/browser');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getInstalledBrowsers') {
              return [
                {'packageName': 'com.android.chrome', 'label': 'Chrome'},
                {'packageName': 'com.brave.browser', 'label': 'Brave'},
              ];
            }
            if (call.method == 'openUrlInBrowser') {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              launchedCalls.add((
                args['url'] as String,
                args['packageName'] as String?,
              ));
              return true;
            }
            return null;
          });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(const YorNewsApp());
      await tester.pumpAndSettle();

      // Tap Liputan6.com -> chooser opens, choose Brave + "Sekali saja"
      await tester.tap(find.text('Liputan6.com'));
      await tester.pumpAndSettle();

      expect(find.text('Buka Liputan6.com'), findsOneWidget);
      await tester.tap(find.text('Brave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sekali saja'));
      await tester.pumpAndSettle();

      expect(launchedCalls.last.$2, 'com.brave.browser');

      // Tap again -> chooser still appears because previous choice was "Sekali saja"
      await tester.tap(find.text('Liputan6.com'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Liputan6.com'), findsOneWidget);

      await tester.tap(find.text('Chrome'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selalu'));
      await tester.pumpAndSettle();

      expect(launchedCalls.last.$2, 'com.android.chrome');

      // Tap again -> opens Chrome directly without prompting
      await tester.tap(find.text('Liputan6.com'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Liputan6.com'), findsNothing);
      expect(launchedCalls.length, 3);
      expect(launchedCalls.last.$2, 'com.android.chrome');

      // Open Browser HP config and reset back to ask every time
      await tester.tap(find.byTooltip('Browser HP: Chrome'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tanya setiap buka website'));
      await tester.pumpAndSettle();

      // Tap Liputan6.com -> prompts again!
      await tester.tap(find.text('Liputan6.com'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Liputan6.com'), findsOneWidget);
    },
  );
}
