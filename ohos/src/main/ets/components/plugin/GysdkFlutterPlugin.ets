import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  FlutterManager
} from '@ohos/flutter_ohos';
import hilog from '@ohos.hilog';
import common from '@ohos.app.ability.common';
import { GyAuthThemeConfig, GyConfig, GyLoginDialog, GyManager, GyResponse } from '@getui/gysdk';

export class OhosGyResponse {
  readonly platform: "ohos" = "ohos"; // 固定值
  readonly isSuccess: boolean
  readonly msg: String
  readonly code: number
  readonly gyuid: String
  readonly operator: String
  readonly result: String
  readonly slogan?: String

  constructor(response: GyResponse, slogan?: String) {
    this.isSuccess = response.isSuccess()
    this.msg = JSON.stringify(response.getData())
    this.code = response.getCode()
    this.gyuid = response.getGyuid()
    this.operator = response.getOperator()
    this.result = JSON.stringify(response)
    this.slogan = slogan
  }
}

let TAG = "gyflut"
const MIN_AUTH_TIMEOUT_MS: number = 5000;

/** GysdkFlutterPlugin **/
export default class GysdkFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  public config: GyAuthThemeConfig | null = null
  public dialog: CustomDialogController | null = null

  constructor() {
  }

  getUniqueClassName(): string {
    return "gyflut"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "gyflut");
    this.channel.setMethodCallHandler(this)
    this.context = FlutterManager.getInstance().getUIAbility()?.context as common.UIAbilityContext
    if (!this.context) {
      this.context = binding.getApplicationContext() as common.UIAbilityContext
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    this.dialog = null
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    hilog.debug(0x0000, TAG, '%{public}s', "method = " + call.method + "  argument = " + JSON.stringify(call.args));
    if (call.method == "getPlatformVersion") {
      result.success("OpenHarmony ^ ^ ")
    } else if (call.method == "init") {
      this.initGySdk(call, result)
    } else if (call.method == "ePreLogin") {
      this.ePreLogin("call", call, result)
    } else if (call.method == "login") {
      // this.eAccountLogin(call, result)
      this.login(call, result)
    } else if (call.method == "getPreLoginResult") {
      this.ePreLogin("get", call, result)
    } else if (call.method == "isPreLoginResultValid") {
      this.isPreLoginResultValid(call, result)
    } else if (call.method == "closeAuthLoginPage") {
      // this.closeAuthLoginPage()
      result.notImplemented()
    } else {
      result.notImplemented()
    }
  }


  initGySdk(call: MethodCall, result: MethodResult): void {
    // GyManager.getInstance().setTestMode(true);
    GyManager.getInstance().init(
      new GyConfig(this.context)
        .setDebug(call.argument("debug"))
        .setPreLoginUseCache(call.argument("preLoginUseCache"))
    ).then((response: GyResponse) => {
      hilog.debug(0x0000, TAG, '%{public}s', "初始化成功 = " + JSON.stringify(response));
      this.channel?.invokeMethod("initGySdkCallBack", JSON.stringify(new OhosGyResponse(response)));
      result.success(null)
    }).catch((error: Error) => {
      hilog.error(0x0000, TAG, '%{public}s', "初始化失败 = " + JSON.stringify(error));
      result.error("-98000", error.name, error.message)
    });
  }

  private resolveAuthTimeout(call: MethodCall): number {
    const requestedTimeout: number | null | undefined = call.argument("timeout");
    return typeof requestedTimeout === "number" && Number.isFinite(requestedTimeout)
      ? Math.max(MIN_AUTH_TIMEOUT_MS, requestedTimeout)
      : MIN_AUTH_TIMEOUT_MS;
  }

  async ePreLogin(type: String, call: MethodCall, result: MethodResult): Promise<void> {
    const timeout = this.resolveAuthTimeout(call);
    hilog.debug(0x0000, TAG, "预取号 timeout=%{public}d ms", timeout);
    if (type == "get") {
      const response = await GyManager.getInstance().ePreLogin(timeout)
      let slogan: String = "";
      switch (response.getOperator()) {
        case "CM":
          slogan = "中国移动提供认证服务";
          break;
        case "CU":
          slogan = "认证服务由联通统一认证提供";
          break;
        case "CT":
          slogan = "天翼账号提供认证服务";
          break;
        default:
          break;
      }
      result.success(JSON.stringify(new OhosGyResponse(response, slogan)))
      return
    }
    GyManager.getInstance().ePreLogin(timeout).then(response => {
      if (response.isSuccess()) {
        hilog.debug(0x0000, TAG, "预取号成功" + JSON.stringify(response));
      } else {
        hilog.warn(0x0000, TAG, "预取号未成功" + JSON.stringify(response));
      }
      this.channel?.invokeMethod("preloginCallback", JSON.stringify(new OhosGyResponse(response)));
      result.success(null)
    }).catch((error: Error) => {
      hilog.error(0x0000, TAG, '%{public}s', "预取号失败 = " + JSON.stringify(error));
      result.error("-98000", error.name, error.message)
    })
  }

  async isPreLoginResultValid(call: MethodCall, result: MethodResult) {
    const isValid: boolean = await GyManager.getInstance().isPreLoginResultValid();
    hilog.debug(0x0000, TAG, '%{public}s', "isPreLoginResultValid = " + JSON.stringify(isValid));
    result.success(isValid)
  }

  async eAccountLogin(call: MethodCall, result: MethodResult) {
    if (!this.config) {
      console.error('config 为空');
      hilog.error(0x0000, TAG, '%{public}s', "config 为空 ");
      result.error("-98000", "config is null", "你需要在@Componentstruct Index 中初始化config,并给插件设置. 参考demo")
      return
    }
    const timeout = this.resolveAuthTimeout(call);
    hilog.debug(0x0000, TAG, "登录 timeout=%{public}d ms", timeout);
    GyManager.getInstance().eAccountLogin(timeout, this.config).then(response => {
      hilog.debug(0x0000, TAG, '%{public}s', "登录成功  " + JSON.stringify(response));
      this.channel?.invokeMethod("loginCallBack", JSON.stringify(new OhosGyResponse(response)));
      result.success(null)
    }).catch((error: Error) => {
      result.error("-98000", error.name, error.message)
      hilog.error(0x0000, TAG, '%{public}s', "登录失败  " + error.message);
    })
  }

  login(call: MethodCall, result: MethodResult) {
    if (!this.dialog) {
      console.error('dialog 为空');
      hilog.error(0x0000, TAG, '%{public}s', "dialog 为空 ");
      result.error("-98000", "dialog is null", "请在当前页面挂载 GyLoginDialogHost，并传入已注册的插件实例")
      return
    }

    const timeout = this.resolveAuthTimeout(call);

    hilog.debug(0x0000, TAG, "登录 timeout=%{public}d ms", timeout);
    GyManager.getInstance().login(timeout, this.dialog).then(response => {
      hilog.info(0x0000, TAG, "登录回包 code=%{public}d success=%{public}s",
        response.getCode(), response.isSuccess() ? "true" : "false");
      this.channel?.invokeMethod("loginCallBack", JSON.stringify(new OhosGyResponse(response)));
      result.success(null)
    }).catch((error: Error) => {
      result.error("-98000", error.name, error.message)
      hilog.error(0x0000, TAG, '%{public}s', "登录失败  " + error.message);
    })
  }

  closeAuthLoginPage() {
    GyManager.getInstance().closeAuthLoginPage();

  }


  getVerifyToken(call: MethodCall, result: MethodResult) {
    // verifyResponse = await GyManager.getInstance().getVerifyToken(phoneNumber, TIMEOUT);
  }

  verifyPhoneNumber(call: MethodCall, result: MethodResult) {
    // const response = await GyManager.getInstance().verifyPhoneNumber(token, processId, phone, operatorType);
    // if (response.isSuccess()) {
    //   hilog.info(0x0000, "GY", `verifyPhoneNumber success ==>${response}`)
    // } else {
    //   hilog.info(0x0000, "GY", `verifyPhoneNumber failed==>${response}`)
    // }
  }
}

/** Mount in the same ArkUI page as FlutterPage to give the dialog a UI owner. */
@Component
export struct GyLoginDialogHost {
  plugin: GysdkFlutterPlugin | null = null
  private attachedPlugin: GysdkFlutterPlugin | null = null
  private readonly dialog = new CustomDialogController({
    builder: GyLoginDialog(),
    width: 0,
    height: 0,
    maskColor: Color.Transparent,
    isModal: false,
    autoCancel: false
  })

  aboutToAppear(): void {
    this.attachedPlugin = this.plugin
    if (this.attachedPlugin) {
      this.attachedPlugin.dialog = this.dialog
      hilog.debug(0x0000, TAG, "已绑定当前页面的登录弹窗")
    }
  }

  aboutToDisappear(): void {
    if (this.attachedPlugin && this.attachedPlugin.dialog === this.dialog) {
      this.attachedPlugin.dialog = null
    }
    this.attachedPlugin = null
  }

  build() {
    Column() {}
    .width(0)
    .height(0)
  }
}
