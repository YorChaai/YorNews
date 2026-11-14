import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yor_news_app/widgets/app_scrollbar.dart';

void main() => runApp(const YorNewsApp());

class NewsSite {
  const NewsSite(
    this.name,
    this.url,
    this.country,
    this.topics,
    this.note, {
    this.categoryIds = const [],
  });
  final String name;
  final String url;
  final String country;
  final List<String> topics;
  final String note;
  final List<String> categoryIds;
  factory NewsSite.fromJson(Map<String, dynamic> json) {
    final topics = (json['topics'] as List<dynamic>).cast<String>();
    final savedCategories = json['categoryIds'] as List<dynamic>?;
    return NewsSite(
      json['name'] as String,
      json['url'] as String,
      json['country'] as String,
      topics,
      json['note'] as String,
      categoryIds:
          savedCategories?.cast<String>() ??
          [
            if (topics.any(const {'Sport', 'Bola', 'F1', 'MotoGP'}.contains))
              'sport',
            if (topics.any(
              const {
                'MLBB',
                'PUBG',
                'CS2',
                'Valorant',
                'Gaming',
                'Esports',
              }.contains,
            ))
              'gaming',
          ],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'country': country,
    'topics': topics,
    'note': note,
    'categoryIds': categoryIds,
  };

  String get host {
    final parsed = Uri.tryParse(url);
    final rawHost = parsed?.host ?? '';
    return rawHost.isEmpty ? url : rawHost.replaceFirst('www.', '');
  }

  String get initialLetter {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  bool get isIndonesia => country.trim().toLowerCase() == 'indonesia';
  bool get isSport =>
      topics.any(const {'Sport', 'Bola', 'F1', 'MotoGP'}.contains);
  bool get isGaming => topics.any(
    const {'MLBB', 'PUBG', 'CS2', 'Valorant', 'Gaming', 'Esports'}.contains,
  );
  NewsSite copyWith({List<String>? categoryIds}) => NewsSite(
    name,
    url,
    country,
    topics,
    note,
    categoryIds: categoryIds ?? this.categoryIds,
  );
}

class NewsCategory {
  const NewsCategory({
    required this.id,
    required this.name,
    this.kind = 'custom',
  });
  final String id;
  final String name;
  final String kind;

  factory NewsCategory.fromJson(Map<String, dynamic> json) => NewsCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: json['kind'] as String? ?? 'custom',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'kind': kind};
  NewsCategory copyWith({String? name}) =>
      NewsCategory(id: id, name: name ?? this.name, kind: kind);
}

class SettingsResult {
  const SettingsResult(this.sites, this.categories);
  final List<NewsSite> sites;
  final List<NewsCategory> categories;
}

const defaultCategories = <NewsCategory>[
  NewsCategory(id: 'national', name: 'Nasional', kind: 'national'),
  NewsCategory(
    id: 'international',
    name: 'Internasional',
    kind: 'international',
  ),
  NewsCategory(id: 'sport', name: 'Sport', kind: 'sport'),
  NewsCategory(id: 'gaming', name: 'Gaming', kind: 'gaming'),
];

bool siteBelongsToCategory(NewsSite site, NewsCategory category) =>
    switch (category.kind) {
      'national' => site.isIndonesia,
      'international' => !site.isIndonesia,
      _ => site.categoryIds.contains(category.id),
    };

const defaultSites = <NewsSite>[
  NewsSite(
    'detikNews',
    'https://news.detik.com/',
    'Indonesia',
    ['Nasional'],
    'Berita politik, hukum, dan peristiwa Indonesia.',
  ),
  NewsSite(
    'Kompas.com',
    'https://www.kompas.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Portal berita umum Indonesia.',
  ),
  NewsSite(
    'Liputan6.com',
    'https://www.liputan6.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Portal berita nasional, bisnis, bola, dan peristiwa terkini Indonesia.',
  ),
  NewsSite(
    'CNN Indonesia',
    'https://www.cnnindonesia.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Berita nasional dan dunia dari media Indonesia.',
  ),
  NewsSite(
    'Tempo.co',
    'https://www.tempo.co/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Laporan, berita, dan investigasi Indonesia.',
  ),
  NewsSite(
    'ANTARA News',
    'https://www.antaranews.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Kantor berita nasional Indonesia.',
  ),
  NewsSite(
    'Kumparan',
    'https://kumparan.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Berita dan cerita dari Indonesia.',
  ),
  NewsSite(
    'Bola.com',
    'https://www.bola.com/',
    'Indonesia',
    ['Bola'],
    'Sepak bola Indonesia dan dunia.',
  ),
  NewsSite(
    'detikSport',
    'https://sport.detik.com/sepakbola',
    'Indonesia',
    ['Bola', 'F1', 'MotoGP'],
    'Kanal olahraga detik.com.',
  ),
  NewsSite(
    'BolaSport.com',
    'https://www.bolasport.com/',
    'Indonesia',
    ['Bola', 'MotoGP'],
    'Berita berbagai cabang olahraga.',
  ),
  NewsSite(
    'Goal Indonesia',
    'https://www.goal.com/id',
    'Indonesia',
    ['Bola'],
    'Sepak bola dan bursa transfer.',
  ),
  NewsSite(
    'Pandit Football',
    'https://panditfootball.com/',
    'Indonesia',
    ['Bola'],
    'Analisis taktik dan kultur sepak bola.',
  ),
  NewsSite(
    'ONE Esports Indonesia',
    'https://www.oneesports.id/',
    'Indonesia',
    ['MLBB', 'PUBG', 'CS2', 'Valorant', 'Esports'],
    'Berita game dan esports.',
  ),
  NewsSite(
    'RevivalTV',
    'https://revivaltv.id/',
    'Indonesia',
    ['MLBB', 'PUBG', 'Esports'],
    'Berita esports dan kompetisi.',
  ),
  NewsSite(
    'Dunia Games',
    'https://duniagames.co.id/',
    'Indonesia',
    ['MLBB', 'PUBG', 'Gaming'],
    'Berita, panduan, dan hiburan game.',
  ),
  NewsSite(
    'UP Station',
    'https://upstation.asia/',
    'Indonesia',
    ['MLBB', 'Valorant', 'Esports'],
    'Gaming dan esports Indonesia.',
  ),
  NewsSite(
    'KotakGame',
    'https://www.kotakgame.com/',
    'Indonesia',
    ['Gaming', 'Esports'],
    'Berita game PC, konsol, dan mobile.',
  ),
  NewsSite(
    'KINCIR',
    'https://www.kincir.com/esports',
    'Indonesia',
    ['Gaming', 'Esports'],
    'Esports dan budaya pop.',
  ),
  NewsSite(
    'Jagat Play',
    'https://jagatplay.com/',
    'Indonesia',
    ['Gaming'],
    'Ulasan game dan kabar industri.',
  ),
  NewsSite('GGWP.id', 'https://www.ggwp.id/', 'Indonesia', [
    'Gaming',
    'Esports',
  ], 'Gaming dan esports.'),
  NewsSite(
    'BBC News Indonesia',
    'https://www.bbc.com/indonesia',
    'Britania Raya',
    ['Internasional'],
    'Berita dunia dalam bahasa Indonesia.',
  ),
  NewsSite(
    'Al Jazeera English',
    'https://www.aljazeera.com/',
    'Qatar',
    ['Internasional'],
    'Berita dan laporan global.',
  ),
  NewsSite(
    'Reuters',
    'https://www.reuters.com/',
    'Britania Raya',
    ['Internasional'],
    'Kantor berita internasional.',
  ),
  NewsSite(
    'DW Indonesia',
    'https://www.dw.com/id',
    'Jerman',
    ['Internasional'],
    'Berita dunia dalam bahasa Indonesia.',
  ),
  NewsSite(
    'The New York Times',
    'https://www.nytimes.com/',
    'Amerika Serikat',
    ['Internasional'],
    'Berita dan liputan dari Amerika Serikat dan dunia.',
  ),
  NewsSite(
    'Sky Sports Football',
    'https://www.skysports.com/football',
    'Britania Raya',
    ['Bola'],
    'Berita sepak bola Inggris dan dunia.',
  ),
  NewsSite(
    'Autosport',
    'https://www.autosport.com/f1/',
    'Britania Raya',
    ['F1'],
    'Berita dan analisis Formula 1.',
  ),
  NewsSite(
    'Formula 1',
    'https://www.formula1.com/',
    'Britania Raya',
    ['F1'],
    'Situs resmi Formula 1.',
  ),
  NewsSite(
    'Motorsport.com F1',
    'https://www.motorsport.com/f1/',
    'Amerika Serikat',
    ['F1'],
    'Berita dan hasil Formula 1.',
  ),
  NewsSite(
    'RaceFans',
    'https://www.racefans.net/',
    'Britania Raya',
    ['F1'],
    'Analisis dan berita paddock F1.',
  ),
  NewsSite('MotoGP', 'https://www.motogp.com/', 'Spanyol', [
    'MotoGP',
  ], 'Situs resmi MotoGP.'),
  NewsSite(
    'Crash.net MotoGP',
    'https://www.crash.net/motogp',
    'Britania Raya',
    ['MotoGP'],
    'Berita balap motor dan MotoGP.',
  ),
  NewsSite(
    'Motorsport.com MotoGP',
    'https://www.motorsport.com/motogp/',
    'Amerika Serikat',
    ['MotoGP'],
    'Berita dan analisis MotoGP.',
  ),
  NewsSite(
    'PUBG Esports',
    'https://pubgesports.com/',
    'Korea Selatan',
    ['PUBG'],
    'Situs resmi kompetisi PUBG Esports.',
  ),
  NewsSite(
    'Liquipedia',
    'https://liquipedia.net/',
    'Internasional',
    ['MLBB', 'PUBG', 'CS2', 'Valorant', 'Esports'],
    'Wiki turnamen dan data esports.',
  ),
  NewsSite(
    'HLTV.org',
    'https://www.hltv.org/',
    'Denmark',
    ['CS2'],
    'Berita, skor, dan statistik Counter-Strike.',
  ),
  NewsSite(
    'Dexerto',
    'https://www.dexerto.com/cs2/',
    'Britania Raya',
    ['CS2', 'Gaming'],
    'Berita gaming dan Counter-Strike.',
  ),
  NewsSite(
    'Dot Esports',
    'https://dotesports.com/',
    'Amerika Serikat',
    ['CS2', 'Valorant', 'Esports'],
    'Berita game kompetitif.',
  ),
  NewsSite(
    'Dust2.us',
    'https://www.dust2.us/',
    'Amerika Serikat',
    ['CS2'],
    'Kompetisi dan kabar Counter-Strike.',
  ),
  NewsSite(
    'VLR.gg',
    'https://www.vlr.gg/',
    'Internasional',
    ['Valorant'],
    'Jadwal, hasil, dan statistik Valorant.',
  ),
  NewsSite(
    'THESPIKE.gg',
    'https://www.thespike.gg/',
    'Internasional',
    ['Valorant'],
    'Berita dan data kompetitif Valorant.',
  ),
];

const recommendedExtraSites = <NewsSite>[
  NewsSite(
    'Tribunnews.com',
    'https://www.tribunnews.com/',
    'Indonesia',
    ['Nasional'],
    'Berita daerah dan nasional Indonesia.',
  ),
  NewsSite(
    'Sindonews.com',
    'https://www.sindonews.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Berita nasional, ekonomi, dan internasional.',
  ),
  NewsSite(
    'Republika.co.id',
    'https://www.republika.co.id/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Portal berita nasional dan dunia Islam.',
  ),
  NewsSite(
    'Merdeka.com',
    'https://www.merdeka.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Berita politik, peristiwa, dan gaya hidup.',
  ),
  NewsSite(
    'Tirto.id',
    'https://tirto.id/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Jurnalisme data, riset, dan berita mendalam.',
  ),
  NewsSite(
    'CNBC Indonesia',
    'https://www.cnbcindonesia.com/',
    'Indonesia',
    ['Nasional', 'Internasional'],
    'Berita bisnis, pasar modal, dan ekonomi.',
  ),
  NewsSite(
    'Katadata',
    'https://katadata.co.id/',
    'Indonesia',
    ['Nasional'],
    'Berita ekonomi, riset, dan analisis data.',
  ),
  NewsSite(
    'Bisnis.com',
    'https://www.bisnis.com/',
    'Indonesia',
    ['Nasional'],
    'Berita keuangan, industri, dan market.',
  ),
  NewsSite(
    'Suara.com',
    'https://www.suara.com/',
    'Indonesia',
    ['Nasional'],
    'Berita terkini, bola, dan hiburan Indonesia.',
  ),
  NewsSite(
    'Okezone',
    'https://www.okezone.com/',
    'Indonesia',
    ['Nasional'],
    'Portal berita nasional, olahraga, dan tekno.',
  ),
  NewsSite(
    'VIVA.co.id',
    'https://www.viva.co.id/',
    'Indonesia',
    ['Nasional'],
    'Berita politik, bola, dan otomotif.',
  ),
  NewsSite(
    'IDN Times',
    'https://www.idntimes.com/',
    'Indonesia',
    ['Nasional'],
    'Berita generasi muda dan tren terkini.',
  ),
  NewsSite(
    'BBC Sport',
    'https://www.bbc.com/sport',
    'Britania Raya',
    ['Bola', 'F1'],
    'Berita dan skor olahraga internasional.',
  ),
  NewsSite(
    'ESPN',
    'https://www.espn.com/',
    'Amerika Serikat',
    ['Bola', 'F1'],
    'Liputan olahraga dunia dan hasil pertandingan.',
  ),
  NewsSite(
    'CNN International',
    'https://edition.cnn.com/',
    'Amerika Serikat',
    ['Internasional'],
    'Berita dunia dan liputan internasional.',
  ),
  NewsSite(
    'The Guardian',
    'https://www.theguardian.com/',
    'Britania Raya',
    ['Internasional'],
    'Berita, opini, dan investigasi global.',
  ),
  NewsSite(
    'IGN',
    'https://www.ign.com/',
    'Amerika Serikat',
    ['Gaming'],
    'Ulasan game, film, dan berita hiburan.',
  ),
  NewsSite(
    'PC Gamer',
    'https://www.pcgamer.com/',
    'Britania Raya',
    ['Gaming'],
    'Berita dan review game PC dan hardware.',
  ),
  NewsSite(
    'The Verge',
    'https://www.theverge.com/',
    'Amerika Serikat',
    ['Internasional'],
    'Berita teknologi, gadget, dan sains.',
  ),
  NewsSite(
    'TechCrunch',
    'https://techcrunch.com/',
    'Amerika Serikat',
    ['Internasional'],
    'Berita startup, AI, dan industri teknologi.',
  ),
];

List<NewsSite> buildAllCatalogSites() {
  final seenHosts = <String>{};
  final result = <NewsSite>[];
  for (final raw in [...defaultSites, ...recommendedExtraSites]) {
    final host = raw.host.toLowerCase();
    if (!seenHosts.add(host)) continue;
    result.add(
      raw.copyWith(
        categoryIds: [if (raw.isSport) 'sport', if (raw.isGaming) 'gaming'],
      ),
    );
  }
  return result;
}

class BrowserApp {
  const BrowserApp({
    required this.packageName,
    required this.label,
    this.iconBytes,
  });
  final String packageName;
  final String label;
  final Uint8List? iconBytes;
}

class BrowserLauncher {
  static const _channel = MethodChannel('yornews/browser');
  static const _prefPackageKey = 'yornews_default_browser_pkg';
  static const _prefLabelKey = 'yornews_default_browser_label';

