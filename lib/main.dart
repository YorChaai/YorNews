import 'dart:convert';

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _restoreSites();
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
            tooltip: 'Pengaturan',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFB7C9DA)),
          ),
          IconButton(
            tooltip: 'Cari situs',
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
  const SiteCard({super.key, required this.site, required this.categories});
  final NewsSite site;
  final List<NewsCategory> categories;
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
        onTap: () async {
          final uri = Uri.tryParse(site.url);
          if (uri == null) return;
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
        },
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
                                'Atur kategori dan situs berita sesuai pilihanmu.',
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_sites.length} situs',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _editSite(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah situs'),
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
