
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gyflut/gyflut.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _initGySdkResult = 'Unknown';
  String _preLoginResult = 'Unknown';
  String _isPreLoginResultValid = 'Unknown';
  String _getPreLoginResult = 'Unknown';
  String _loginResult = 'Unknown';
  final gyflut = Gyflut();

  @override
  void initState() {
    super.initState();
    initPlatformState();

  }

  void _getPreLoginResultValid() async {
    bool? isPreLoginResultValid = await gyflut.isPreLoginResultValid();
    setState(() {
      _isPreLoginResultValid = isPreLoginResultValid.toString();
    });
  }

  void _getPreLoginResultMethod() async {
    Map<dynamic, dynamic>? getPreLoginResult =
    await gyflut.getPreLoginResult();
    setState(() {
      _getPreLoginResult = getPreLoginResult.toString();
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // String isPreLoginResultValid;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      print("Gyflut.platformVersion ");
      platformVersion =
          await gyflut.platformVersion ?? 'Unknown platform version';
      print("Gyflut.platformVersion "+platformVersion);
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _platformVersion = platformVersion;
    });

    gyflut.addEventHandler(
      initGySdkCallBack: (Map<String, dynamic> msg) async {
        print("flutter initGySdkCallBack: $msg");
        setState(() {
          _initGySdkResult = msg["msg"];

        });
      },
      preloginCallback: (Map<String, dynamic> msg) async {
        print("flutter preloginCallback: $msg");
        setState(() {
          _preLoginResult = msg["msg"];
        });
      },
      loginCallBack: (Map<String, dynamic> msg) async {
        print("flutter loginCallback: $msg");
        //关闭鸿蒙一件登录的弹框
        gyflut.closeAuthLoginPage();
        setState(() {
          _loginResult = msg["msg"];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Plugin example app'),
            ),
            body: ListView(children: <Widget>[
              Container(
                  child: Column(children: <Widget>[
                    Text('Running on: $_platformVersion\n'),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              /// preLoginUseCache:预登录是否使用缓存，默认为true
                              /// debug:是否开启SDK的debug模式，默认false
                              /// operatorDebug:是否开启运营商的debug模式，默认false
                              /// appId: appid（ios)
                              /// preLoginTimeout: 预登录超时时长（ios)
                              /// eloginTimeout:登录超时时长（ios)
                              gyflut.initGySdk(
                                  true, true, false, "5xpxEg5qvI9PNGH2kQAia2");
                            },
                            child: const Text('初始化'),
                          ),
                          Expanded(child: Text('  $_initGySdkResult')),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              gyflut.ePreLogin();
                            },
                            child: const Text('预登录'),
                          ),
                          Expanded(child: Text('  $_preLoginResult')),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: _getPreLoginResultValid,
                            child: const Text('预登录是否有效'),
                          ),
                          Expanded(child: Text('  $_isPreLoginResultValid')),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: _getPreLoginResultMethod,
                            child: const Text('预登录信息'),
                          ),
                          Expanded(child: Text('  $_getPreLoginResult')),
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              gyflut.login();

                            },
                            child: const Text('login'),
                          ),
                          Expanded(child: Text(' $_loginResult')),
                        ]),
                  ]))
            ])));
  }
}