  static Future<({String? packageName, String? label})>
  getSavedBrowser() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      packageName: prefs.getString(_prefPackageKey),
      label: prefs.getString(_prefLabelKey),
    );
  }

  static Future<void> saveBrowser(BrowserApp browser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPackageKey, browser.packageName);
    await prefs.setString(_prefLabelKey, browser.label);
  }

  static Future<void> clearSavedBrowser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPackageKey);
    await prefs.remove(_prefLabelKey);
  }

  static Future<List<BrowserApp>> getInstalledBrowsers() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const [];
    }
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>(
        'getInstalledBrowsers',
      );
      if (raw == null) return const [];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map((entry) {
            final iconRaw = entry['icon'];
            return BrowserApp(
              packageName: entry['packageName'] as String? ?? '',
              label: entry['label'] as String? ?? '',
              iconBytes: iconRaw is Uint8List && iconRaw.isNotEmpty
                  ? iconRaw
                  : null,
            );
          })
          .where((b) => b.packageName.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> _openInPackage(String url, String packageName) async {
    try {
      final ok = await _channel.invokeMethod<bool>('openUrlInBrowser', {
        'url': url,
        'packageName': packageName,
      });
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSite(
    BuildContext context,
    NewsSite site, {
    VoidCallback? onBrowserPreferenceChanged,
  }) async {
    final uri = Uri.tryParse(site.url);
    if (uri == null) return;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final browsers = await getInstalledBrowsers();
      if (browsers.isNotEmpty) {
        final saved = await getSavedBrowser();
        if (saved.packageName != null &&
            browsers.any((b) => b.packageName == saved.packageName)) {
          final launched = await _openInPackage(site.url, saved.packageName!);
          if (launched) return;
          await clearSavedBrowser();
          onBrowserPreferenceChanged?.call();
        }

        if (!context.mounted) return;
        final choice = await showModalBottomSheet<({BrowserApp browser, bool always})>(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF0D1B2B),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (_) => _BrowserPickerSheet(
            title: 'Buka ${site.name}',
            subtitle: site.host,
            browsers: browsers,
            initialPackage: saved.packageName,
          ),
        );
        if (choice == null) return;
        if (choice.always) {
          await saveBrowser(choice.browser);
          onBrowserPreferenceChanged?.call();
        }
        final launched = await _openInPackage(
          site.url,
          choice.browser.packageName,
        );
        if (launched) return;
      }
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka ${site.url}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka ${site.url}')),
        );
      }
    }
  }

  static Future<void> configureDefaultBrowser(
    BuildContext context, {
    VoidCallback? onBrowserPreferenceChanged,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pemilihan browser HP hanya tersedia di Android.'),
          ),
        );
      }
      return;
    }

    final browsers = await getInstalledBrowsers();
    if (!context.mounted) return;
    if (browsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada aplikasi browser yang terdeteksi di HP.'),
        ),
      );
      return;
    }

    final saved = await getSavedBrowser();
    if (!context.mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _BrowserDefaultConfigSheet(
        browsers: browsers,
        savedPackage: saved.packageName,
      ),
    );
    if (action == null) return;
    if (action == '__ask_every_time__') {
      await clearSavedBrowser();
      onBrowserPreferenceChanged?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akan selalu tanya browser saat buka website.'),
          ),
        );
      }
      return;
    }
    final picked = browsers.where((b) => b.packageName == action).firstOrNull;
    if (picked != null) {
      await saveBrowser(picked);
      onBrowserPreferenceChanged?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Browser utama diatur ke ${picked.label} (Selalu).'),
          ),
        );
      }
    }
  }
}

