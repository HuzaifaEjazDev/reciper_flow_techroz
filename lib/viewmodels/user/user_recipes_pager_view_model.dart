import 'package:flutter/material.dart';
import 'package:recipe_app/services/firestore_recipes_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRecipeCardData {
  final String id;
  final String title;
  final String imageAssetPath;
  final int ingredientsCount;
  final int stepsCount;
  
  UserRecipeCardData({
    required this.id,
    required this.title,
    required this.imageAssetPath,
    required this.ingredientsCount,
    required this.stepsCount,
  });
}

class UserRecipesPagerViewModel extends ChangeNotifier {
  UserRecipesPagerViewModel(this._service);
  final FirestoreRecipesService _service;
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

  Future<void> loadInitial() async {
    print('Loading initial page');
    _items.clear();
    _lastId = null;
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null}); // Page 1 starts with null cursor
    _pageToTitleCursor
      ..clear()
      ..addAll({1: null}); // Page 1 starts with null cursor
    await _loadTotalCount();
    print('Page cursors after init: $_pageToCursor');
    // Pass null for startAfterId to load the first page
    await _loadPageAtCursor(startAfterId: null);
  }

  Future<void> _loadPageAtCursor({required String? startAfterId}) async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      print('Loading page $_currentPage with startAfterId: $startAfterId');
      if (_activeQuery.isNotEmpty) {
        final page = await _service.fetchUserRecipesPageByTitlePrefix(
          limit: _pageSize,
          startAfterTitle: startAfterId, // Use startAfterId directly for title-based pagination
          prefix: _activeQuery,
        );
        print('Loaded ${page.items.length} items for search query: $_activeQuery');
        _items
          ..clear()
          ..addAll(page.items);
        final String? lastTitle = page.lastTitle;
        print('Last title: $lastTitle');
        // Store the cursor for the next page (currentPage + 1)
        _pageToTitleCursor[_currentPage + 1] = lastTitle;
      } else {
        final page = await _service.fetchUserRecipesPage(limit: _pageSize, startAfterId: startAfterId);
        print('Loaded ${page.items.length} items, lastId: ${page.lastId}');
        _items
          ..clear()
          ..addAll(page.items);
        _lastId = page.lastId;
        print('Stored cursor for page ${_currentPage + 1}: $_lastId');
        // Store the cursor for the next page (currentPage + 1)
        _pageToCursor[_currentPage + 1] = _lastId;
      }
    } catch (e) {
      error = e.toString();
      print('Error loading page: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1) return;
    print('Going to page $pageNumber, current page: $_currentPage');
    print('Page cursors: $_pageToCursor');
    print('Title cursors: $_pageToTitleCursor');
    int anchor = pageNumber;
    if (_activeQuery.isNotEmpty) {
      while (anchor > 1 && !_pageToTitleCursor.containsKey(anchor)) {
        anchor--;
      }
      print('Anchor for search: $anchor');
      for (int p = anchor; p < pageNumber; p++) {
        final String? cursor = _pageToTitleCursor[p];
        print('Fetching page ${p + 1} with cursor: $cursor');
        final next = await _service.fetchUserRecipesPageByTitlePrefix(
          limit: _pageSize,
          startAfterTitle: cursor,
          prefix: _activeQuery,
        );
        _pageToTitleCursor[p + 1] = next.lastTitle;
        print('Stored title cursor for page ${p + 1}: ${next.lastTitle}');
        if (next.lastTitle == null) break;
      }
    } else {
      while (anchor > 1 && !_pageToCursor.containsKey(anchor)) {
        anchor--;
      }
      print('Anchor for normal: $anchor');
      for (int p = anchor; p < pageNumber; p++) {
        final String? cursor = _pageToCursor[p];
        print('Fetching page ${p + 1} with cursor: $cursor');
        final next = await _service.fetchUserRecipesPage(limit: _pageSize, startAfterId: cursor);
        _pageToCursor[p + 1] = next.lastId;
        print('Stored cursor for page ${p + 1}: ${next.lastId}');
        if (next.lastId == null) break;
      }
    }
    _currentPage = pageNumber;
    print('Set current page to: $_currentPage');
    // Use the correct cursor based on whether we're searching or not
    // For page N, we need the cursor from page N-1 (or null for page 1)
    final String? startAfterId = _activeQuery.isNotEmpty 
        ? _pageToTitleCursor[_currentPage] 
        : _pageToCursor[_currentPage];
    print('Loading page $_currentPage with startAfterId: $startAfterId');
    await _loadPageAtCursor(
      startAfterId: startAfterId
    );
  }

  int get currentPage => _currentPage;
  int get totalPages => (_totalCount == 0) ? 0 : ((_totalCount + _pageSize - 1) ~/ _pageSize);
  int get totalCount => _totalCount;

  Future<void> _loadTotalCount() async {
    try {
      _totalCount = _activeQuery.isNotEmpty
          ? await _service.fetchUserRecipesCountByTitlePrefix(_activeQuery)
          : await _service.fetchUserRecipesCount();
      print('Total count: $_totalCount');
    } catch (e) {
      print('Error loading total count: $e');
      _totalCount = ((_pageToCursor.length - 1) * _pageSize) + _items.length;
    }
    notifyListeners();
  }

  void setQueryTemp(String v) {
    _queryTemp = v;
  }

  Future<void> applySearch() async {
    final String t = _queryTemp.trim().toLowerCase();
    _activeQuery = t;
    _currentPage = 1;
    _pageToCursor
      ..clear()
      ..addAll({1: null}); // Page 1 starts with null cursor
    _pageToTitleCursor
      ..clear()
      ..addAll({1: null}); // Page 1 starts with null cursor
    await _loadTotalCount();
    // Pass null for startAfterId to load the first page of search results
    await _loadPageAtCursor(startAfterId: null);
  }
}