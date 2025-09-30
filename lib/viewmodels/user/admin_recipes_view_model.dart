import 'package:flutter/foundation.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class AdminRecipeCardData {
  final String id;
  final String title;
  final String imageUrl;
  final int minutes;
  final double rating;
  const AdminRecipeCardData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.minutes,
    required this.rating,
  });
}

class AdminRecipesViewModel extends ChangeNotifier {
  AdminRecipesViewModel({FirestoreRecipesService? service})
      : _service = service ?? FirestoreRecipesService();

  final FirestoreRecipesService _service;

  final List<AdminRecipeCardData> _allItems = <AdminRecipeCardData>[];
  final List<AdminRecipeCardData> _items = <AdminRecipeCardData>[];
  String _query = '';
  String? _lastId;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  List<AdminRecipeCardData> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadInitial() async {
    _allItems.clear();
    _items.clear();
    _lastId = null;
    _hasMore = true;
    await _loadPage();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    await _loadPage();
  }

  Future<void> _loadPage() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await _service.fetchRecipesPage(collection: 'recipes', limit: 10, startAfterId: _lastId);
      _lastId = page.lastId;
      _hasMore = page.lastId != null;
      _allItems.addAll(page.items.map(_map));
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    _query = q;
    _applyFilter();
  }

  void _applyFilter() {
    final String q = _query.trim().toLowerCase();
    _items
      ..clear()
      ..addAll(q.isEmpty
          ? _allItems
          : _allItems.where((e) => e.title.toLowerCase().contains(q)));
  }

  AdminRecipeCardData _map(Map<String, dynamic> m) {
    final String id = (m['id'] ?? '').toString();
    final String title = (m['title'] ?? 'Untitled').toString();
    final String image = (m['imageUrl'] ?? m['image'] ?? '').toString();
    final int minutes = _safeInt(m['minutes']) ?? _safeInt(m['time']) ?? 0;
    final double rating = _safeDouble(m['rating']) ?? 0.0;
    return AdminRecipeCardData(
      id: id.isEmpty ? title : id,
      title: title,
      imageUrl: image,
      minutes: minutes,
      rating: rating,
    );
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}


