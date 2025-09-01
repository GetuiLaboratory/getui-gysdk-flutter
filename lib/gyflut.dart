import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
typedef Future<dynamic> EventHandler(String res);
typedef Future<dynamic> EventHandlerMap(Map<String, dynamic> event);

class Gyflut {
  static const MethodChannel _channel = MethodChannel('gyflut');

  late EventHandlerMap _initGySdkCallBack;
  late EventHandlerMap _preloginCallback;
  late EventHandlerMap _loginCallBack;


  Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  void addEventHandler({
    required EventHandlerMap initGySdkCallBack,
    required EventHandlerMap preloginCallback,
    required EventHandlerMap loginCallBack,
  }) {
    _initGySdkCallBack = initGySdkCallBack;
    _preloginCallback = preloginCallback;
    _loginCallBack = loginCallBack;
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future _handleMethod(MethodCall call) async {
    print( "_handleMethod method:"  + call.method );
    dynamic result;
    if (call.arguments is String) {
      result = jsonDecode(call.arguments) as Map<String, dynamic>;
    } else {
      result = call.arguments.cast<String, dynamic>();
    }
    switch (call.method) {
      case "initGySdkCallBack":
        return _initGySdkCallBack(result);
      case "preloginCallback":
        return _preloginCallback(result);
      case "loginCallBack":
        return _loginCallBack(result);
      default:
        throw UnsupportedError("Unrecongnized Event");
    }
  }

  /// preLoginUseCache:预登录是否使用缓存，默认为true
  /// debug:是否开启SDK的debug模式，默认false
  /// operatorDebug:是否开启运营商的debug模式，默认false
  /// appId: appid（ios)
  /// preLoginTimeout: 预登录超时时长（ios)
  /// eloginTimeout:登录超时时长（ios)
  void initGySdk(
      [bool? preLoginUseCache,
      bool? debug,
      bool? operatorDebug,
      String? appId,
      int? preLoginTimeout, int? eloginTimeout]) {
    if (Platform.isIOS) {
      _channel.invokeMethod('init', {
        "appId": appId,
        "debug": debug,
        "preLoginTimeout": preLoginTimeout ?? 10,
        "eloginTimeout": eloginTimeout ?? 10
      });
    } else {
      _channel.invokeMethod('init', {
        "preLoginUseCache": preLoginUseCache,
        "debug": debug,
        "operatorDebug": operatorDebug
      });
    }
  }

  void ePreLogin([int? timeout]) {
    if (Platform.isIOS) {
      _channel.invokeMethod('ePreLogin', {});
    } else {
      _channel.invokeMethod('ePreLogin', {"timeout": timeout});
    }
  }

  void login([int? timeout]) {
    if (Platform.isIOS) {
      _channel.invokeMethod('login', {});
    } else {
      _channel.invokeMethod('login', {"timeout": timeout});
    }
  }
  void closeAuthLoginPage() {
    //鸿蒙关闭一键登录弹框
    _channel.invokeMethod('closeAuthLoginPage', {});
  }


  Future<bool?> isPreLoginResultValid() async {
    final bool? result = await _channel.invokeMethod('isPreLoginResultValid');
    return result;
  }

  Future<Map<dynamic, dynamic>?> getPreLoginResult() async {
    dynamic result =  await _channel.invokeMethod('getPreLoginResult');
    if (result is String) {
      result = jsonDecode(result) as Map<String, dynamic>;
    } else {
      result = result.cast<String, dynamic>();
    }
    return result;
  }
}