class _BrowserPickerSheet extends StatefulWidget {
  const _BrowserPickerSheet({
    required this.title,
    required this.subtitle,
    required this.browsers,
    this.initialPackage,
  });

  final String title;
  final String subtitle;
  final List<BrowserApp> browsers;
  final String? initialPackage;

  @override
  State<_BrowserPickerSheet> createState() => _BrowserPickerSheetState();
}

class _BrowserPickerSheetState extends State<_BrowserPickerSheet> {
  late BrowserApp _selected = widget.browsers.firstWhere(
    (b) => b.packageName == widget.initialPackage,
    orElse: () => widget.browsers.first,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2B435C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            'Pilih Google / browser dari HP (${widget.subtitle})',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8DA3B8)),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.browsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final browser = widget.browsers[index];
                final selected = browser.packageName == _selected.packageName;
                return InkWell(
                  onTap: () => setState(() => _selected = browser),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF132E4A)
                          : const Color(0xFF0A1624),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF51C8F5)
                            : const Color(0xFF1B3045),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (browser.iconBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              browser.iconBytes!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          const Icon(
                            Icons.public_rounded,
                            size: 30,
                            color: Color(0xFF51C8F5),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                browser.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                browser.packageName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7F96AC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selected
                              ? const Color(0xFF51C8F5)
                              : const Color(0xFF5E748A),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop((browser: _selected, always: false)),
                  child: const Text('Sekali saja'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop((browser: _selected, always: true)),
                  child: const Text('Selalu'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BrowserDefaultConfigSheet extends StatelessWidget {
  const _BrowserDefaultConfigSheet({
    required this.browsers,
    this.savedPackage,
  });

  final List<BrowserApp> browsers;
  final String? savedPackage;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2B435C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pengaturan Browser HP',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          const Text(
            'Pilih browser yang selalu dipakai, atau tanya setiap buka website.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8DA3B8)),
          ),
          const SizedBox(height: 14),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: savedPackage == null
                    ? const Color(0xFF51C8F5)
                    : const Color(0xFF1B3045),
              ),
            ),
            tileColor: savedPackage == null
                ? const Color(0xFF132E4A)
                : const Color(0xFF0A1624),
            leading: const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF51C8F5),
            ),
            title: const Text(
              'Tanya setiap buka website',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Tampilkan pilihan "Sekali saja / Selalu"',
              style: TextStyle(fontSize: 11, color: Color(0xFF8DA3B8)),
            ),
            trailing: Icon(
              savedPackage == null
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: savedPackage == null
                  ? const Color(0xFF51C8F5)
                  : const Color(0xFF5E748A),
            ),
            onTap: () => Navigator.of(context).pop('__ask_every_time__'),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: browsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final browser = browsers[index];
                final isDefault = browser.packageName == savedPackage;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDefault
                          ? const Color(0xFF51C8F5)
                          : const Color(0xFF1B3045),
                    ),
                  ),
                  tileColor: isDefault
                      ? const Color(0xFF132E4A)
                      : const Color(0xFF0A1624),
                  leading: browser.iconBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            browser.iconBytes!,
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Icon(Icons.public_rounded),
                  title: Text(
                    browser.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Selalu buka dengan ${browser.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8DA3B8),
                    ),
                  ),
                  trailing: isDefault
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF51C8F5),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(browser.packageName),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class YorNewsApp extends StatelessWidget {
  const YorNewsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'YorNews',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF07111F),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF36B7F4),
        brightness: Brightness.dark,
        surface: const Color(0xFF0D1B2B),
      ),
      fontFamily: 'Roboto',
    ),
    home: const DirectoryPage(),
  );
}

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key});
  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  final ScrollController _scrollController = ScrollController();
  List<NewsSite> _sites = defaultSites
      .map(
        (site) => site.copyWith(
          categoryIds: [if (site.isSport) 'sport', if (site.isGaming) 'gaming'],
        ),
      )
      .toList();
  List<NewsCategory> _categories = List.of(defaultCategories);
  String selected = 'all';
  String query = '';
  bool searchOpen = false;
  bool _openingSettings = false;
  bool _openingCatalog = false;
  String? _savedBrowserLabel;

  @override
  void initState() {
    super.initState();
    _restoreSites();
    _refreshBrowserLabel();
  }

  Future<void> _refreshBrowserLabel() async {
    final saved = await BrowserLauncher.getSavedBrowser();
    if (!mounted) return;
    setState(() => _savedBrowserLabel = saved.label);
  }

  Future<void> _restoreSites() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final savedSites = preferences.getString('yornews_sites');
      final savedCategories = preferences.getString('yornews_categories');
      final restoredSites = savedSites == null
          ? _sites
          : (jsonDecode(savedSites) as List<dynamic>)
                .map((item) => NewsSite.fromJson(item as Map<String, dynamic>))
                .toList();
      final restoredCategories = savedCategories == null
          ? _categories
          : (jsonDecode(savedCategories) as List<dynamic>)
                .map(
                  (item) => NewsCategory.fromJson(item as Map<String, dynamic>),
                )
                .toList();
      final migratedLiputan6 =
          preferences.getBool('yornews_migrated_liputan6_v1') ?? false;
      if (!migratedLiputan6) {
        if (savedSites != null &&
            !restoredSites.any(
              (site) => site.host.toLowerCase() == 'liputan6.com',
            )) {
          final liputan6 = defaultSites.firstWhere(
            (site) => site.host.toLowerCase() == 'liputan6.com',
          );
          final insertIndex = restoredSites.length < 2
              ? restoredSites.length
              : 2;
          restoredSites.insert(insertIndex, liputan6);
          await preferences.setString(
            'yornews_sites',
            jsonEncode(restoredSites.map((site) => site.toJson()).toList()),
          );
        }
        await preferences.setBool('yornews_migrated_liputan6_v1', true);
      }
      if (mounted) {
        setState(() {
          _sites = restoredSites;
          _categories = restoredCategories;
          if (selected != 'all' && !_categories.any((c) => c.id == selected)) {
            selected = 'all';
          }
        });
      }
    } catch (_) {
      await preferences.remove('yornews_sites');
      await preferences.remove('yornews_categories');
    }
  }

  Future<void> _persistAndApply(SettingsResult updated) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'yornews_sites',
      jsonEncode(updated.sites.map((site) => site.toJson()).toList()),
    );
    await preferences.setString(
      'yornews_categories',
      jsonEncode(
        updated.categories.map((category) => category.toJson()).toList(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _sites = updated.sites;
      _categories = updated.categories;
      if (selected != 'all' && !_categories.any((c) => c.id == selected)) {
        selected = 'all';
      }
    });
  }

  Future<void> _openWebsiteCatalog() async {
    if (_openingCatalog) return;
    _openingCatalog = true;
    try {
      final updatedSites = await Navigator.of(context).push<List<NewsSite>>(
        MaterialPageRoute(
          builder: (_) => WebsiteCatalogPage(
            initialSites: List.of(_sites),
            categories: List.of(_categories),
          ),
        ),
      );
      if (updatedSites == null || !mounted) return;
      await _persistAndApply(
        SettingsResult(updatedSites, List.of(_categories)),
      );
    } finally {
      _openingCatalog = false;
    }
  }

  Future<void> _openSettings() async {
    if (_openingSettings) return;
    _openingSettings = true;
    try {
      final updated = await Navigator.of(context).push<SettingsResult>(
        MaterialPageRoute(
          builder: (_) => SettingsPage(
            initialSites: List.of(_sites),
            initialCategories: List.of(_categories),
            onChanged: _persistAndApply,
          ),
        ),
      );
      if (!mounted) return;
      await _refreshBrowserLabel();
      if (updated == null || !mounted) return;
      await _persistAndApply(updated);
    } finally {
      _openingSettings = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<NewsSite> get visibleSites => _sites.where((site) {
    final category = _categories
        .where((item) => item.id == selected)
        .firstOrNull;
    final categoryMatch =
        selected == 'all' ||
        (category != null && siteBelongsToCategory(site, category));
    final queryMatch =
        query.isEmpty ||
        '${site.name} ${site.country} ${site.host} ${site.topics.join(' ')}'
            .toLowerCase()
            .contains(query.toLowerCase());
    return categoryMatch && queryMatch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final intlCount = _sites.where((s) => !s.isIndonesia).length;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cardExtent = 166 + (textScale - 1.0).clamp(0.0, 1.0) * 64;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: AppScrollbar(
              controller: _scrollController,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                      child: _header(intlCount),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                      child: _filters(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selected == 'all'
                                  ? 'Semua situs berita'
                                  : _categories
                                            .where((c) => c.id == selected)
                                            .firstOrNull
                                            ?.name ??
                                        'Semua situs berita',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${visibleSites.length} situs',
                            style: const TextStyle(color: Color(0xFF8DA3B8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (visibleSites.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Tidak ada situs yang cocok.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final columns = width > 760
                              ? 3
                              : width > 500
                              ? 2
                              : 1;
                          return SliverGrid.builder(
                            itemCount: visibleSites.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: cardExtent,
                                ),
                            itemBuilder: (context, index) => SiteCard(
                              site: visibleSites[index],
                              categories: _categories,
                              onBrowserPreferenceChanged: _refreshBrowserLabel,
                            ),
                          );
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 22),
                      child: Center(
                        child: Text(
                          'Situs dikelompokkan menurut negara asal medianya',
                          style: TextStyle(
                            color: Color(0xFF647A90),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(int intlCount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF21B8F3), Color(0xFF455FEA)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.newspaper_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YorNews',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                Text(
                  'Direktori situs berita pilihan',
                  style: TextStyle(color: Color(0xFF8DA3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Pilih atau tambah website',
            visualDensity: VisualDensity.compact,
            onPressed: _openWebsiteCatalog,
            icon: const Icon(
              Icons.playlist_add_rounded,
              color: Color(0xFF51C8F5),
            ),
          ),
          IconButton(
            tooltip: _savedBrowserLabel == null
                ? 'Browser HP: Tanya setiap buka'
                : 'Browser HP: $_savedBrowserLabel',
            visualDensity: VisualDensity.compact,
            onPressed: () => BrowserLauncher.configureDefaultBrowser(
              context,
              onBrowserPreferenceChanged: _refreshBrowserLabel,
            ),
            icon: Icon(
              Icons.open_in_browser_rounded,
              color: _savedBrowserLabel == null
                  ? const Color(0xFFB7C9DA)
                  : const Color(0xFF51C8F5),
            ),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            visualDensity: VisualDensity.compact,
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFB7C9DA)),
          ),
          IconButton(
            tooltip: 'Cari situs',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => searchOpen = !searchOpen),
            icon: Icon(
              searchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: const Color(0xFFB7C9DA),
            ),
          ),
        ],
      ),
      if (searchOpen) ...[
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) => setState(() => query = value.trim()),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari nama situs atau negara...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFF0D1B2B),
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102B48), Color(0xFF102039)],
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFF1D3D5A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Baca dari sumber pilihanmu',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_sites.length} situs • Indonesia dan $intlCount sumber internasional',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9BB1C6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.public_rounded,
              color: Color(0xFF4DC8F5),
              size: 34,
            ),
          ],
        ),
      ),
    ],
  );

  Widget _filters() => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length + 1,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final item = index == 0 ? null : _categories[index - 1];
        final id = item?.id ?? 'all';
        final label = item?.name ?? 'Semua';
        final active = selected == id;
        return ChoiceChip(
          label: Text(label),
          selected: active,
          onSelected: (_) => setState(() => selected = id),
          showCheckmark: false,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFF06121D) : const Color(0xFFB2C4D5),
          ),
          backgroundColor: const Color(0xFF0D1B2B),
          selectedColor: const Color(0xFF51C8F5),
          side: BorderSide(
            color: active ? const Color(0xFF51C8F5) : const Color(0xFF20344A),
          ),
        );
      },
    ),
  );
}

