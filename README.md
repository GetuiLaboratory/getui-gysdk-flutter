# GY Flutter Plugin

## 1、引用

Pub.dev:
<a href="https://pub.dev/packages/gyflut" target="_blank">gy-flutter-plugin</a>

增加依赖：

```shell
flutter pub add gyflut
```

或者手动在工程 pubspec.yaml 中加入 dependencies：

```yaml
dependencies:
  gyflut: ^0.0.2
```
下载依赖：

```shell
flutter pub get
flutter run
```

## 2、配置

## 3、使用
```dart
import 'package:gyflut/gyflut.dart';
```
### 3.1、公共 API

* 公共 API

```dart

  /**
	*
	*初始化SDK
	* @param preLoginUseCache:预登录是否使用缓存，默认为true
	* @param debug:是否开启SDK的debug模式，默认false
	* @param operatorDebug:是否开启运营商的debug模式，默认false
    */
 void initGySdk([bool? preLoginUseCache, bool? debug, bool? operatorDebug])

/**
  *  预登录
  *
  *  @param timeout 超时设置，默认8000ms
  */
  void ePreLogin([int? timeout])

 /**
   *  预登录是否有效
   *
   *  @param timeout 超时设置，默认5000ms
   */
  Future<bool?> isPreLoginResultValid()

/**
  *  预登录结果
  *
  */
 Future<Map<dynamic, dynamic>?> getPreLoginResult()

```
* 回调方法

```dart
  void addEventHandler({
    required EventHandlerMap initGySdkCallBack,
    required EventHandlerMap preloginCallback,
    required EventHandlerMap loginCallBack,
  })
```