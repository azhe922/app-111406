import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_app/db/model/chart_data.dart';
import 'package:sport_app/enum/training_part.dart';
import 'package:sport_app/screen/loadingpage.dart';
import 'package:sport_app/screen/mainpage.dart';
import 'package:sport_app/screen/testpage.dart';
import 'package:sport_app/screen/testresultpage.dart';
import 'package:sport_app/theme/color.dart';
import 'package:sport_app/utils/http_request.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

class Prepare extends StatefulWidget {
  const Prepare({Key? key}) : super(key: key);
  static const String routeName = "/prepare";

  @override
  State<Prepare> createState() => _PrepareState();
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

Widget _CountNumberTitle() {
  return const Text(
    '下一個動作',
    style: TextStyle(
        color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold),
  );
}

Widget _PoseTitle() {
  return const Text(
    '二頭肌彎舉',
    style: TextStyle(
        color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
  );
}

Widget _TutorialScreen(BuildContext context) {
  //一般模式 二頭肌教學
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ImageSlideshow(
        width: MediaQuery.of(context).size.width / 1.5,
        height: MediaQuery.of(context).size.height / 2.5,
        children: [
          Image.network(
            'https://media.gq.com.tw/photos/5fcdfa0ab27ba9fa77ec3274/2:3/w_941,h_1412,c_limit/GettyImages-699086757.jpg',
            fit: BoxFit.cover,
          ),
          Image.network(
            'https://media.gq.com.tw/photos/5fcdfa0ab27ba9fa77ec3274/2:3/w_941,h_1412,c_limit/GettyImages-699086757.jpg',
            fit: BoxFit.cover,
          ),
          Image.network(
            'https://media.gq.com.tw/photos/5fcdfa0ab27ba9fa77ec3274/2:3/w_941,h_1412,c_limit/GettyImages-699086757.jpg',
            fit: BoxFit.cover,
          ),
        ],
        onPageChanged: (value) {
          print('Page changed: $value');
        },
        autoPlayInterval: 3000,
        isLoop: true,
      ),
    ],
  );
}

Widget _StartBtn(BuildContext context) {
  return Container(
    width: MediaQuery.of(context).size.width / 1.5,
    child: ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, TestPage.routeName);
      },
      child: const Text(
        '開始',
        style: TextStyle(fontSize: 24),
      ),
      style: ElevatedButton.styleFrom(
        primary: primaryColor,
      ),
    ),
  );
}

class _PrepareState extends State<Prepare> {
  FlutterTts flutterTts = FlutterTts();
  final List<ChartData> _angleList = [];
  late StreamSubscription<AccelerometerEvent> subscription;
  @override
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.width / 6),
              _Title(),
              const SizedBox(height: 20),
              _CountNumberTitle(),
              const SizedBox(height: 30),
              _PoseTitle(),
              const SizedBox(height: 30),
              // _WarmUpGit(),
              _TutorialScreen(context),
              const SizedBox(height: 30),
              _StartBtn(context),
            ],
          ),
        ],
      ),
    );
  }

  ///設置加速度器更新時間

  var period = const Duration(seconds: 1);

  ///設定倒數計時器

}
