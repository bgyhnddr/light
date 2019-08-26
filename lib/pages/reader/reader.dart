import 'dart:async';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlay;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show required;
import 'package:intl/intl.dart';
import '../../services/system.dart';
import '../../models/book.dart';
import '../../utils/light_engine.dart';
import '../../widgets/text_indicator.dart';
import '../../models/style.dart';

class Reader extends StatefulWidget {
  Reader({@required this.book});

  /// the book be read
  final Book book;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  _ReaderState createState() => new _ReaderState();
}

class _ReaderState extends State<Reader> with WidgetsBindingObserver {
  int pageNum;
  PersistentBottomSheetController bottomSheet;
  int currentPage = 0;
  String _timeString;
  Timer _timer;
  StreamController<dynamic> pageControllerStream =
      StreamController<dynamic>.broadcast();

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
    pageController.jumpToPage(currentPage + 1);
    print('change:' + value.toString());
  }

  /// tu show menu
  handleShowMenu(BuildContext context) {
    bottomSheet =
        widget.scaffoldKey.currentState.showBottomSheet((BuildContext context) {
      return Container(
          height: 150,
          child: Column(children: <Widget>[
            Expanded(
                child: SliderTheme(
                    data: SliderTheme.of(widget.scaffoldKey.currentContext)
                        .copyWith(
                            activeTrackColor: Colors.deepOrangeAccent,
                            activeTickMarkColor: Colors.white,
                            inactiveTickMarkColor: Colors.white,
                            inactiveTrackColor: Colors.black,
                            valueIndicatorColor: Colors.blue,
                            thumbColor: Colors.green,
                            overlayColor: Colors.amber),
                    child: Slider(
                        label: '$currentPage',
                        value: currentPage.toDouble(),
                        min: 1,
                        max: lightEngine.childCount.toDouble(),
                        divisions: lightEngine.childCount - 1,
                        onChanged: (progress) {
                          bottomSheet.setState(() {
                            currentPage = progress.round();
                          });
                        },
                        onChangeEnd: (progress) {
                          pageController.jumpToPage(progress.round());
                        }))),
            Expanded(
                child: Center(
              child: MaterialButton(
                color: Colors.blue,
                textColor: Colors.white,
                child: Text('跳转'),
                onPressed: () {
                  bottomSheet.close();
                  isShowMenu = false;
                  showJumpDialog(context);
                },
              ),
            ))
          ]));
    });
    bottomSheet.closed.then((val) {
      isShowMenu = false;
    });
  }

  /// detect tap event
  void handleTapUp(TapUpDetails tapUpDetails, BuildContext context) {
    if (!isShowMenu) {
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
          handleShowMenu(context);
          isShowMenu = true;
        }
      }
    } else {
      bottomSheet.close();
      isShowMenu = false;
    }
  }

  ThemeData get theme {
    return Theme.of(context);
  }

  TextStyle get waitingTextStyle {
    return theme.textTheme.body2.copyWith(color: Colors.white70);
  }

  Widget pageBuilder(BuildContext context, int index) {
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
                Text(_timeString),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
                onTapUp: (TapUpDetails tapUpDetails) {
                  handleTapUp(tapUpDetails, context);
                },
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

  void setTimer() {
    _timeString = DateFormat.Hm().format(DateTime.now());
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      String formattedDateTime = DateFormat.Hm().format(DateTime.now());
      setState(() {
        _timeString = formattedDateTime;
      });
    });
  }

  TextEditingController _textFieldController = TextEditingController();

  showJumpDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('跳转'),
            content: TextField(
              keyboardType: TextInputType.numberWithOptions(),
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "页数"),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('确认'),
                onPressed: () {
                  print('确认');
                  int number = int.tryParse(_textFieldController.text);
                  if (number != null) {
                    if (number > 0 && number <= lightEngine.childCount) {
                      currentPage = number - 1;
                      pageController.jumpToPage(number - 1);
                      pageController = PageController(initialPage: currentPage);
                      _textFieldController.text = '';
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              new FlatButton(
                child: new Text('取消'),
                onPressed: () {
                  print('取消');
                  _textFieldController.text = '';
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setTimer();
      pageController = PageController(initialPage: currentPage);
    }

    if (state == AppLifecycleState.paused) {
      isShowMenu = false;
      if (bottomSheet != null) {
        bottomSheet.close();
      }
      _timer.cancel();
    }
  }

  @override
  void initState() {
    setTimer();
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    // SystemChrome.setEnabledSystemUIOverlays([]);
    lightEngine = LightEngine(book: widget.book, stateSetter: setState);
    lightEngine.init().then((controller) {
      lightEngine.buildPage(pageControllerStream);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
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
                if (snapshot.data == 'end' ||
                    snapshot.connectionState == ConnectionState.done) {
                  pageControllerStream.close();
                  currentPage = lightEngine.loadPage();
                  if (pageController == null) {
                    pageController = PageController(initialPage: currentPage);
                  }
                  return PageView.builder(
                      onPageChanged: (page) {
                        print("change!!!!!!!!!!!!!!!!!!!!!!!!!!");
                        currentPage = page;
                        lightEngine.savePage(page);
                      },
                      itemCount: lightEngine.childCount,
                      controller: pageController,
                      itemBuilder: pageBuilder);
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
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }
}
