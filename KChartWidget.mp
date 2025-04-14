import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_chart/flutter_k_chart.dart';

import 'chart_style.dart';
import 'entity/info_window_entity.dart';
import 'entity/k_line_entity.dart';
import 'renderer/chart_painter.dart';
import 'utils/date_format_util.dart';

enum MainState { MA, BOLL, EMA, SAR, NONE }
enum SecondaryState { MACD, KDJ, RSI, WR, CCI, NONE }

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

class KChartWidget extends StatefulWidget {
  List<KLineEntity> datas;
  List<MainState> mainStateList;
  List<SecondaryState> secondaryStateList;
  bool volHidden;
  Function()? onSecondaryTap;
  bool? isLine;
  bool isChinese;
  List<String> timeFormat;
  //当屏幕滚动到尽头会调用，真为拉到屏幕右侧尽头，假为拉到屏幕左侧尽头
  Function(bool)? onLoadMore;
  List<Color>? bgColor;
  int? fixedLength;
  List<int> maDayList;
  int flingTime;
  double flingRatio;
  Curve flingCurve;
  Function(bool)? isOnDrag;
  ChartColors chartColors;
  ChartStyle chartStyle;
  bool isDark = false;
  bool isSmall;
  String? lineType = "";
  Function(bool)? scaleFunc;
  Function(bool)? multiDownFunc;
  Function(bool)? touchFunc;
  int upDownType = 0;//0--红涨绿跌  1--绿涨红跌

  KChartWidget(
    this.datas,
    this.chartStyle,
    this.chartColors,
    this.isDark,
    this.upDownType,{
    this.mainStateList = const [MainState.MA],
    this.secondaryStateList = const [SecondaryState.MACD],
    this.onSecondaryTap,
    this.volHidden = false,
    this.isLine,
    this.isChinese = true,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.bgColor,
    this.fixedLength,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.scaleFunc,
    this.multiDownFunc,
    this.touchFunc,
    this.lineType,
    this.isSmall = false,
  }) : assert(maDayList != null);

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  double mScaleX = 1.5, mScrollX = 0.0, mSelectX = 0.0, mSelectY = 0.0;
  StreamController<InfoWindowEntity?>? mInfoWindowStream;
  double mWidth = 0;
  double widgetHeight = 0;
  AnimationController? _controller;
  Animation<double>? aniX;
  AnimationController? _openController;
  Animation<int>? _openAnim;
  List<int> downIndexList = [];//多手指点击位置列表
  int _theStopIndex = 0;
  int _theStartIndex = 0;
  double mDataLen = 0;
  double mTranslateX = 0;
  bool _hasOpenAnim = false;
  bool _openAnimEnd = false;
  String lineType = "";

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false;

  //logo
  ui.Image? logoImage;
  //加载资源
  loadAssets() async{
    ByteData byteData = await rootBundle.load(widget.isDark?"assets/images_black/icon_klickl_watermark.png":"assets/images_white/icon_klickl_watermark.png");
    List<int> dataList = byteData.buffer.asUint8List(byteData.offsetInBytes,byteData.lengthInBytes);
    ui.decodeImageFromList(Uint8List.fromList(dataList), (result) {
      logoImage = result;
    });
  }

  @override
  void initState() {
    super.initState();
    loadAssets();
    mInfoWindowStream = StreamController<InfoWindowEntity>();

    //开启的K线动画
    _openController = AnimationController(vsync: this,duration: Duration(milliseconds: 500))
      ..addStatusListener((status) {
        if(status==AnimationStatus.completed/*||status==AnimationStatus.dismissed*/){
          setState(() {
            _openAnimEnd = true;
          });
        }else _openAnimEnd = false;
      })
      ..addListener(() {
        setState(() {
          _theStopIndex = _openAnim!.value;
        });
      });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widgetHeight = context.size!.height;
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mWidth = MediaQuery.of(context).size.width;
  }

  @override
  void dispose() {
    _openController?.dispose();
    mInfoWindowStream?.close();
    _controller?.dispose();
    super.dispose();
  }

