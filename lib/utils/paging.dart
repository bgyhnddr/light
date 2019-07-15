import 'package:flutter/material.dart';
import '../models/style.dart';

class Paging {
  Paging({
    Size size,
    int maxLines,
  })  : _size = size,
        _textPainter = new TextPainter() {
    _textStyle = Style.textStyle;
    _textAlign = Style.textAlign;
    _textDirection = Style.textDirection;
    _textPainter.textAlign = _textAlign;
    _textPainter.textDirection = _textDirection;
  }

//  BookService bookService = new BookService();

  /// view size
  Size _size;

  TextStyle _textStyle;

  TextAlign _textAlign;

  TextDirection _textDirection;

  TextPainter _textPainter;

  set size(Size size) {
    _size = size;
  }

  set textStyle(TextStyle textStyle) {
    _textStyle = textStyle;
  }

  set textAlign(TextAlign textAlign) {
    _textAlign = textAlign;
    _textPainter.textAlign = _textAlign;
  }

  set textDirection(TextDirection textDirection) {
    _textDirection = textDirection;
    _textPainter.textDirection = _textDirection;
  }

  int getLength(content) {
    _textPainter.maxLines = 30;
    _textPainter
      ..text = new TextSpan(text: content, style: _textStyle)
      ..layout(maxWidth: _size.width);
    return _textPainter
        .getPositionForOffset(Offset(_size.width, _size.height))
        .offset;
  }
}
