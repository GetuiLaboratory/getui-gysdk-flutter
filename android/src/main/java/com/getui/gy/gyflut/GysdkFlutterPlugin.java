package com.getui.gy.gyflut;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;

import com.g.gysdk.EloginActivityParam;
import com.g.gysdk.GYManager;
import com.g.gysdk.GYResponse;
import com.g.gysdk.GyCallBack;
import com.g.gysdk.GyConfig;
import com.g.gysdk.GyPreloginResult;

import org.json.JSONObject;

import java.util.HashMap;

import io.flutter.BuildConfig;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * GysdkFlutterPlugin
 */
public class GysdkFlutterPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private Context fContext;
    private static final int FLUTTER_CALL_BACK_INIT = 1;
    private static final int FLUTTER_CALL_BACK_PRELOGIN = 2;
    private static final int FLUTTER_CALL_BACK_LOGIN = 3;

    public  static  String TAG = "GysdkFlutterPlugin";


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        Log.d(TAG,"onAttachedToEngine ");
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "gyflut");
        channel.setMethodCallHandler(this);
        fContext = flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.d(TAG,""+call.method);
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("init")) {
            initGySdk(call.argument("preLoginUseCache"), call.argument("debug"), call.argument("operatorDebug"));
        } else if (call.method.equals("ePreLogin")) {
            Integer time = call.argument("timeout");
            ePreLogin(time);
            result.success(null);
        } else if (call.method.equals("login")) {
            login(call.argument("timeout"));
            result.success(null);
        } else if (call.method.equals("isPreLoginResultValid")) {
            boolean preLoginResultValid = isPreLoginResultValid();
            result.success(preLoginResultValid);
        } else if (call.method.equals("getPreLoginResult")) {
            HashMap<String, Object> preLoginResult = getPreLoginResult();
            result.success(preLoginResult);
        } else {
            result.notImplemented();
        }
    }


    private final Handler flutterHandler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            Log.d(TAG,"msg.what : "+ msg.what);


            switch (msg.what) {
                case FLUTTER_CALL_BACK_PRELOGIN:
                   channel.invokeMethod("preloginCallback", msg.obj);
                    break;
                case FLUTTER_CALL_BACK_INIT:
                   channel.invokeMethod("initGySdkCallBack", msg.obj);
                    break;
                case FLUTTER_CALL_BACK_LOGIN:
                   channel.invokeMethod("loginCallBack", msg.obj);
                    break;
                default:
                    break;
            }

        }
    };

    private void ePreLogin(Integer timeout) {
        timeout = timeout == null ? 8000 : timeout;
        GYManager.getInstance().ePreLogin(timeout, new GyCallBack() {
            @Override
            public void onSuccess(GYResponse response) {
                transforMapSend(response, FLUTTER_CALL_BACK_PRELOGIN);
            }

            @Override
            public void onFailed(GYResponse response) {
                transforMapSend(response, FLUTTER_CALL_BACK_PRELOGIN);
            }
        });
    }

    private void initGySdk(Boolean preLoginUseCache, Boolean debug, Boolean operatorDebug) {
        GYManager.getInstance().init(GyConfig.with(fContext)
                //预取号使用缓存，可以提高预取号的成功率，建议设置为true
                .preLoginUseCache(preLoginUseCache == null || preLoginUseCache)
                //个验debug调试模式
                .debug(debug != null && debug)
                //运营商debug调试模式
                .eLoginDebug(operatorDebug != null && operatorDebug)
                //应用渠道
                .channel("flutter")
                //成功失败回调
                .callBack(new GyCallBack() {
                    @Override
                    public void onSuccess(GYResponse response) {
                        transforMapSend(response, FLUTTER_CALL_BACK_INIT);
                    }

                    @Override
                    public void onFailed(GYResponse response) {

                        transforMapSend(response, FLUTTER_CALL_BACK_INIT);
                    }
                }).build());
    }

    private void login(Integer timeout) {
        timeout = timeout == null ? 5000 : timeout;
        GYManager.getInstance().login(timeout, null, new GyCallBack() {
            @Override
            public void onSuccess(GYResponse response) {
                transforMapSend(response, FLUTTER_CALL_BACK_LOGIN);
            }

            @Override
            public void onFailed(GYResponse response) {
                transforMapSend(response, FLUTTER_CALL_BACK_LOGIN);
            }
        });
    }

    private boolean isPreLoginResultValid() {
        boolean resultValid = GYManager.getInstance().isPreLoginResultValid();
        HashMap<String, Object> map = new HashMap<>();
        map.put("isPreLoginResultValid", resultValid);

        return resultValid;
    }

    private HashMap<String, Object> getPreLoginResult() {
        GyPreloginResult response = GYManager.getInstance().getPreLoginResult();
        HashMap<String, Object> map = new HashMap<>();
        map.put("isValid", response.isValid());
        map.put("privacyName", response.getPrivacyName());
        map.put("privacyUrl", response.getPrivacyUrl());
        map.put("operator", response.getOperator());

        return map;
    }


    private void transforMapSend(GYResponse response, int flutterType) {
        Log.d(TAG,"flutterType : "+flutterType);
        HashMap<String, Object> map = new HashMap<>();
        map.put("isSuccess", response.isSuccess());
        map.put("msg", response.getMsg());
        map.put("code", response.getCode());
        map.put("gyuid", response.getGyuid());
        map.put("operator", response.getOperator());
        map.put("result", response.toString());

        Message msg = Message.obtain();
        msg.what = flutterType;
        msg.obj = map;
        flutterHandler.sendMessage(msg);
    }

}
