import 'dart:async';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlay;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show required;
import '../../services/system.dart';
import '../../models/book.dart';
import '../../utils/light_engine.dart';
import '../../widgets/text_indicator.dart';
import '../../models/style.dart';

class Reader extends StatefulWidget {
  Reader({@required this.book});

  /// the book be read
  final Book book;

  _ReaderState createState() => new _ReaderState();
}

class _ReaderState extends State<Reader> {
  StreamController<dynamic> pageControllerStream = StreamController<dynamic>();

  SystemService service = new SystemService();
  LightEngine lightEngine;

  /// the ratio to slice the screen
  Map<String, List<int>> tapRatio = <String, List<int>>{
    'x': [1, 1, 1],
    'y': [1, 1, 1]
  };

  /// the area tapped
  Map<String, double> tapGrid = <String, double>{};

  /// the size of screen

  bool isShowMenu = false;

  ///
  PageController pageController;

  Future<PageController> pageControllerFuture;

  SliverChildBuilderDelegate childBuilderDelegate;

  /// to change the page
  void handlePageChanged(bool value) {
    print('change:' + value.toString());
  }

  /// tu show menu
  Future<Null> handleShowMenu() async {
    return;
  }

  /// detect tap event
  void handleTapUp(TapUpDetails tapUpDetails) {
    double x = tapUpDetails.globalPosition.dx;
    double y = tapUpDetails.globalPosition.dy;
    Size mediaSize = lightEngine.pageSize;
    if (tapGrid.isEmpty) {
      double x1 = mediaSize.width *
          (tapRatio['x'][0] /
              (tapRatio['x'][0] + tapRatio['x'][1] + tapRatio['x'][2]));
      double x2 = mediaSize.width *
          ((tapRatio['x'][0] + tapRatio['x'][1]) /
              (tapRatio['x'][0] + tapRatio['x'][1] + tapRatio['x'][2]));
      double y1 = mediaSize.height *
          (tapRatio['y'][0] /
              (tapRatio['y'][0] + tapRatio['y'][1] + tapRatio['y'][2]));
      double y2 = mediaSize.height *
          ((tapRatio['y'][0] + tapRatio['y'][1]) /
              (tapRatio['y'][0] + tapRatio['y'][1] + tapRatio['y'][2]));
      tapGrid['x1'] = x1;
      tapGrid['x2'] = x2;
      tapGrid['y1'] = y1;
      tapGrid['y2'] = y2;
    }
    if (x <= tapGrid['x1']) {
      // previous page
      handlePageChanged(false);
    } else if (x >= tapGrid['x2']) {
      // next page
      handlePageChanged(true);
    } else {
      if (y <= tapGrid['y1']) {
        // previous page
        handlePageChanged(false);
      } else if (y >= tapGrid['y2']) {
        // next page
        handlePageChanged(true);
      } else {
        // open the menu
        isShowMenu = true;
        handleShowMenu().then((value) {
            print('showmenu:' + value.toString());
          if (true == value) {
          }
        });
      }
    }
  }

  ThemeData get theme {
    return Theme.of(context);
  }

  TextStyle get waitingTextStyle {
    return theme.textTheme.body2.copyWith(color: Colors.white70);
  }

  Widget pageBuilder(BuildContext contxt, int index) {
    return Container(
      decoration: BoxDecoration(
          color: lightEngine.style.backgroundColor,
          image: lightEngine.style.image),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 30.0,
            child: Row(
              children: <Widget>[
                Text(lightEngine.title),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
                onTapUp: handleTapUp,
                child: Container(
                  color: Colors.white,
                  child: Text(
                    lightEngine.getContent(index),
                    style: Style.textStyle,
                    overflow: TextOverflow.clip,
                    textScaleFactor: 1.0,
                  ),
                )),
          ),
          SizedBox(
            height: 30.0,
            child: Row(
              children: <Widget>[
                Text('${(index + 1).toString()}/${lightEngine.childCount}'),
              ],
            ),
          )
        ],
      ),
    );
  }

  bool dataLoad = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    lightEngine = LightEngine(book: widget.book, stateSetter: setState);
    lightEngine.init().then((controller) {
      lightEngine.buildPage(pageControllerStream);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraint) {
          lightEngine.pageSize =
              Size(constraint.maxWidth - 40.0, constraint.maxHeight - 100.0);

          Widget child;
          child = StreamBuilder(
              stream: pageControllerStream.stream,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                print(snapshot.connectionState);
                print(snapshot.data);
                if (snapshot.data == 'end') {
                  dataLoad = true;
                  if (pageController == null) {
                    pageController =
                        PageController(initialPage: lightEngine.loadPage());
                  }
                  return PageView.custom(
                      onPageChanged: (page) {
                        lightEngine.savePage(page);
                      },
                      controller: pageController,
                      childrenDelegate: new SliverChildBuilderDelegate(
                          pageBuilder,
                          childCount: lightEngine.childCount,
                          addRepaintBoundaries: false,
                          addAutomaticKeepAlives: false));
                } else if (snapshot.data is String) {
                  lightEngine.nextPage(pageControllerStream);
                  return new Center(
                    child: Text(snapshot.data.toString()),
                  );
                } else {
                  return Center(
                    child: TextIndicator(),
                  );
                }
              });
          return Container(color: Colors.black45, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    lightEngine.close();
    pageControllerStream.close();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }
}
