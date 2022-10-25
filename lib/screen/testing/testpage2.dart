///座椅深蹲測試頁

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:age_calculator/age_calculator.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_app/model/chart_data.dart';
import 'package:sport_app/enum/training_part.dart';
import 'package:sport_app/screen/main_page.dart';
import 'package:sport_app/screen/result/testresultpage.dart';
import 'package:sport_app/theme/color.dart';
import 'package:sport_app/utils/http_request.dart';

import '../../enum/gender.dart';

TrainingPart _part = TrainingPart.quadriceps;
var _timerStart = false;
var _displayTimer = 30;
late Timer timer;

class TestPage2 extends StatefulWidget {
  const TestPage2({Key? key}) : super(key: key);
  static const String routeName = "/test2";

  @override
  State<TestPage2> createState() => _TestPageState2();
}

Widget _title() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: const [
      Opacity(
        opacity: 0.5,
        child: Text(
          '肌動GO',
          style: TextStyle(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
    ],
  );
}

Widget _secondLeftTitle() {
  return const Text(
    '剩餘秒數',
    style: TextStyle(
      color: primaryColor,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _secondLeft(int timer) {
  return Text(
    timer.toString(),
    style: const TextStyle(
      color: primaryColor,
      fontSize: 42,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _countNumberTitle() {
  return const Text(
    '次數',
    style: TextStyle(
      color: primaryColor,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _countNumber(int times) {
  return Text(
    '$times次',
    style: const TextStyle(
      color: primaryColor,
      fontSize: 72,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _angle(int displayAngle) {
  return Text(
    '$displayAngle°',
    style: const TextStyle(
      color: primaryColor,
      fontSize: 42,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _angleTitle() {
  return const Text(
    '角度',
    style: TextStyle(
      color: primaryColor,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget _endBtn(BuildContext context) {
  return Container(
    alignment: Alignment.center,
    child: GestureDetector(
      onLongPress: () {
        Navigator.pushReplacementNamed(context, Main.routeName);
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
  var _times = 0, _displayAngle = 0, _startTime = 0, _checkAddNum = 0.0;
  final List<ChartData> _angleList = [];
  final int tobeMinused = 30;

  late StreamSubscription<AccelerometerEvent> subscription;
  @override
  void initState() {
    super.initState();
    _setTimerEvent();
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
    timer.cancel();
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
              _title(),
              const SizedBox(height: 25),
              _secondLeftTitle(),
              const SizedBox(height: 30),
              _secondLeft(_displayTimer),
              const SizedBox(height: 60),
              _countNumberTitle(),
              _countNumber(_times),
              const SizedBox(height: 60),
              _angle(_displayAngle),
              _angleTitle(),
              const SizedBox(height: 50),
              _endBtn(context),
            ],
          ),
        ],
      ),
    );
  }

  ///計算roll, pitch角度
  void _calcAngles(double accelX, double accelY, double accelZ) {
    var pitch =
        (180 * atan2(accelX, sqrt(accelY * accelY + accelZ * accelZ)) / pi)
            .floor();
    var roll =
        (180 * atan2(accelY, sqrt(accelX * accelX + accelZ * accelZ)) / pi)
            .floor();

    _checkPart(_part, pitch, roll);
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
    _timerStart = true;
    _startTime = DateTime.now().millisecondsSinceEpoch;
    timer = Timer.periodic(
      period,
      (_timer) async {
        _displayTimer = tobeMinused - _timer.tick;
        if (_displayTimer == 0) {
          _loadingCircle();
          final prefs = await SharedPreferences.getInstance();
          String userId = prefs.getString("userId")!;

          String birthday = prefs.getString("birthday")!;
          final birthdayDatetime = DateTime.parse(birthday);
          DateDuration duration = AgeCalculator.age(birthdayDatetime);

          String genderString = prefs.getString("gender")!;
          final gender = Gender.parse(genderString);
          _timer.cancel();
          _timerStart = false;

          // TODO wrap in object
          String quadricepsReqeustData = """
            {
              "user_id": "$userId",
              "part": ${_part.code},
              "times": $_times,
              "age": ${duration.years},
              "gender": ${gender.value},
              "angles": ${jsonEncode(_angleList)}
            }
        """;
          String bicepsRequestData =
              prefs.getString(TrainingPart.biceps.string)!;
          dynamic bicepsResponse = await HttpRequest.post(
              "${HttpURL.host}/record", bicepsRequestData);
          dynamic bicepsData = jsonEncode(bicepsResponse['data']);

          dynamic quadricepsResponse = await HttpRequest.post(
              "${HttpURL.host}/record", quadricepsReqeustData);
          dynamic quadricepsData = jsonEncode(quadricepsResponse['data']);
          prefs.remove(TrainingPart.biceps.string);
          Navigator.pushReplacementNamed(
            context,
            TestResultPage.routeName,
            arguments: {
              "bicepsData": bicepsData,
              "quadricepsData": quadricepsData
            },
          );
        }
      },
    );
  }

  Future<void> _loadingCircle() async {
    //讀取
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('changePage', false);
    Timer? _timer1;
    late double _progress;
    EasyLoading.instance
      ..backgroundColor = primaryColor
      ..textColor = Colors.white
      ..progressColor = Colors.white
      ..maskColor = Colors.white70
      ..displayDuration = const Duration(milliseconds: 10000)
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorType = EasyLoadingIndicatorType.wave
      ..maskType = EasyLoadingMaskType.custom
      ..userInteractions = false;

    _progress = 0;
    _timer1?.cancel();
    _timer1 = Timer.periodic(
      const Duration(milliseconds: 750),
      (Timer timer) async {
        EasyLoading.showProgress(_progress, status: '載入中...');
        _progress += 0.05;

        if (_progress >= 1 || prefs.getBool('changePage') == true) {
          _timer1?.cancel();
          EasyLoading.dismiss();
          await prefs.setBool('changePage', false);
        }
      },
    );
    //讀取結束
  }
}
