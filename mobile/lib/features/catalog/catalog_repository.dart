import 'dart:convert';

import 'package:flutter/services.dart';

import 'catalog_item.dart';

class CatalogRepository {
  const CatalogRepository();

  Future<List<CatalogItem>> loadCatalog() async {
    final raw = await rootBundle.loadString('assets/catalog/catalog.json');
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException('catalog.json must be a JSON array');
    }

    return decoded
        .whereType<Map>()
        .map((e) => CatalogItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
