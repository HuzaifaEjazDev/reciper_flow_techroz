import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';

class BookmarkedRecipesScreen extends StatelessWidget {
  const BookmarkedRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_BookmarksPager>(
      create: (_) => _BookmarksPager(FirestoreRecipesService())..loadInitial(),
      child: const _BookmarkedRecipesView(),
    );
  }
}

class _BookmarkedRecipesView extends StatelessWidget {
  const _BookmarkedRecipesView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<_BookmarksPager>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bookmarked Recipes'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54, size: 20),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search bookmarks...',
                                hintStyle: TextStyle(color: Colors.black54, fontSize: 15),
                              ),
                              onChanged: (v) => vm.setQueryTemp(v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => vm.applySearch(),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F00),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (vm.loading && vm.items.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.items.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, index) {
                          final r = vm.items[index];
                          return _BookmarkCard(title: r['title']?.toString() ?? '', imageUrl: r['imageUrl']?.toString() ?? '', minutes: (r['minutes'] is int) ? r['minutes'] as int : 0);
                        },
                      ),
                      const SizedBox(height: 12),
                      _PageControls(vm: vm),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final int minutes;
  const _BookmarkCard({required this.title, required this.imageUrl, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: imageUrl.startsWith('http')
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Image.asset(imageUrl.isEmpty ? 'assets/images/easymakesnack1.jpg' : imageUrl, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text('$minutes min', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarksPager extends ChangeNotifier {
  _BookmarksPager(this._service);
  final FirestoreRecipesService _service;
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  bool loading = false;
  String? error;
  String? _lastId;
  // bool _hasMore = true; // not needed with total count
  int _currentPage = 1;
  final int _pageSize = 10;
  final Map<int, String?> _pageToCursor = <int, String?>{1: null};
  final Map<int, String?> _pageToTitleCursor = <int, String?>{1: null};
  int _totalCount = 0;
  String _activeQuery = '';
  String _queryTemp = '';

  Future<void> loadInitial() async {
    _items.clear();
    _lastId = null;
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    _pageToTitleCursor
      ..clear()
      ..addAll({1: null});
    await _loadTotalCount();
    await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
  }

  Future<void> _loadPageAtCursor({required String? startAfterId}) async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (_activeQuery.isNotEmpty) {
        final page = await _service.fetchBookmarksPageByTitlePrefix(
          limit: _pageSize,
          startAfterTitle: _pageToTitleCursor[_currentPage],
          prefix: _activeQuery,
        );
        _items
          ..clear()
          ..addAll(page.items);
        final String? lastTitle = page.lastTitle;
        _pageToTitleCursor[_currentPage + 1] = lastTitle;
      } else {
        final page = await _service.fetchBookmarksPage(limit: _pageSize, startAfterId: startAfterId);
        _items
          ..clear()
          ..addAll(page.items);
        _lastId = page.lastId;
      // _hasMore = page.lastId != null;
        _pageToCursor[_currentPage + 1] = _lastId;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1) return;
    int anchor = pageNumber;
    if (_activeQuery.isNotEmpty) {
      while (anchor > 1 && !_pageToTitleCursor.containsKey(anchor)) {
        anchor--;
      }
      for (int p = anchor; p < pageNumber; p++) {
        final String? cursor = _pageToTitleCursor[p];
        final next = await _service.fetchBookmarksPageByTitlePrefix(
          limit: _pageSize,
          startAfterTitle: cursor,
          prefix: _activeQuery,
        );
        _pageToTitleCursor[p + 1] = next.lastTitle;
        if (next.lastTitle == null) break;
      }
    } else {
      while (anchor > 1 && !_pageToCursor.containsKey(anchor)) {
        anchor--;
      }
      for (int p = anchor; p < pageNumber; p++) {
        final String? cursor = _pageToCursor[p];
        final next = await _service.fetchBookmarksPage(limit: _pageSize, startAfterId: cursor);
        _pageToCursor[p + 1] = next.lastId;
        if (next.lastId == null) break;
      }
    }
    _currentPage = pageNumber;
    await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
  }

  int get currentPage => _currentPage;
  int get totalPages => (_totalCount == 0) ? 0 : ((_totalCount + _pageSize - 1) ~/ _pageSize);
  int get totalCount => _totalCount;

  Future<void> _loadTotalCount() async {
    try {
      _totalCount = _activeQuery.isNotEmpty
          ? await _service.fetchBookmarksCountByTitlePrefix(_activeQuery)
          : await _service.fetchBookmarksCount();
    } catch (_) {
      _totalCount = ((_pageToCursor.length - 1) * _pageSize) + _items.length;
    }
    notifyListeners();
  }

  void setQueryTemp(String v) {
    _queryTemp = v;
  }

  Future<void> applySearch() async {
    _activeQuery = _queryTemp.trim();
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    _pageToTitleCursor
      ..clear()
      ..addAll({1: null});
    await _loadTotalCount();
    await _loadPageAtCursor(startAfterId: _pageToCursor[_currentPage]);
  }
}

class _PageControls extends StatelessWidget {
  final _BookmarksPager vm;
  const _PageControls({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.items.isEmpty && vm.loading) return const SizedBox.shrink();
    final int totalPages = vm.totalPages;
    if (totalPages <= 1) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: totalPages,
            itemBuilder: (context, index) {
              final int page = index + 1;
              final bool selected = vm.currentPage == page;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: vm.loading ? null : () => vm.goToPage(page),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? Colors.deepOrange : Colors.white,
                    foregroundColor: selected ? Colors.white : Colors.black87,
                    side: BorderSide(color: selected ? Colors.deepOrange : const Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text('$page', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          vm.totalCount > 0
              ? 'Page ${vm.currentPage} of $totalPages  •  ${vm.totalCount} total BookMarked Recipes'
              : 'Loading pages…',
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


