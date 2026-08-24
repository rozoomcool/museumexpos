import 'package:flutter/foundation.dart';

import '../data/catalog.dart';

enum LoadStatus { loading, ready, failed }

/// Единое состояние экрана: выбранная категория, выбранный экспонат, поиск
/// и пропорция раскладки «модель / описание».
class GalleryState extends ChangeNotifier {
  GalleryState(this._repository) {
    load();
  }

  final CatalogRepository _repository;

  LoadStatus _status = LoadStatus.loading;
  Object? _error;
  Catalog? _catalog;
  String? _categoryId;
  String? _exhibitId;
  String _query = '';
  double _splitRatio = kDefaultSplitRatio;

  /// Доля ширины под 3D-сцену: 40 % против 60 % под описание и фотографии.
  static const kDefaultSplitRatio = 0.4;
  static const kMinSplitRatio = 0.25;
  static const kMaxSplitRatio = 0.65;

  LoadStatus get status => _status;
  Object? get error => _error;
  Catalog? get catalog => _catalog;
  String get query => _query;
  bool get isSearching => _query.trim().isNotEmpty;
  double get splitRatio => _splitRatio;

  List<ExhibitCategory> get categories => _catalog?.categories ?? const [];

  ExhibitCategory? get category {
    if (_categoryId == null) return null;
    for (final c in categories) {
      if (c.id == _categoryId) return c;
    }
    return null;
  }

  Exhibit? get exhibit {
    if (_exhibitId == null) return null;
    for (final e in _catalog?.allExhibits ?? const <Exhibit>[]) {
      if (e.id == _exhibitId) return e;
    }
    return null;
  }

  /// Экспонаты, которые показывает секция «Просмотр» и лента «Модели».
  List<Exhibit> get visibleExhibits {
    if (_catalog == null) return const [];
    if (isSearching) {
      final needle = _query.trim().toLowerCase();
      return _catalog!.allExhibits
          .where(
            (e) =>
                e.title.toLowerCase().contains(needle) ||
                e.reason.toLowerCase().contains(needle),
          )
          .toList(growable: false);
    }
    return category?.exhibits ?? const [];
  }

  int get selectedIndex =>
      _exhibitId == null ? -1 : visibleExhibits.indexWhere((e) => e.id == _exhibitId);

  bool get hasPrevious => selectedIndex > 0;
  bool get hasNext =>
      selectedIndex >= 0 && selectedIndex < visibleExhibits.length - 1;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final catalog = await _repository.load();
      _catalog = catalog;
      _categoryId = catalog.categories.isNotEmpty ? catalog.categories.first.id : null;
      _exhibitId = null;
      _status = LoadStatus.ready;
    } catch (e) {
      _error = e;
      _status = LoadStatus.failed;
    }
    notifyListeners();
  }

  void selectCategory(String id) {
    if (_categoryId == id && !isSearching) return;
    _categoryId = id;
    _exhibitId = null;
    _query = '';
    notifyListeners();
  }

  void selectExhibit(Exhibit exhibit) {
    if (_exhibitId == exhibit.id) return;
    _exhibitId = exhibit.id;
    // Раздел всегда подтягивается под выбранный предмет: клик по результату
    // поиска переносит в его категорию, чтобы лента «Модели» показывала
    // осмысленное окружение экспоната.
    _categoryId = exhibit.categoryId;
    if (isSearching) _query = '';
    notifyListeners();
  }

  void clearSelection() {
    if (_exhibitId == null) return;
    _exhibitId = null;
    notifyListeners();
  }

  void step(int delta) {
    final items = visibleExhibits;
    final index = selectedIndex;
    if (index < 0) return;
    final next = index + delta;
    if (next < 0 || next >= items.length) return;
    _exhibitId = items[next].id;
    notifyListeners();
  }

  void search(String value) {
    if (_query == value) return;
    _query = value;
    if (isSearching) _exhibitId = null;
    notifyListeners();
  }

  void setSplitRatio(double value) {
    final clamped = value.clamp(kMinSplitRatio, kMaxSplitRatio);
    if ((clamped - _splitRatio).abs() < 0.001) return;
    _splitRatio = clamped;
    notifyListeners();
  }

  void resetSplitRatio() {
    if (_splitRatio == kDefaultSplitRatio) return;
    _splitRatio = kDefaultSplitRatio;
    notifyListeners();
  }
}