  bool isMultiEvent = false;
  bool pressedUp = true;
  bool isLongPressed = false;//是否长按
  bool moveStart = false;//滑动开始
  bool firstMoveStart = true;//首次滑动开始
  bool isScaling = false;//正在缩放
  bool isScrolling = false;//正在滑动
  bool prepareLongPress = false;//准备长按
  bool panUpDown = false;//上下平移
  num pointerNum = 0;//屏幕的手指数量
  Offset? firstDownOffset;
  Map<int,PointerDownEvent> pointerEventMap = {};
  Map<int,Offset> pointerMoveEventMap = {};
  Map<int,PointerMoveEvent> lastMoveMap = {};
  Map<int,num> pointerMoveDistanceMap = {};
  Map<int,List<int>> pointerDirectionMap = {};
  int longPressPointer = -1;//正在长按的点
  int scaleOrientation = -1;//缩放方向
  int flyStartTimeStamp = 0;


  double getX(int position) => position * widget.chartStyle.pointWidth + widget.chartStyle.pointWidth / 2;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, widget.datas.length - 1);

  double xToTranslateX(double x) => -mTranslateX + x / 1.0;

  ///二分查找当前值的index
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  ///获取平移的最小值
  double getMinTranslateX() {
    //多加一些距离不然 缩放到最小加载动画前面一截会空
    var x = -mDataLen + mWidth / 1.0 - widget.chartStyle.pointWidth / 2 + 230/mScaleX;
    return x >= 0 ? 0.0 : x;
  }


  ///scrollX 转换为 TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  int stopIndex = 0;

  /// 开始动画
  /// @return void
  void startAnim(){
    //计算动画初始与结束值,并开启动画
    // print("K线的内容：${widget.datas.length}");
    if(lineType!=widget.lineType){
      _hasOpenAnim = false;
      _openAnimEnd = false;
      mScrollX = mSelectX = mSelectY =  0.0;
      isLongPress = false;
    }
    //判断是否有数据并是否加载过动画
    if(widget.datas.length>=1&&!_hasOpenAnim){
      _hasOpenAnim = true;
      mDataLen = widget.datas.length * widget.chartStyle.pointWidth + 150/mScaleX;
      setTranslateXFromScrollX(0);
      _theStartIndex = indexOfTranslateX(xToTranslateX(0));
      double allLength = widget.datas.length * (widget.chartStyle.pointWidth*mScaleX);
      if(allLength<mWidth) _theStartIndex = 0;
      stopIndex = indexOfTranslateX(xToTranslateX(mWidth));
      _openAnim = IntTween(
        begin: _theStartIndex,
        end: widget.datas.length-1,
      ).animate(_openController!);
      _openController?.reset();
      _openController?.forward();
      //动画启动时设置固定X轴位置
      if(allLength>=mWidth) mScrollX = 130/mScaleX;
    }

    lineType = widget.lineType??"";
    if (widget.datas == null || widget.datas.isEmpty) {
      mScrollX = mSelectX = mSelectY = 0.0;
      mScaleX = 1.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    if(widget.datas.length==0) return Container();
    startAnim();
    final _painter = ChartPainter(
        widget.chartStyle,
        widget.chartColors,
        logoImage,
        datas: widget.datas,
        scaleX: mScaleX,
        scrollX: mScrollX,
        selectX: mSelectX,
        selectY: mSelectY,
        isLongPass: isLongPress,
        mainStateList: widget.mainStateList,
        volHidden: widget.volHidden,
        secondaryStateList: widget.secondaryStateList,
        isLine: (widget.isLine??false),
        sink: mInfoWindowStream?.sink,
        bgColor: widget.bgColor,
        fixedLength: (widget.fixedLength??2),
        maDayList: widget.maDayList,
        theStopIndex: _theStopIndex,
        theStartIndex: _theStartIndex,
        openAnimEnd: _openAnimEnd
    );

    hideKLineInfo(){
      //隐藏K线信息
      isLongPress = false;
      mInfoWindowStream?.sink.add(null);
      notifyChanged();
    }
    double screenWidth = MediaQuery.of(context).size.width;

    return Listener(
      onPointerDown: (details){
        if(widget.touchFunc!=null) widget.touchFunc!(true);
        if(pointerEventMap.length==0) {
          flyStartTimeStamp = DateTime.now().millisecondsSinceEpoch;
          pressedUp = false;
          longPressPointer = details.pointer;
        }else longPressPointer = -1;
        //判断长按
        if(longPressPointer!=-1) {
          prepareLongPress = true;
          Future.delayed(Duration(milliseconds: 500),(){
            // print("一秒后...$pressedUp--$isScaling--$isScrolling--$longPressPointer--${details.pointer}");
            if(!pressedUp&&!isScaling&&!isScrolling&&!panUpDown&&longPressPointer==details.pointer) {//1s 没有Up 则表示长按
              isLongPressed = true;
              if(widget.onSecondaryTap != null && _painter.isInSecondaryRect(details.localPosition)) {
                widget.onSecondaryTap!();
              }
              //显示K线信息
              isLongPress = true;
              if (mSelectX != details.localPosition.dx || mSelectY != details.localPosition.dy) {
                mSelectX = details.localPosition.dx;
                mSelectY = details.localPosition.dy;
                notifyChanged();
              }
            }
          });
        }
        if(pointerEventMap.length<2) {
          pointerEventMap[details.pointer] = details;
          pointerMoveEventMap[details.pointer] = Offset(details.localPosition.dx, details.localPosition.dy);
        }
        if(pointerEventMap.length==2){
          Iterable<int> pointerList = pointerEventMap.keys;
          int firstPointer = pointerList.elementAt(0);
          int secondPointer = pointerList.elementAt(1);

          PointerDownEvent? firstDetail = pointerEventMap[firstPointer];
          PointerDownEvent? secondDetail = pointerEventMap[secondPointer];
          Offset? firstOffset = firstDetail?.localPosition;
          Offset? secondOffset = secondDetail?.localPosition;
          if(firstOffset==null||secondOffset==null) return;
          //判断两点的位置 0--左、上  1--右、下
          if(firstOffset.dx>secondOffset.dx){
            if(firstOffset.dy>secondOffset.dy){
              pointerDirectionMap[firstPointer] = [1,1];
              pointerDirectionMap[secondPointer] = [0,0];
            }else {
              pointerDirectionMap[firstPointer] = [1,0];
              pointerDirectionMap[secondPointer] = [0,1];
            }
          }else{
            if(firstOffset.dy>secondOffset.dy){
              pointerDirectionMap[firstPointer] = [0,1];
              pointerDirectionMap[secondPointer] = [1,0];
            }else {
              pointerDirectionMap[firstPointer] = [0,0];
              pointerDirectionMap[secondPointer] = [1,1];
            }
          }
        }
        // print("点击onPointerDown...${details.pointer}--${details.localPosition}--$pointerDirectionMap");

      },
      onPointerMove: (PointerMoveEvent details){
        if(panUpDown) return;
        //长按后移动只改变K线数据的位置
        if(isLongPressed&&longPressPointer==details.pointer) {
          if (mSelectX != details.localPosition.dx || mSelectY != details.localPosition.dy) {
            if(widget.scaleFunc!=null) widget.scaleFunc!(true);
            mSelectX = details.localPosition.dx;
            mSelectY = details.localPosition.dy;
            notifyChanged();
          }
          return;
        }
        //滑动或缩放之前隐藏K线数据
        if(firstMoveStart||pressedUp){
          firstMoveStart = false;
          isLongPress = false;
          mInfoWindowStream?.sink.add(null);
          notifyChanged();
          _stopAnimation();
          _onDragChanged(true);
          hideKLineInfo();
        }

        //判断是否为上下平移
        num moveY = details.localPosition.dy;
        num moveX = details.localPosition.dx;
        num downY = pointerEventMap[details.pointer]?.localPosition.dy??0;
        num downX = pointerEventMap[details.pointer]?.localPosition.dx??0;
        if(pointerEventMap.length<2&&!isLongPressed){
          num yDistance = (moveY-downY).abs();
          num xDistance = (moveX-downX).abs();
          if(yDistance>3*xDistance) {
            if(widget.scaleFunc!=null) widget.scaleFunc!(false);
            panUpDown = true;
            mInfoWindowStream?.sink.add(null);
            notifyChanged();
            return;
          }
        }

        pointerMoveEventMap[details.pointer] = Offset(details.localPosition.dx, details.localPosition.dy);
        //缩放
        if(pointerEventMap.length==2){
          if(pointerEventMap[details.pointer]==null) return;
          if(widget.scaleFunc!=null) widget.scaleFunc!(true);
          isScaling = true;
          //遍历计算Down与Move是的X轴距离和Y轴距离绝对值  去最大值
          Iterable<int> downKeyList = pointerEventMap.keys;
          Iterable<int> moveKeyList = pointerMoveEventMap.keys;
          double downFirstDx = pointerEventMap[downKeyList.first]?.localPosition.dx??0;
          double downFirstDy = pointerEventMap[downKeyList.first]?.localPosition.dy??0;
          double downLastDx = pointerEventMap[downKeyList.last]?.localPosition.dx??0;
          double downLastDy = pointerEventMap[downKeyList.last]?.localPosition.dy??0;
          double moveFirstDx = pointerMoveEventMap[moveKeyList.first]?.dx??0;
          double moveFirstDy = pointerMoveEventMap[moveKeyList.first]?.dy??0;
          double moveLastDx = pointerMoveEventMap[moveKeyList.last]?.dx??0;
          double moveLastDy = pointerMoveEventMap[moveKeyList.last]?.dy??0;
          double downDistanceX = (downFirstDx - downLastDx).abs();
          double moveDistanceX = (moveFirstDx - moveLastDx).abs();
          double downDistanceY = (downFirstDy - downLastDy).abs();
          double moveDistanceY = (moveFirstDy - moveLastDy).abs();

          double distanceXResult = (moveDistanceX-downDistanceX);
          double distanceYResult = (moveDistanceY-downDistanceY);
          double distanceXAbsResult = (moveDistanceX-downDistanceX).abs();
          double distanceYAbsResult = (moveDistanceY-downDistanceY).abs();

          double scale = ((distanceYAbsResult>distanceXAbsResult?distanceYResult:distanceXResult)/(screenWidth/10));
          mScaleX = (_lastScale + scale).clamp(0.7, 3.0);
          notifyChanged();

        }else{
          num downX = pointerEventMap[details.pointer]?.localPosition.dx??0;
          num downY = pointerEventMap[details.pointer]?.localPosition.dy??0;
          num moveX = details.localPosition.dx;
          num moveY = details.localPosition.dy;
          Offset delta = details.delta;

          if((moveX==downX&&moveY==downY)) return;
          if(prepareLongPress&&(delta.dx.abs()<=2&&delta.dy.abs()<=2)) return;

          //缩放后松开一个手指
          if(isScaling) return;
          isScrolling = true;
          prepareLongPress = false;
          if(widget.scaleFunc!=null) widget.scaleFunc!(true);
          // print("滑动...${details.pointer}--${details.position}--${pointerEventMap.length}--${details.buttons}--${details.orientation}--${details.localDelta}");

          num distanceX = 0;
          if(lastMoveMap[details.pointer]==null)
            distanceX = (moveX - downX);
          else{
            distanceX = (moveX-(lastMoveMap[details.pointer]?.localPosition.dx??0));
          }
          mScrollX = (distanceX + mScrollX)
              .clamp(0.0, ChartPainter.maxScrollX).toDouble();
          notifyChanged();
          lastMoveMap[details.pointer] = details;
        }
        pressedUp = true;
      },
      onPointerUp: (details){
        if(widget.touchFunc!=null) widget.touchFunc!(false);
        _lastScale = mScaleX;
        int upTimeStamp = DateTime.now().millisecondsSinceEpoch;
        double downX = pointerEventMap[details.pointer]?.localPosition.dx??0;
        double upX = details.localPosition.dx;
        flyStartTimeStamp = 0;
        // _onFling(upX);

        if(pointerEventMap.containsKey(details.pointer)) pointerEventMap.remove(details.pointer);
        if(pointerMoveEventMap.containsKey(details.pointer)) pointerMoveEventMap.remove(details.pointer);
        if(lastMoveMap.containsKey(details.pointer)) lastMoveMap.remove(details.pointer);
        if(pointerDirectionMap.containsKey(details.pointer)) pointerDirectionMap.remove(details.pointer);
        if(pointerMoveDistanceMap.containsKey(details.pointer)) pointerMoveDistanceMap.remove(details.pointer);
        // print("点击onPointerUp...${details.pointer}--${details.localPosition}--$details");


        //down的记录Map清空代表缩放或者滑动完成
        if(pointerEventMap.length==0){
          //点击
          if(!panUpDown&&!isScaling&&!isScrolling&&!isLongPressed){
            if(widget.onSecondaryTap != null && _painter.isInSecondaryRect(details.localPosition)) widget.onSecondaryTap!();
            //显示K线信息
            isLongPress = true;
            if (mSelectX != details.localPosition.dx || mSelectY != details.localPosition.dy) {
              mSelectX = details.localPosition.dx;
              mSelectY = details.localPosition.dy;
              notifyChanged();
            }
          }
          if(widget.scaleFunc!=null) widget.scaleFunc!(false);
          //缩放结束
          if(isScaling) {
            isScaling = false;
            panUpDown = false;
            _lastScale = mScaleX;
            return;
          }
          //滑动结束
          if(isScrolling){
            isScrolling = false;
            panUpDown = false;
            return;
          }
        }
        firstMoveStart = true;
        if(longPressPointer==details.pointer) pressedUp = true;
        isLongPressed = false;
        longPressPointer = -1;
        scaleOrientation = -1;
        prepareLongPress = false;
        panUpDown = false;
      },
      onPointerCancel: (details){
        if(widget.touchFunc!=null) widget.touchFunc!(false);
        panUpDown = false;
        _lastScale = mScaleX;
        if(pointerEventMap.containsKey(details.pointer)) pointerEventMap.remove(details.pointer);
        if(pointerMoveEventMap.containsKey(details.pointer)) pointerMoveEventMap.remove(details.pointer);
        if(lastMoveMap.containsKey(details.pointer)) lastMoveMap.remove(details.pointer);
        if(pointerDirectionMap.containsKey(details.pointer)) pointerDirectionMap.remove(details.pointer);
        if(pointerMoveDistanceMap.containsKey(details.pointer)) pointerMoveDistanceMap.remove(details.pointer);
        // print("点击onPointerUp...${details.pointer}--${details.localPosition}--$details");
        if(pointerEventMap.length==0){
          if(!isScaling&&!isScrolling&&!isLongPressed){//点击
            if(widget.onSecondaryTap != null && _painter.isInSecondaryRect(details.localPosition)) widget.onSecondaryTap!();

            //显示K线信息
            isLongPress = true;
            if (mSelectX != details.localPosition.dx || mSelectY != details.localPosition.dy) {
              mSelectX = details.localPosition.dx;
              mSelectY = details.localPosition.dy;
              notifyChanged();
            }
          }
          if(widget.scaleFunc!=null) widget.scaleFunc!(false);
          if(isScaling) {//onScaleEnd 缩放结束
            isScaling = false;
            _lastScale = mScaleX;
            return;
          }
          if(isScrolling){//onScrollEnd //滑动结束
            isScrolling = false;
            return;
          }

        }
        firstMoveStart = true;
        if(longPressPointer==details.pointer) pressedUp = true;
        isLongPressed = false;
        longPressPointer = -1;
        scaleOrientation = -1;
        prepareLongPress = false;
      },
      child: Stack(
        children: <Widget>[

          CustomPaint(
            size: Size(double.infinity, double.infinity),
            painter: _painter,
          ),
          _buildInfoDialog()
        ],
      ),
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    if(isScale||downIndexList.length>=2) return;
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.flingTime), vsync: this);
    aniX = null;
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX)
        .animate(
            CurvedAnimation(parent: _controller!, curve: widget.flingCurve));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) widget.onLoadMore!(true);

        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) widget.onLoadMore!(false);

        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  final List<String> infoNamesCN = [
    "时间",
    "开",
    "高",
    "低",
    "收",
    "涨跌额",
    "涨跌幅",
    "成交量"
  ];
  final List<String> infoNamesEN = [
    "Date",
    "Open",
    "High",
    "Low",
    "Close",
    "Change",
    "Change%",
    "Executed"
  ];
  List<String>? infos;

  String getBillionAndThousand(String amount){
    if(amount == null && amount.isEmpty){
      return amount;
    }else{//123456789  12345
      String doubleStr = amount;
      String intStr = doubleStr.split(".")[0];
      if(int.parse(intStr)>=1000000000){
        return '${intStr.substring(0,intStr.length-9)}.${intStr.substring(intStr.length-9,intStr.length-7)}B';
      }
      if(int.parse(intStr)>=1000000){
        return '${intStr.substring(0,intStr.length-6)}.${intStr.substring(intStr.length-6,intStr.length-4)}M';
      }
      if(int.parse(intStr)>=1000){
        return '${intStr.substring(0,intStr.length-3)}.${intStr.substring(intStr.length-3,intStr.length-1)}K';
      }
      return amount;
    }
  }

  StreamBuilder? streamBuilder;
  Widget _buildInfoDialog() {
    if(streamBuilder==null) streamBuilder = StreamBuilder<InfoWindowEntity?>(
        stream: mInfoWindowStream?.stream,
        builder: (context, snapshot) {
          if (!isLongPress ||
              widget.isLine == true ||
              !snapshot.hasData ||
              snapshot.data?.kLineEntity == null || widget.datas.length==0) return Container();
          KLineEntity entity = snapshot.data!.kLineEntity!;
          double upDown = entity.change ?? ((entity.close??0) - (entity.open??0));
          double upDownPercent = entity.ratio ?? (upDown / (entity.open??1)) * 100;
          infos = [
            getDate(entity.time),
            entity.open?.toStringAsFixed((widget.fixedLength??2))??"",
            entity.high?.toStringAsFixed((widget.fixedLength??2))??"",
            entity.low?.toStringAsFixed((widget.fixedLength??2))??"",
            entity.close?.toStringAsFixed((widget.fixedLength??2))??"",
            "${upDown > 0 ? "+" : ""}${upDown.toStringAsFixed((widget.fixedLength??2))}",
            "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
            getBillionAndThousand(entity.amount.toString())
          ];
          return Container(
            margin: EdgeInsets.only(
                left: (snapshot.data?.isLeft??false) ? 20 : mWidth - 130 - 20,
                top: widget.isSmall? 5 : 25
            ),
            width: 130,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(3)),
                color: widget.chartColors.selectInfoBgColor,
                // border: Border.all(
                //     color: widget.chartColors.selectBorderColor, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    spreadRadius: 2,
                    blurRadius: 5,
                  )
                ]
            ),
            child: ListView.builder(
              padding: EdgeInsets.all(6),
              itemCount: infoNamesCN.length,
              itemExtent: widget.isSmall? 15 : 20.0,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return _buildItem((infos?[index]??""),
                    widget.isChinese ? infoNamesCN[index] : infoNamesEN[index]);
              },
            ),
          );
        });
    return streamBuilder!;
  }

  Widget _buildItem(String info, String infoName) {
    Color color = Colors.white;
    if (info.startsWith("+"))
      color = widget.upDownType==0?Colors.red:Colors.green;
    else if (info.startsWith("-"))
      color = widget.upDownType==0?Colors.green:Colors.red;
    else
      color = Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
            child: Text("$infoName",
                style: const TextStyle(color: Colors.black, fontSize: 10.0))),
        Text(info, style: TextStyle(color: color, fontSize: 10.0)),
      ],
    );
  }

  String getDate(int? date) {
    if(date==null) return "";
    return dateFormat(DateTime.fromMillisecondsSinceEpoch(date), widget.timeFormat);;
  }
}
