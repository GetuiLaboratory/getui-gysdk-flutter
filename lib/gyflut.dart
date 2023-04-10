import 'dart:async';
import 'dart:ffi';

import 'package:flutter/services.dart';

typedef Future<dynamic> EventHandler(String res);
typedef Future<dynamic> EventHandlerMap(Map<String, dynamic> event);

class Gyflut {
  static const MethodChannel _channel = MethodChannel('gyflut');

  late EventHandlerMap _initGySdkCallBack;
  late EventHandlerMap _preloginCallback;
  late EventHandlerMap _loginCallBack;

  static Future<String?> get platformVersion async {
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

    switch (call.method) {
      case "initGySdkCallBack":
        return _initGySdkCallBack(call.arguments.cast<String, dynamic>());
      case "preloginCallback":
        return _preloginCallback(call.arguments.cast<String, dynamic>());
      case "loginCallBack":
        return _loginCallBack(call.arguments.cast<String, dynamic>());
      default:
        throw UnsupportedError("Unrecongnized Event");
    }
  }

  /**
   * preLoginUseCache:预登录是否使用缓存，默认为true
   * debug:是否开启SDK的debug模式，默认false
   * operatorDebug:是否开启运营商的debug模式，默认false
   */
  void initGySdk([bool? preLoginUseCache, bool? debug, bool? operatorDebug]) {
    _channel.invokeMethod('init', {
      "preLoginUseCache": preLoginUseCache,
      "debug": debug,
      "operatorDebug": operatorDebug
    });
  }

  void ePreLogin([int? timeout]) {

    _channel.invokeMethod('ePreLogin', {"timeout": timeout});
  }

  void login([int? timeout]) {
    _channel.invokeMethod('login', {"timeout": timeout});
  }


  Future<bool?> isPreLoginResultValid() async {
    final bool? result = await _channel.invokeMethod('isPreLoginResultValid');
    return result;
  }

  Future<Map<dynamic, dynamic>?> getPreLoginResult() async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('getPreLoginResult');
    return result;
  }
}
