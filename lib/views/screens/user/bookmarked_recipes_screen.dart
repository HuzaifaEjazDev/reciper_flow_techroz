import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:recipe_app/views/screens/recipe_details_screen.dart';

class BookmarkedRecipesScreen extends StatefulWidget {
  const BookmarkedRecipesScreen({super.key});

  @override
  State<BookmarkedRecipesScreen> createState() => _BookmarkedRecipesScreenState();
}

class _BookmarkedRecipesScreenState extends State<BookmarkedRecipesScreen> {
  late _BookmarksPager _pager;

  @override
  void initState() {
    super.initState();
    _pager = _BookmarksPager(FirestoreRecipesService())..loadInitial();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_BookmarksPager>.value(
      value: _pager,
      child: const _BookmarkedRecipesView(),
    );
  }
}

class _BookmarkedRecipesView extends StatefulWidget {
  const _BookmarkedRecipesView();

  @override
  State<_BookmarkedRecipesView> createState() => _BookmarkedRecipesViewState();
}

class _BookmarkedRecipesViewState extends State<_BookmarkedRecipesView> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<_BookmarksPager>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bookmarked Recipes', style: TextStyle(fontWeight: FontWeight.w600,),),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
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
                          Expanded(
                            child: TextField(
                              controller: vm.searchController,
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
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F00),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Icon(Icons.search, color: Colors.white, size: 20),
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
                        Skeletonizer(
                          enabled: true,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.70,
                            ),
                            itemBuilder: (context, index) => const _BookmarkCardSkeleton(),
                          ),
                        ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.items.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.70,
                        ),
                        itemBuilder: (context, index) {
                          final r = vm.items[index];
                          return _BookmarkCard(
                            title: r['title']?.toString() ?? '', 
                            imageUrl: r['imageUrl']?.toString() ?? '', 
                            minutes: (r['minutes'] is int) ? r['minutes'] as int : 0,
                            recipeId: r['id']?.toString() ?? '',
                          );
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

/// Bookmark card container for bookmarks
class _BookmarkCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final int minutes;
  final String recipeId;
  const _BookmarkCard({required this.title, required this.imageUrl, required this.minutes, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(
              title: title,
              imageAssetPath: imageUrl,
              minutes: minutes,
              recipeId: recipeId,
              fromAdminScreen: false,
              fromBookmarksScreen: true,
            ),
          ),
        );
      },
      child: Container(
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
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Image.asset('assets/images/dish/dish1.jpg', fit: BoxFit.cover),
                    )
                  : Image.asset(imageUrl.isEmpty ? 'assets/images/dish/dish1.jpg' : imageUrl, fit: BoxFit.cover),
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
      ),
    );
  }
}