class SiteCard extends StatelessWidget {
  const SiteCard({
    super.key,
    required this.site,
    required this.categories,
    this.onBrowserPreferenceChanged,
  });
  final NewsSite site;
  final List<NewsCategory> categories;
  final VoidCallback? onBrowserPreferenceChanged;
  Color get accent =>
      site.isIndonesia ? const Color(0xFF4FC6F2) : const Color(0xFF9B9AFF);

  @override
  Widget build(BuildContext context) {
    final categoryNames = categories
        .where((category) => siteBelongsToCategory(site, category))
        .map((category) => category.name)
        .toList();
    return Material(
      color: const Color(0xFF0D1B2B),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => BrowserLauncher.openSite(
          context,
          site,
          onBrowserPreferenceChanged: onBrowserPreferenceChanged,
        ),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFF1B3045)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://www.google.com/s2/favicons?domain=${site.host}&sz=128',
                        width: 39,
                        height: 39,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            site.initialLetter,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, size: 17, color: accent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                site.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7F96AC)),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  site.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: Color(0xFFADBDCC),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tag(site.country, accent),
                    for (final topic in categoryNames) ...[
                      const SizedBox(width: 5),
                      _tag(topic, const Color(0xFF7E96AB)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.initialSites,
    required this.initialCategories,
    this.onChanged,
  });
  final List<NewsSite> initialSites;
  final List<NewsCategory> initialCategories;
  final ValueChanged<SettingsResult>? onChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  late final List<NewsSite> _sites = List.of(widget.initialSites);
  late final List<NewsCategory> _categories = List.of(widget.initialCategories);
  bool _isClosing = false;
  String? _savedBrowserLabel;

  @override
  void initState() {
    super.initState();
    _refreshBrowserLabel();
  }

  Future<void> _refreshBrowserLabel() async {
    final saved = await BrowserLauncher.getSavedBrowser();
    if (!mounted) return;
    setState(() => _savedBrowserLabel = saved.label);
  }

  Future<void> _openWebsiteCatalog() async {
    final updatedSites = await Navigator.of(context).push<List<NewsSite>>(
      MaterialPageRoute(
        builder: (_) => WebsiteCatalogPage(
          initialSites: List.of(_sites),
          categories: List.of(_categories),
        ),
      ),
    );
    if (!mounted || updatedSites == null) return;
    setState(() {
      _sites
        ..clear()
        ..addAll(updatedSites);
    });
    _notifyChanged();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      SettingsResult(List.of(_sites), List.of(_categories)),
    );
  }

  Future<void> _editSite([int? index]) async {
    final edited = await Navigator.of(context).push<NewsSite>(
      MaterialPageRoute(
        builder: (_) => SiteEditorPage(
          site: index == null ? null : _sites[index],
          categories: List.of(_categories),
        ),
      ),
    );
    if (!mounted || edited == null) return;
    setState(() {
      if (index == null) {
        _sites.add(edited);
      } else {
        _sites[index] = edited;
      }
    });
    _notifyChanged();
  }

  Future<void> _deleteSite(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus situs?'),
        content: Text(
          '“${_sites[index].name}” akan dihapus dari daftar YorNews dan hilang dari kategori yang terkait. Kategori serta situs lain tetap ada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _sites.removeAt(index));
      _notifyChanged();
    }
  }

  int _categorySiteCount(NewsCategory category) =>
      _sites.where((site) => siteBelongsToCategory(site, category)).length;

  Future<void> _editCategory([int? index]) async {
    final existingNames = _categories
        .where((c) => index == null || c.id != _categories[index].id)
        .map((c) => c.name.trim().toLowerCase())
        .toSet();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryDialog(
        title: index == null ? 'Tambah kategori' : 'Edit kategori',
        initialName: index == null ? '' : _categories[index].name,
        existingNamesLower: existingNames,
      ),
    );
    if (!mounted || name == null || name.isEmpty) return;
    setState(() {
      if (index == null) {
        _categories.add(
          NewsCategory(
            id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
            name: name,
          ),
        );
      } else {
        _categories[index] = _categories[index].copyWith(name: name);
      }
    });
    _notifyChanged();
  }

  Future<void> _deleteCategory(int index) async {
    final category = _categories[index];
    final count = _categorySiteCount(category);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text(
          'Kategori “${category.name}” memiliki $count situs. Jika dihapus, situs-situs itu hilang dari kategori ini. Situsnya tetap tersimpan di YorNews dan bisa muncul di kategori lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus kategori'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _categories.removeAt(index);
      for (var i = 0; i < _sites.length; i++) {
        _sites[i] = _sites[i].copyWith(
          categoryIds: _sites[i].categoryIds
              .where((id) => id != category.id)
              .toList(),
        );
      }
    });
    _notifyChanged();
  }

  void _goBack() {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.of(
      context,
    ).pop<SettingsResult>(SettingsResult(List.of(_sites), List.of(_categories)));
  }

  @override
  Widget build(BuildContext context) => PopScope<SettingsResult>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _goBack();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali ke YorNews',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Pengaturan'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: AppScrollbar(
              controller: _scrollController,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10243A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF203D59)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: Color(0xFF51C8F5)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kelola YorNews',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Atur kategori, browser HP, dan daftar website sesuai pilihanmu.',
                                style: TextStyle(
                                  color: Color(0xFF9BB1C6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1B3045)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF51C8F5).withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.open_in_browser_rounded,
                            color: Color(0xFF51C8F5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Browser HP saat buka website',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _savedBrowserLabel == null
                                    ? 'Tanya setiap buka website (Sekali / Selalu)'
                                    : 'Selalu pakai: $_savedBrowserLabel',
                                style: const TextStyle(
                                  color: Color(0xFF9BB1C6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () =>
                              BrowserLauncher.configureDefaultBrowser(
                                context,
                                onBrowserPreferenceChanged:
                                    _refreshBrowserLabel,
                              ),
                          child: const Text('Atur'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _editCategory(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Belum ada kategori.'),
                    )
                  else
                    ...List.generate(_categories.length, (index) {
                      final category = _categories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B2B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1B3045)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${category.name} · ${_categorySiteCount(category)} situs',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit kategori',
                              onPressed: () => _editCategory(index),
                              icon: const Icon(Icons.edit_outlined, size: 19),
                            ),
                            IconButton(
                              tooltip: 'Hapus kategori',
                              onPressed: () => _deleteCategory(index),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Color(0xFFFF8585),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${_sites.length} situs',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _openWebsiteCatalog,
                            icon: const Icon(Icons.playlist_add_rounded),
                            label: const Text('Pilih website'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _editSite(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah manual'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_sites.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('Belum ada situs.')),
                    )
                  else
                    ...List.generate(_sites.length, (index) {
                      final site = _sites[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.fromLTRB(14, 11, 7, 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B2B),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF1B3045)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF36B7F4,
                                ).withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                site.initialLetter,
                                style: const TextStyle(
                                  color: Color(0xFF51C8F5),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    site.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${site.country} · ${site.host}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF879DB2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit situs',
                              onPressed: () => _editSite(index),
                              icon: const Icon(Icons.edit_outlined, size: 19),
                            ),
                            IconButton(
                              tooltip: 'Hapus situs',
                              onPressed: () => _deleteSite(index),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Color(0xFFFF8585),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Kembali ke YorNews'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    required this.title,
    required this.initialName,
    required this.existingNamesLower,
  });

  final String title;
  final String initialName;
  final Set<String> existingNamesLower;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorText = 'Nama kategori wajib diisi.');
      return;
    }
    if (widget.existingNamesLower.contains(trimmed.toLowerCase())) {
      setState(() => _errorText = 'Nama kategori itu sudah digunakan.');
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 32,
      decoration: InputDecoration(
        labelText: 'Nama kategori',
        border: const OutlineInputBorder(),
        errorText: _errorText,
      ),
      onChanged: (_) {
        if (_errorText != null) setState(() => _errorText = null);
      },
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _submit,
        child: const Text('Simpan'),
      ),
    ],
  );
}

class SiteEditorPage extends StatefulWidget {
  const SiteEditorPage({super.key, this.site, required this.categories});
  final NewsSite? site;
  final List<NewsCategory> categories;

  @override
  State<SiteEditorPage> createState() => _SiteEditorPageState();
}

class _SiteEditorPageState extends State<SiteEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.site?.name);
  late final _urlController = TextEditingController(text: widget.site?.url);
  late final _countryController = TextEditingController(
    text: widget.site?.country,
  );
  late final _noteController = TextEditingController(text: widget.site?.note);
  late final Set<String> _selectedCategoryIds =
      widget.site?.categoryIds.toSet() ?? {};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _countryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    _isSaving = true;
    final site = NewsSite(
      _nameController.text.trim(),
      _urlController.text.trim(),
      _countryController.text.trim(),
      widget.site?.topics ?? const [],
      _noteController.text.trim(),
      categoryIds: _selectedCategoryIds.toList(),
    );
    Navigator.of(context).pop(site);
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi' : null;

  String? _validateUrl(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final uri = Uri.tryParse(value!.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return 'Masukkan URL lengkap, misalnya https://contoh.com';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.site == null ? 'Tambah situs' : 'Edit situs'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama situs',
                    hintText: 'Contoh: Kompas.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL situs',
                    hintText: 'https://contoh.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateUrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Negara asal media',
                    hintText: 'Indonesia',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi singkat',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: _required,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kategori',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.categories.map((category) {
                    final isRegion =
                        category.kind == 'national' ||
                        category.kind == 'international';
                    final countryIsIndonesia =
                        _countryController.text.trim().toLowerCase() ==
                        'indonesia';
                    final isSelected = switch (category.kind) {
                      'national' => countryIsIndonesia,
                      'international' =>
                        !countryIsIndonesia &&
                            _countryController.text.trim().isNotEmpty,
                      _ => _selectedCategoryIds.contains(category.id),
                    };
                    return FilterChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: isRegion
                          ? null
                          : (value) => setState(() {
                              if (value) {
                                _selectedCategoryIds.add(category.id);
                              } else {
                                _selectedCategoryIds.remove(category.id);
                              }
                            }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan situs'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class WebsiteCatalogPage extends StatefulWidget {
  const WebsiteCatalogPage({
    super.key,
    required this.initialSites,
    required this.categories,
  });

  final List<NewsSite> initialSites;
  final List<NewsCategory> categories;

  @override
  State<WebsiteCatalogPage> createState() => _WebsiteCatalogPageState();
}

class _WebsiteCatalogPageState extends State<WebsiteCatalogPage> {
  final ScrollController _scrollController = ScrollController();
  late final List<NewsSite> _catalogSites = buildAllCatalogSites();
  late final Map<String, NewsSite> _existingByKey = {
    for (final site in widget.initialSites) _siteKey(site): site,
  };
  late final Set<String> _selectedKeys = {
    for (final site in widget.initialSites) _siteKey(site),
  };
  late final List<NewsSite> _customSites = [
    for (final site in widget.initialSites)
      if (!_catalogKeys.contains(_siteKey(site))) site,
  ];
  late final Set<String> _catalogKeys = {
    for (final site in _catalogSites) _siteKey(site),
  };

  String _query = '';
  String _selectedCategory = 'all';

  static String _siteKey(NewsSite site) {
    final uri = Uri.tryParse(site.url.trim());
    if (uri == null || uri.host.isEmpty) {
      return site.url.trim().toLowerCase();
    }
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    return path.isEmpty ? host : '$host$path';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<NewsSite> get _allDisplaySites => [..._customSites, ..._catalogSites];

  List<NewsSite> get _filteredSites {
    final needle = _query.trim().toLowerCase();
    final activeCategory = _selectedCategory == 'all'
        ? null
        : widget.categories.where((c) => c.id == _selectedCategory).firstOrNull;
    return _allDisplaySites.where((site) {
      if (activeCategory != null &&
          !siteBelongsToCategory(site, activeCategory)) {
        return false;
      }
      if (needle.isEmpty) return true;
      return '${site.name} ${site.host} ${site.country} ${site.note}'
          .toLowerCase()
          .contains(needle);
    }).toList();
  }

  void _toggleSite(NewsSite site) {
    final key = _siteKey(site);
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  Future<void> _addCustomWebsite() async {
    final created = await Navigator.of(context).push<NewsSite>(
      MaterialPageRoute(
        builder: (_) =>
            SiteEditorPage(categories: List.of(widget.categories)),
      ),
    );
    if (!mounted || created == null) return;
    final key = _siteKey(created);
    setState(() {
      final catalogIndex = _catalogSites.indexWhere(
        (site) => _siteKey(site) == key,
      );
      if (catalogIndex >= 0) {
        _existingByKey[key] = created;
      } else {
        final customIndex = _customSites.indexWhere(
          (site) => _siteKey(site) == key,
        );
        if (customIndex >= 0) {
          _customSites[customIndex] = created;
        } else {
          _customSites.insert(0, created);
        }
      }
      _selectedKeys.add(key);
    });
  }

  void _saveSelection() {
    final selected = <NewsSite>[];
    final seen = <String>{};
    // Preserve custom/existing site edits while keeping catalog additions cleanly ordered.
    for (final site in widget.initialSites) {
      final key = _siteKey(site);
      if (_selectedKeys.contains(key) && seen.add(key)) {
        selected.add(_existingByKey[key] ?? site);
      }
    }
    for (final site in [..._customSites, ..._catalogSites]) {
      final key = _siteKey(site);
      if (_selectedKeys.contains(key) && seen.add(key)) {
        selected.add(_existingByKey[key] ?? site);
      }
    }
    Navigator.of(context).pop<List<NewsSite>>(selected);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredSites;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Website'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saveSelection,
              child: Text('Simpan (${_selectedKeys.length})'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Cari website berita (mis. Liputan6, Kompas)...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFF0D1B2B),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF20344A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.categories.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final item = index == 0
                                ? null
                                : widget.categories[index - 1];
                            final id = item?.id ?? 'all';
                            final label = item?.name ?? 'Semua';
                            final active = _selectedCategory == id;
                            return ChoiceChip(
                              label: Text(label),
                              selected: active,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = id),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? const Color(0xFF06121D)
                                    : const Color(0xFFB2C4D5),
                              ),
                              backgroundColor: const Color(0xFF0D1B2B),
                              selectedColor: const Color(0xFF51C8F5),
                              side: BorderSide(
                                color: active
                                    ? const Color(0xFF51C8F5)
                                    : const Color(0xFF20344A),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _addCustomWebsite,
                        icon: const Icon(Icons.add_link_rounded),
                        label: const Text('Tambah Website Sendiri (URL Manual)'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child: Text(
                            'Website tidak ditemukan di katalog.',
                            style: TextStyle(color: Color(0xFF8FA5BA)),
                          ),
                        )
                      : AppScrollbar(
                          controller: _scrollController,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final site = visible[index];
                              final key = _siteKey(site);
                              final checked = _selectedKeys.contains(key);
                              final isCustom = !_catalogKeys.contains(key);
                              return Material(
                                color: checked
                                    ? const Color(0xFF10253A)
                                    : const Color(0xFF0D1B2B),
                                borderRadius: BorderRadius.circular(14),
                                child: CheckboxListTile(
                                  value: checked,
                                  onChanged: (_) => _toggleSite(site),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: checked
                                          ? const Color(0xFF51C8F5)
                                                .withValues(alpha: .5)
                                          : const Color(0xFF1B3045),
                                    ),
                                  ),
                                  activeColor: const Color(0xFF51C8F5),
                                  checkColor: const Color(0xFF06121D),
                                  title: Text(
                                    isCustom
                                        ? '${site.name} (Custom)'
                                        : site.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${site.host} · ${site.country} — ${site.note}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF9BB1C6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B1522),
                    border: Border(top: BorderSide(color: Color(0xFF1B3045))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedKeys.length} website dipilih',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB2C4D5),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _saveSelection,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Simpan Pilihan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
