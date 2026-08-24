import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Экспонат: описание, фотографии и (не всегда) 3D-модель.
class Exhibit {
  const Exhibit({
    required this.id,
    required this.number,
    required this.title,
    required this.categoryId,
    required this.reason,
    required this.note,
    required this.sources,
    required this.photos,
    required this.thumbs,
    this.model,
  });

  final String id;

  /// Номер в кураторской подборке (1–60).
  final int number;
  final String title;
  final String categoryId;

  /// «Почему выбран» — основной текст описания.
  final String reason;
  final String note;
  final String sources;
  final List<String> photos;
  final List<String> thumbs;
  final String? model;

  bool get hasModel => model != null;
  bool get hasPhotos => photos.isNotEmpty;
  String? get cover => thumbs.isNotEmpty ? thumbs.first : null;

  factory Exhibit.fromJson(Map<String, dynamic> json) => Exhibit(
    id: json['id'] as String,
    number: json['number'] as int,
    title: json['title'] as String,
    categoryId: json['categoryId'] as String,
    reason: json['reason'] as String? ?? '',
    note: json['note'] as String? ?? '',
    sources: json['sources'] as String? ?? '',
    photos: (json['photos'] as List).cast<String>(),
    thumbs: (json['thumbs'] as List).cast<String>(),
    model: json['model'] as String?,
  );
}

/// Раздел коллекции.
class ExhibitCategory {
  const ExhibitCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.exhibits,
  });

  final String id;
  final String title;

  /// Ключ иконки из [categoryIcons].
  final String icon;
  final List<Exhibit> exhibits;

  int get modelCount => exhibits.where((e) => e.hasModel).length;

  factory ExhibitCategory.fromJson(Map<String, dynamic> json) => ExhibitCategory(
    id: json['id'] as String,
    title: json['title'] as String,
    icon: json['icon'] as String? ?? 'amphora',
    exhibits: (json['exhibits'] as List)
        .map((e) => Exhibit.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class Catalog {
  const Catalog({
    required this.title,
    required this.subtitle,
    required this.categories,
  });

  final String title;
  final String subtitle;
  final List<ExhibitCategory> categories;

  Iterable<Exhibit> get allExhibits => categories.expand((c) => c.exhibits);

  ExhibitCategory categoryOf(Exhibit exhibit) =>
      categories.firstWhere((c) => c.id == exhibit.categoryId);

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
    title: json['title'] as String,
    subtitle: json['subtitle'] as String? ?? '',
    categories: (json['categories'] as List)
        .map((e) => ExhibitCategory.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

/// Каталог собирается скриптом tools/build_assets.py и лежит в ассетах.
class CatalogRepository {
  const CatalogRepository();

  static const _path = 'assets/data/catalog.json';

  Future<Catalog> load() async {
    final raw = await rootBundle.loadString(_path);
    return Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
