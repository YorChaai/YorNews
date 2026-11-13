import 'package:flutter/material.dart';
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
    expect(find.textContaining('Teknologi'), findsOneWidget);

    // Edit category
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

    await tester.tap(find.byTooltip('Hapus kategori').at(2));
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

    await tester.tap(find.text('Tambah situs'));
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
}