class _BookmarkCardSkeleton extends StatelessWidget {
  const _BookmarkCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 120, child: Container(color: Colors.white)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16, width: 140, child: ColoredBox(color: Colors.white)),
                SizedBox(height: 8),
                SizedBox(height: 12, width: 90, child: ColoredBox(color: Colors.white)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _BookmarksPager extends ChangeNotifier {
  _BookmarksPager(this._service) {
    _setupRealTimeListener();
  }
  
  final FirestoreRecipesService _service;
  final TextEditingController searchController = TextEditingController();
  final List<Map<String, dynamic>> _allItems = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  bool loading = false;
  String? error;
  String? _lastId;
  int _currentPage = 1;
  final int _pageSize = 10;
  final Map<int, String?> _pageToCursor = <int, String?>{1: null};
  final Map<int, String?> _pageToTitleCursor = <int, String?>{1: null};
  int _totalCount = 0;
  String _activeQuery = '';
  String _queryTemp = '';
  bool _usingClientSideFiltering = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookmarksListener;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    searchController.dispose();
    _bookmarksListener?.cancel();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> loadInitial() async {
    if (_disposed) return;
    _allItems.clear();
    _items.clear();
    _lastId = null;
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    _pageToTitleCursor
      ..clear()
      ..addAll({1: null});
    _usingClientSideFiltering = false;
    await _loadTotalCount();
    await _loadPageAtCursor(startAfterId: null);
    
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_disposed) return;
    if (searchController.text.trim().isEmpty) {
      _activeQuery = '';
      _queryTemp = '';
      loadInitial();
    }
  }

  Future<void> _loadPageAtCursor({required String? startAfterId}) async {
    if (_disposed || loading) return;
    loading = true;
    error = null;
    _safeNotifyListeners();
    try {
      if (_activeQuery.isNotEmpty && !_usingClientSideFiltering) {
        final page = await _service.fetchBookmarksPageByTitlePrefix(
          limit: _pageSize,
          startAfterTitle: startAfterId,
          prefix: _activeQuery,
        );
        _allItems
          ..clear()
          ..addAll(page.items);
        _items
          ..clear()
          ..addAll(page.items);
        final String? lastTitle = page.lastTitle;
        _pageToTitleCursor[_currentPage + 1] = lastTitle;
      } else if (_activeQuery.isNotEmpty && _usingClientSideFiltering) {
        _applyFilter();
      } else {
        final page = await _service.fetchBookmarksPage(limit: _pageSize, startAfterId: startAfterId);
        _allItems
          ..clear()
          ..addAll(page.items);
        _items
          ..clear()
          ..addAll(page.items);
        _lastId = page.lastId;
        _pageToCursor[_currentPage + 1] = _lastId;
      }
    } catch (e) {
      if (!_disposed) {
        error = e.toString();
      }
    } finally {
      loading = false;
      _safeNotifyListeners();
    }
  }

  void _setupRealTimeListener() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _disposed) return;

    final CollectionReference<Map<String, dynamic>> bookmarksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('BookMarkedRecipes');

    _bookmarksListener = bookmarksRef.snapshots().listen(
      (snapshot) {
        if (_disposed) return;
        for (final change in snapshot.docChanges) {
          switch (change.type) {
            case DocumentChangeType.removed:
              _items.removeWhere((item) => item['id'] == change.doc.id);
              _allItems.removeWhere((item) => item['id'] == change.doc.id);
              _totalCount = _totalCount > 0 ? _totalCount - 1 : 0;
              if (_activeQuery.isNotEmpty && _usingClientSideFiltering) {
                _applyFilter();
              } else {
                final String? cursorForCurrentPage = _activeQuery.isNotEmpty && !_usingClientSideFiltering
                    ? _pageToTitleCursor[_currentPage]
                    : _pageToCursor[_currentPage];
                _loadPageAtCursor(startAfterId: cursorForCurrentPage);
              }
              break;
            case DocumentChangeType.added:
              _totalCount = _totalCount + 1;
              if (_activeQuery.isNotEmpty && _usingClientSideFiltering) {
                _loadAllBookmarksForFiltering().then((_) {
                  if (!_disposed) {
                    _applyFilter();
                  }
                });
              } else {
                final String? cursorForCurrentPage = _activeQuery.isNotEmpty && !_usingClientSideFiltering
                    ? _pageToTitleCursor[_currentPage]
                    : _pageToCursor[_currentPage];
                _loadPageAtCursor(startAfterId: cursorForCurrentPage);
              }
              break;
            case DocumentChangeType.modified:
              final int idx = _items.indexWhere((item) => item['id'] == change.doc.id);
              final Map<String, dynamic>? data = change.doc.data();
              if (idx != -1 && data != null) {
                _items[idx] = {...data, 'id': change.doc.id};
                _safeNotifyListeners();
              }
              break;
          }
        }
      },
      onError: (_) {
        if (_disposed) return;
      },
    );
  }

  Future<void> goToPage(int pageNumber) async {
    if (_disposed || pageNumber < 1) return;
    int anchor = pageNumber;
    if (_activeQuery.isNotEmpty && !_usingClientSideFiltering) {
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
    } else if (_activeQuery.isNotEmpty && _usingClientSideFiltering) {
      _currentPage = pageNumber;
      _applyFilter();
      return;
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
    await _loadPageAtCursor(
      startAfterId: _activeQuery.isNotEmpty && !_usingClientSideFiltering
        ? _pageToTitleCursor[_currentPage - 1] 
        : _pageToCursor[_currentPage - 1]
    );
  }

  int get currentPage => _currentPage;
  int get totalPages {
    if (_totalCount == 0) return 0;
    return ((_totalCount - 1) ~/ _pageSize) + 1;
  }
  int get totalCount => _totalCount;

  Future<void> _loadTotalCount() async {
    if (_disposed) return;
    try {
      if (_activeQuery.isNotEmpty && !_usingClientSideFiltering) {
        _totalCount = await _service.fetchBookmarksCountByTitlePrefix(_activeQuery);
      } else if (_activeQuery.isNotEmpty && _usingClientSideFiltering) {
        final List<Map<String, dynamic>> filtered = _allItems.where(
          (item) => (item['title'] as String?)?.toLowerCase().contains(_activeQuery.toLowerCase()) ?? false
        ).toList();
        _totalCount = filtered.length;
      } else {
        _totalCount = await _service.fetchBookmarksCount();
      }
    } catch (_) {
      _totalCount = ((_pageToCursor.length - 1) * _pageSize) + _items.length;
    }
    _safeNotifyListeners();
  }

  void setQueryTemp(String v) {
    if (_disposed) return;
    _queryTemp = v;
  }

  Future<void> applySearch() async {
    if (_disposed) return;
    final String t = _queryTemp.trim().toLowerCase();
    if (t.isEmpty) {
      _activeQuery = '';
      await loadInitial();
      return;
    }
    _activeQuery = t;
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null});
    _pageToTitleCursor
      ..clear()
      ..addAll({1: null});
    
    if (_activeQuery.isNotEmpty) {
      _usingClientSideFiltering = true;
      await _loadAllBookmarksForFiltering();
      await _loadTotalCount();
      _applyFilter();
    } else {
      _usingClientSideFiltering = false;
      await _loadTotalCount();
      await _loadPageAtCursor(startAfterId: null);
    }
  }

  Future<void> _loadAllBookmarksForFiltering() async {
    if (_disposed || loading) return;
    loading = true;
    error = null;
    _safeNotifyListeners();
    try {
      final List<Map<String, dynamic>> allBookmarks = [];
      String? lastId;
      bool hasMore = true;
      
      while (hasMore) {
        final page = await _service.fetchBookmarksPage(limit: 50, startAfterId: lastId);
        allBookmarks.addAll(page.items);
        lastId = page.lastId;
        hasMore = lastId != null;
      }
      
      _allItems
        ..clear()
        ..addAll(allBookmarks);
    } catch (e) {
      if (!_disposed) {
        error = e.toString();
      }
    } finally {
      loading = false;
      _safeNotifyListeners();
    }
  }

  void _applyFilter() {
    if (_disposed || !_usingClientSideFiltering) return;
    
    final String query = _activeQuery.toLowerCase();
    final List<Map<String, dynamic>> filtered = _allItems.where(
      (item) => (item['title'] as String?)?.toLowerCase().contains(query) ?? false
    ).toList();
    
    final int start = (_currentPage - 1) * _pageSize;
    final int end = start + _pageSize > filtered.length ? filtered.length : start + _pageSize;
    
    final List<Map<String, dynamic>> paginated = start < filtered.length 
        ? filtered.sublist(start, end) 
        : <Map<String, dynamic>>[];
    
    _items
      ..clear()
      ..addAll(paginated);
    
    _totalCount = filtered.length;
    _safeNotifyListeners();
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
        // Center the pagination buttons
        Center(
          child: SizedBox(
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
