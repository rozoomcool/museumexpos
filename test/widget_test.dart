import 'package:chrexpo/data/catalog.dart';
import 'package:chrexpo/state/gallery_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('каталог читается из ассетов и не пустой', () async {
    final catalog = await const CatalogRepository().load();

    expect(catalog.categories, isNotEmpty);
    expect(catalog.allExhibits, isNotEmpty);
    for (final exhibit in catalog.allExhibits) {
      expect(exhibit.title, isNotEmpty);
      expect(catalog.categoryOf(exhibit).id, exhibit.categoryId);
    }
  });

  test('выбор категории сбрасывает выбранный экспонат', () async {
    final state = GalleryState(const CatalogRepository());
    await _untilReady(state);

    final first = state.categories.first;
    state.selectExhibit(first.exhibits.first);
    expect(state.exhibit, isNotNull);

    state.selectCategory(state.categories.last.id);
    expect(state.exhibit, isNull);
    expect(state.category?.id, state.categories.last.id);
  });

  test('поиск ищет по названию и описанию', () async {
    final state = GalleryState(const CatalogRepository());
    await _untilReady(state);

    final sample = state.catalog!.allExhibits.first;
    state.search(sample.title);
    expect(state.isSearching, isTrue);
    expect(state.visibleExhibits.map((e) => e.id), contains(sample.id));

    state.search('заведомо-несуществующий-запрос');
    expect(state.visibleExhibits, isEmpty);
  });

  test('шаги вперёд и назад не выходят за границы списка', () async {
    final state = GalleryState(const CatalogRepository());
    await _untilReady(state);

    final items = state.category!.exhibits;
    state.selectExhibit(items.first);
    expect(state.hasPrevious, isFalse);

    state.step(-1);
    expect(state.exhibit?.id, items.first.id);

    state.step(1);
    expect(state.exhibit?.id, items[1].id);
  });

  test('пропорция раскладки ограничена разумными пределами', () async {
    final state = GalleryState(const CatalogRepository());
    await _untilReady(state);

    expect(state.splitRatio, GalleryState.kDefaultSplitRatio);
    state.setSplitRatio(0.95);
    expect(state.splitRatio, GalleryState.kMaxSplitRatio);
    state.setSplitRatio(0.01);
    expect(state.splitRatio, GalleryState.kMinSplitRatio);
    state.resetSplitRatio();
    expect(state.splitRatio, GalleryState.kDefaultSplitRatio);
  });
}

Future<void> _untilReady(GalleryState state) async {
  while (state.status == LoadStatus.loading) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(state.status, LoadStatus.ready);
}
