import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_item.dart';
import 'catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return const CatalogRepository();
});

final catalogProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final repo = ref.read(catalogRepositoryProvider);
  return repo.loadCatalog();
});
