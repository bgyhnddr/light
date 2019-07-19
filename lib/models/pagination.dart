import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show required;
import 'package:flutter/material.dart';

//import '../services/system.dart';
import '../services/book.dart';
import '../models/book.dart';
import '../models/style.dart';
import '../models/section.dart';
import '../utils/book_decoder.dart';
import '../utils/constants.dart';
import '../utils/paging.dart';

/// Get paging data by pagingHashCode.
/// If dose not exist, calculates paging data with [Book] and [BookDecoder].
///
/// [Style] must have been initialized already,
/// which will be used to calculate paging data.
/// If there's not data for current pagingHashCode, use temporary data,
/// At the same, start calculating paging data.
/// When finish calculating, replace the temporary with the correct data.
class Pagination {
  Pagination(
      {@required Book book,
      @required BookDecoder bookDecoder,
      @required Size size})
      : assert(null != book),
        assert(null != bookDecoder),
        assert(null != Style.values),
        assert(null != size),
        _book = book,
        _bookDecoder = bookDecoder,
        paging = new Paging(size: size);

  final Book _book;
  final BookDecoder _bookDecoder;

  final BookService bookService = new BookService();
  Paging paging;

  bool isTemporary;

  List<int> pageData;

  int offset = 0;
  bool loaded = false;

  /// Initialize paging data.
  void init(StreamController streamController) {
    pageData = bookService.getPagingData(_book);
    if (pageData != null) {
      streamController.add('end');
    } else {
      pageData = List<int>();
      pageData.add(0);
      streamController.add('begin');
    }
  }

  void getPageData(StreamController streamController) {
    var content = _bookDecoder.content;

    for (var i = 0; i < 200; i++) {
      if (offset < content.length) {
        offset += paging.getLength(
            content.substring(offset, min(offset + 400, content.length)));
        pageData.add(offset);
      } else {
        bookService.setPagingData(_book, pageData);
        streamController.sink.add('end');
        return;
      }
    }
    bookService.setPagingData(_book, pageData);
    streamController.sink.add('${offset.toString()}/${content.length}');
  }

  List<int> pagingData(int index) {
    if (index < pageData.length - 1) {
      return [pageData[index], pageData[index + 1]];
    }
    return null;
  }

  Section section;

  operator [](int index) {
    return pagingData(index);
  }
}
