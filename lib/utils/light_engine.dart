import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show required;
import 'book_decoder.dart';
import '../services/system.dart';
import '../services/book.dart';
import '../models/book.dart';
import '../models/pagination.dart';
import '../models/style.dart';
import '../models/section.dart';
import '../utils/paging.dart';

class LightEngine {
  static Map<Book, LightEngine> _cache;

  /// used to reset state
  final ValueChanged<VoidCallback> _stateSetter;

  factory LightEngine(
      {@required Book book, @required ValueChanged<VoidCallback> stateSetter}) {
//    if (null == _cache) {
    _cache = <Book, LightEngine>{};
//    }
    if (!_cache.containsKey(book)) {
      _cache[book] =
          new LightEngine._internal(book: book, stateSetter: stateSetter);
    }
    return _cache[book];
  }

  final Book _book;

  final SystemService _service = new SystemService();
  final BookService bookService = new BookService();

  StreamSubscription _streamSubscription;

  bool inited = false;

  LightEngine._internal({Book book, ValueChanged<VoidCallback> stateSetter})
      : assert(null != book),
        assert(null != stateSetter),
        _book = book,
        _stateSetter = stateSetter {
    _streamSubscription = _service.listen(_listener);
  }

  void _listener(var event) {
    if (null != event && event is List && event.isNotEmpty) {
      switch (event[0]) {
        case '':
          break;
      }
    }
  }

  PageController _pageController;

  BookDecoder _decoder;

  Future init() async {
    print('get controller');
    try {
      if (null == _pageController) {
        if (null == _decoder) {
          _decoder = await BookDecoder.decode(_book);
        }
        if (null == Style.values) {
          await Style.init();
        }
      }
    } catch (e) {
      print('get controller failed. error: $e');
      throw e;
    }
  }

  void buildPage(pageControllerStream) async {
    if (null == _pagination) {
      _pagination =
          new Pagination(book: _book, bookDecoder: _decoder, size: _pageSize);
      _pagination.init(pageControllerStream);
    }
  }

  void nextPage(pageControllerStream) {
    _pagination.getPageData(pageControllerStream);
  }

  int get childCount {
    if (_pagination.pageData != null) {
      return _pagination.pageData.length - 1;
    } else {
      return 0;
    }
  }

  List<Style> get styles => Style.values;

  Style get style {
    return Style.values[Style.currentId];
  }

  String get title {
    return 'title...';
  }

  Pagination _pagination;

  Section section;

  String getContent(int index) {
    try {
      print('get content index=$index');
      var page = _pagination[index];
      section = _decoder.getSection(page[0], page[1] - page[0]);
      if (null == section) {
        return 'get section error.';
      }
      return section.content;
    } catch (e) {
      print('get content error: $e');
      return e.toString();
    }
  }

  void savePage(int index) {
    bookService.setOffset(_book, index);
  }

  int loadPage() {
    return bookService.getOffset(_book);
  }

  Size _pageSize;
  double get fontSize => Style.fontSize;

  double get lineHeight => Style.height;

  TextDirection get textDirection => Style.textDirection;

  /// When set a new Size, check the pagingHashCode,
  /// recalculate pagination if need.
  set pageSize(Size size) {
    assert(null != size);
    print('set page size: $size');
    if (null != _pageSize || size == _pageSize) {
      return;
    }
    _pageSize = size;
  }

  Size get pageSize {
    return _pageSize;
  }

  int get estimateMaxLines {
    return _pageSize.height ~/ (fontSize * lineHeight);
  }

  void close() {
    _streamSubscription?.cancel();
    _cache[_book] = null;
  }
}
