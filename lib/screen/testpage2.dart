import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_app/db/model/chart_data.dart';
import 'package:sport_app/enum/training_part.dart';
import 'package:sport_app/screen/loadingpage.dart';
import 'package:sport_app/screen/prepare2.dart';
import 'package:sport_app/screen/main_page.dart';
import 'package:sport_app/screen/testresultpage.dart';
import 'package:sport_app/theme/color.dart';
import 'package:sport_app/utils/http_request.dart';

int _part = 0, _type = 0;
var _timerStart = false;
var _ss = 0;

class TestPage2 extends StatefulWidget {
  const TestPage2({Key? key}) : super(key: key);
  static const String routeName = "/test2";

  @override
  State<TestPage2> createState() => _TestPageState2();
}

Widget _Title() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      Opacity(
        opacity: 0.5,
        child: Text(
          '肌動GO',
          style: TextStyle(
              color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      )
    ],
  );
}

Widget _SecondLeftTitle() {
  return const Text(
    '剩餘秒數',
    style: TextStyle(
        color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
  );
}

Widget _SecondLeft(int timer) {
  return Text(
    timer.toString(),
    style: const TextStyle(
        color: primaryColor, fontSize: 42, fontWeight: FontWeight.bold),
  );
}

Widget _CountNumberTitle() {
  return const Text(
    '次數',
    style: TextStyle(
        color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
  );
}

Widget _CountNumber(int times) {
  return Text(
    '$times次',
    style: const TextStyle(
        color: primaryColor, fontSize: 72, fontWeight: FontWeight.bold),
  );
}

Widget _Angle(int displayAngle) {
  return Text(
    '$displayAngle°',
    style: const TextStyle(
        color: primaryColor, fontSize: 42, fontWeight: FontWeight.bold),
  );
}

Widget _AngleTitle() {
  return const Text(
    '角度',
    style: TextStyle(
        color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
  );
}

Widget _EndBtn(BuildContext context) {
  return Container(
    alignment: Alignment.center,
    child: GestureDetector(
      onLongPress: () {
        _ss = 1;
        Navigator.pushNamed(context, Main.routeName);
      },
      child: const Text(
        '長按結束',
        style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            decoration: TextDecoration.underline),
      ),
    ),
  );
}

class _TestPageState2 extends State<TestPage2> {
  FlutterTts flutterTts = FlutterTts();
  var _times = 0,
      _displayAngle = 0,
      _displayTimer = 30,
      _startTime = 0,
      _checkAddNum = 0.0;
  final List<ChartData> _angleList = [];
  final int _timer = 30;

  late StreamSubscription<AccelerometerEvent> subscription;
  @override
  void initState() {
    super.initState();
    _setTimerEvent();
    _loadPrefs();
    subscription =
        motionSensors.accelerometer.listen((AccelerometerEvent event) {
      setState(() {
        _calcAngles(event.x, event.y, event.z);
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setUpdateInterval(Duration.microsecondsPerSecond ~/ 60);
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.width / 6),
              _Title(),
              const SizedBox(height: 25),
              _SecondLeftTitle(),
              const SizedBox(height: 30),
              _SecondLeft(_displayTimer),
              const SizedBox(height: 60),
              _CountNumberTitle(),
              _CountNumber(_times),
              const SizedBox(height: 60),
              _Angle(_displayAngle),
              _AngleTitle(),
              const SizedBox(height: 50),
              _EndBtn(context),
            ],
          ),
        ],
      ),
    );
  }

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _part = (prefs.getInt("part") ?? 0);
    _type = (prefs.getInt("type") ?? 0);
  }

  ///計算roll, pitch角度
  void _calcAngles(double accelX, double accelY, double accelZ) {
    var pitch =
        (180 * atan2(accelX, sqrt(accelY * accelY + accelZ * accelZ)) / pi)
            .floor();
    var roll =
        (180 * atan2(accelY, sqrt(accelX * accelX + accelZ * accelZ)) / pi)
            .floor();

    //可能需要例外處理
    TrainingPart? part = TrainingPart.parse(_part);

    _checkPart(part!, pitch, roll);
  }

  ///區分訓練部位
  void _checkPart(TrainingPart part, int pitch, int roll) {
    bool isMinAngle = false, isMaxAngle = false;

    roll += 90;
    _displayAngle = roll;
    isMinAngle = roll < 65;
    isMaxAngle = roll > 87;

    _addTimes(_displayAngle, isMinAngle, isMaxAngle);
  }

  ///判斷是否符合增加次數條件
  void _addTimes(int roll, bool isMin, bool isMax) {
    if (_checkAddNum == 0 && isMin) _checkAddNum += .5;

    if (_checkAddNum == 0.5 && isMax) _checkAddNum += .5;

    if (_checkAddNum == 1) {
      _times += 1;
      _s(_times);
      _checkAddNum = 0.0;
    }
  }

  ///文字轉語音
  Future _s(int times) async {
    await flutterTts.speak('$times');
  }

  ///設置加速度器更新時間
  void setUpdateInterval(int interval) {
    motionSensors.accelerometerUpdateInterval = interval;
    setState(() {
      if (_timerStart) {
        int now = DateTime.now().millisecondsSinceEpoch;
        double sec = (now - _startTime) / 1000;
        var data = ChartData(sec, _displayAngle);
        _angleList.add(data);
      }
    });
  }

  var period = const Duration(seconds: 1);

  ///設定倒數計時器
  void _setTimerEvent() {
    Timer? _timer1;
    late double _progress;
    _timerStart = true;
    _startTime = DateTime.now().millisecondsSinceEpoch;
    Timer.periodic(period, (timer) async {
      _displayTimer = _timer - timer.tick;
      if (_displayTimer == 0) {
        timer.cancel();
        _timerStart = false;
        // TODO 需載入登入資訊，待修改
        String reqeustData = """
            {
              "user_id": "zsda5858sda",
              "part": $_part,
              "times": $_times,
              "age": 100,
              "gender": 0,
              "angles": ${jsonEncode(_angleList)}
            }
        """;
        Navigator.pushNamed(context, TestResultPage.routeName);
        // dynamic response =
        //     await HttpRequest().post("${HttpURL.host}/api/record", reqeustData);
        // Navigator.pushReplacementNamed(context, Prepare2.routeName, arguments: {
        //   'data': response["data"],
        //   'angles': jsonEncode(_angleList)
        // });
      }
      if (_ss == 1) {
        timer.cancel();
        _timerStart = false;
        _ss = 0;
      }
    });
  }
}
