import {
    GyAuthLoginDialog,
    GyAuthThemeConfig,
    GyConfig,
    GyLog,
    GyLoginDialog,
    GyManager,
    GyResponse
} from '@getui/gysdk';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { bundleManager } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { JSON, util } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

const DOMAIN = 0X1111;
const TAG = "gy.log";

function getAppid() {
    const flags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
        | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(flags);
    let appid = "";
    const array = bundleInfo.appInfo.metadataArray;
    array.forEach((moduleMetadata) => {
        moduleMetadata.metadata.forEach((metadata: bundleManager.Metadata) => {
            if ("GETUI_APPID" === metadata.name) {
                appid = metadata.value;
            }
        })
    })
    return appid;
}

function showDialog(title: string, response: GyResponse | string) {
    promptAction.showDialog({
        title: title,
        message: typeof response === 'string' ? response : JSON.stringify(response, null, 2)
    })
}

function showToast(message: string) {
    promptAction.showToast({
        message: message
    })
}

//号码预校验结果
let verifyResponse: GyResponse | undefined;
let loginResponse: GyResponse | undefined;

const TIMEOUT = 5000;

@Entry
@Component
struct Index {
    static readOneID(context: Context) {
        const key = 'oneid-76336fe5b4b92be0f5c212e1f577d4ea'
        //let
        preferences.getPreferences(context.getApplicationContext(), key)
            .then(async (p) => {
                let a = p.getAllSync();
                await p.flush();
                a = p.getAllSync();
                const oneIdBuffer = p.getSync("oneid", undefined)
                if (oneIdBuffer && oneIdBuffer instanceof Uint8Array) {
                    //const tempKey =
                    // const oneId = Index.getXOR(tempKey, oneIdBuffer)
                    // return buffer.from(oneId).toString()
                }
                // return ''
            })
    }

    @State gyuid: string = "gyuid请先初始化";
    @State textValue: string = ''
    @State inputValue: string = 'click me'
    private readonly config: GyAuthThemeConfig = new GyAuthThemeConfig().setSystemBarProperties({
        statusBarColor: '#ffffff',
        navigationBarColor: '#ffffff',
        statusBarContentColor: '#000000',
        navigationBarContentColor: '#00ffff'
    })
        .setPrivacyNavTextColor(Color.White)
        .setPrivacyNavTextSize(20)
        .setPrivacyNavHeight(50)
        .setPrivacyUnCheckedToastText("测试未同意隐私协议")
        .setLoginPageComponent(authPageComponent)// .setNumberColor("#3973ff")
        .setNumberSize(28)
        .setNumberMargin({ top: 30 })
        .setNumberAlignRuleOption({
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
            top: { anchor: 'gy_login_logo_image', align: VerticalAlign.Bottom },
        })
        .setCheckedColor(Color.Blue)
        .setLoginBtnText("本机号码一键登录")
        .setLoginBtnTextSize(20)
        .setLoginBtnTextColor(Color.White)
        .setLoginBtnColor("#3973ff")
        .setLoginBtnWidth('70%')
        .setLoginBtnHeight(48)
        .setLoginBtnMargin({ top: 0 })
        .setLoginBtnAlignRuleOption({
            top: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .setClauses([{
            text: "同意",
            isProtocol: false,
            fontColor: Color.Black,
            fontSize: 16,
            fontWeight: FontWeight.Normal,
        }, {
            text: "《&&Clause&&》",
            isProtocol: true,
            fontColor: "#3973ff",
            fontSize: 16,
            fontWeight: FontWeight.Normal,
        },
            {
                text: "自定义协议",
                isProtocol: true,
                fontColor: "#3973ff",
                fontSize: 16,
                fontWeight: FontWeight.Normal,
                url: "https://www.baidu.com/"
            },
            {
                text: "并使用本机号码校验",
                isProtocol: false,
                fontColor: Color.Black,
                fontSize: 16,
                fontWeight: FontWeight.Normal
            }
        ])
        .setCheckBoxSize(20, 20)
        .setCheckBoxShape(CheckBoxShape.ROUNDED_SQUARE)
        .setCheckBoxMargin({ left: 20, bottom: 20 })
        .setCheckBoxAlignRuleOption({
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
            left: { anchor: '__container__', align: HorizontalAlign.Start }
        })
        .setClauseMargin({ left: 5, right: 15 })
        .setClauseAlignRuleOption({
            left: { anchor: 'gy_login_clause_checkbox', align: HorizontalAlign.End },
            top: { anchor: 'gy_login_clause_checkbox', align: VerticalAlign.Top },
            right: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .setOnAuthLoginPageListener({
            onLoginPageInComplete: () => {
                GyLog.debug("login page 成功拉起授权页")
            },
            onCheckedChanged: (checked): void => {
                GyLog.debug("login page checkBok 选中状态：" + checked)
            },
            onBackPressed: () => {
                GyLog.debug("login page 返回事件")
            },
            onLoginClickStart: () => {
                GyLog.debug("login page 点击登录按钮")
            },
            onLoginClickComplete: () => {
                GyLog.debug("login page 登录返回响应")
            },
            onAuthLogin: (message, callback?): void => {
                if (callback) {
                    promptAction.showDialog({
                        message: '是否授权登录',
                        buttons: [
                            { text: '确定', color: '#000000' },
                            { text: '取消', color: '#000000' }
                        ],
                    }).then(data => {
                        if (data.index == 0) {
                            callback(true)
                        } else {
                            callback(false)
                        }
                    })
                }
            }
        });
    dialogController: CustomDialogController | null = new CustomDialogController({
        builder: VerifyDialog({
            textValue: $textValue,
            inputValue: $inputValue,
            confirm: async (phoneNumber) => {
                if (phoneNumber && phoneNumber.length == 11) {
                    verifyResponse = await GyManager.getInstance().getVerifyToken(phoneNumber, TIMEOUT);
                    hilog.debug(DOMAIN, TAG, `preVerify==>${JSON.stringify(verifyResponse, undefined, 2)}`)
                    showDialog("获取校验token", verifyResponse);
                } else {
                    showToast("请输入正确的手机号码")
                }
            }
        }),
        autoCancel: true,
        alignment: DialogAlignment.Bottom,
        offset: { dx: 0, dy: 0 },
        gridCount: 4,
        customStyle: false,
        cornerRadius: 10,
    })

    build() {
        Column() {
            Text(GyManager.getInstance().getVersion())
                .fontSize(15)
                .fontColor(Color.Green)
                .width("90%")
                .margin(8)
            Text(getContext().applicationInfo.name)
                .fontSize(15)
                .fontColor(Color.Green)
                .width("90%")
                .margin(8)
            Text(this.gyuid)
                .fontSize(15)
                .fontColor(Color.Green)
                .width("90%")
                .align(Alignment.Center)
                .margin(8)
            Text(getAppid())
                .fontSize(15)
                .fontColor(Color.Green)
                .width("90%")
                .align(Alignment.Center)
                .margin(8)
            Button("初始化")
                .fontSize(20)
                .width("60%")
                .margin(10)
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    // try {
                    //     let a = await OneID.init(getContext(this).getApplicationContext());
                    // } catch (e) {
                    //     GyLog.debug("eeeee", e)
                    // }
                    // // setTimeout(() => {
                    // Index.readOneID(getContext(this))
                    // //}, 4000)
                    // GyManager.getInstance().setTestMode(true);
                    const response = await GyManager.getInstance().init(new GyConfig(getContext(Index))
                        .setDebug(true)
                        .setPreLoginUseCache(false)
                        //.setAppid("{传入的appid}")
                        .setChannel("huawei"))
                    if (response.isSuccess()) {
                        hilog.info(0x0000, "GY", `init success ==>${response}`)
                    } else {
                        hilog.info(0x0000, "GY", `init failed==>${response}`)
                    }
                    GyManager.getInstance().isPreLoginResultValid()
                    this.gyuid = response.getGyuid();
                    hilog.info(DOMAIN, TAG, `init==>${JSON.stringify(response, undefined, 2)}`)
                    promptAction.showToast({
                        message: "初始化"
                    })
                    showToast("初始化" + (response.isSuccess() ? "成功" : "失败"))
                    // const response2 = await GyManager.getInstance().ePreLogin(TIMEOUT);
                    // hilog.debug(DOMAIN, TAG, `preLogin==>${JSON.stringify(response2, undefined, 2)}`)
                    // showDialog("预取号", response2);
                })
            Button("预取号")
                .fontSize(20)
                .margin(10)
                .width("60%")
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    const response = await GyManager.getInstance().ePreLogin(TIMEOUT);
                    hilog.debug(DOMAIN, TAG, `preLogin==>${JSON.stringify(response, undefined, 2)}`)
                    const result = await GyManager.getInstance().getPreLoginResult();
                    hilog.debug(DOMAIN, TAG, `preLoginResult==>${JSON.stringify(result, undefined, 2)}`)
                    hilog.debug(DOMAIN, TAG, `preLoginResult==>${GyManager.getInstance().getOperatorAgent(1)}`)

                    showDialog("预取号", response);
                })
            Button("全屏登录")
                .fontSize(20)
                .margin(10)
                .width("60%")
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    this.config.setWindowMode(undefined)
                    this.config.setLogoMargin({ top: 120 })
                    loginResponse = await GyManager.getInstance().eAccountLogin(TIMEOUT, this.config)
                    hilog.debug(DOMAIN, TAG, `login==>${JSON.stringify(loginResponse, undefined, 2)}`)
                    showDialog("全屏登录", loginResponse);
                    //GyManager.getInstance().closeAuthLoginPage()
                })
            Button("窗口登录")
                .fontSize(20)
                .margin(10)
                .width("60%")
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    const dialogController = new CustomDialogController({
                        builder: GyAuthLoginDialog({ dialogWidth: "100%", dialogHeight: "80%" }),
                        // //自定义蒙层颜色
                        // maskColor: Color.Transparent,
                        // //窗口背景颜色
                        // //如果同时设置了内容构造器的背景色，则backgroundColor会被内容构造器的背景色覆盖。
                        // //当设置了backgroundColor为非透明色时，backgroundBlurStyle需要设置为BlurStyle.NONE，
                        // //否则颜色显示将不符合预期效果。
                        // backgroundColor: Color.White,
                        // //弹窗背板模糊材质
                        // backgroundBlurStyle: BlurStyle.NONE,
                        // //弹窗是否为模态窗口，模态窗口有蒙层，非模态窗口无蒙层
                        // isModal: true,
                        // //是否允许点击遮障层退出，true表示关闭弹窗。false表示不关闭
                        // autoCancel: false,
                        // // 弹窗在竖直方向上的对齐方式。
                        // alignment: DialogAlignment.Center
                    })
                    this.config.setWindowMode(dialogController)
                    this.config.setLogoMargin({ top: 50 })
                    loginResponse = await GyManager.getInstance().eAccountLogin(TIMEOUT, this.config)
                    hilog.debug(DOMAIN, TAG, `login==>${JSON.stringify(loginResponse, undefined, 2)}`)
                    showDialog("窗口登录", loginResponse);
                    //GyManager.getInstance().closeAuthLoginPage()
                })
            Button("无UI登录")
                .fontSize(20)
                .margin(10)
                .width("60%")
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    //无UI登录
                    const dialog = new CustomDialogController({
                        builder: GyLoginDialog(),
                        width: 0,
                        height: 0,
                        maskColor: Color.Transparent,
                        isModal: false,
                        autoCancel: false
                    })
                    loginResponse = await GyManager.getInstance().login(TIMEOUT, dialog)
                    hilog.debug(DOMAIN, TAG, `login==>${JSON.stringify(loginResponse, undefined, 2)}`)
                    showDialog("无UI登录", loginResponse);
                })
            Button("取号")
                .fontSize(20)
                .margin(10)
                .width("60%")
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    if (!loginResponse || !loginResponse.isSuccess()) {
                        showToast("请先调用登录")
                        return
                    }
                    const options: http.HttpRequestOptions = {
                        method: http.RequestMethod.POST,
                        header: { 'Content-Type': 'application/json; charset=utf-8' },
                        connectTimeout: 7000,
                        readTimeout: 7000,
                        usingCache: false,
                        //统一处理为buffer
                        expectDataType: http.HttpDataType.STRING,
                        usingProtocol: http.HttpProtocol.HTTP1_1,
                        extraData: {
                            appId: getAppid(),
                            gyuid: loginResponse.getGyuid(),
                            token: loginResponse.getData()["token"],
                            timestamp: Date.now()
                        }
                    }
                    const httpRequest = http.createHttp();
                    httpRequest.request("http://192.168.10.62:8130/v1/gy/ct_login/gy_get_pn", options,
                        //httpRequest.request("https://openapi-gy.getui.com/v1/gy/ct_login/gy_get_pn", options,
                        (err, data) => {
                            if (err) {
                                showDialog("取号http异常", JSON.stringify(err))
                            } else {
                                try {
                                    showDialog("取号结果",
                                        JSON.stringify(JSON.parse(data.result as string), undefined, 2))
                                } catch (e) {
                                    showDialog("取号结果", data.result as string)
                                }
                            }
                            httpRequest.destroy()
                        })
                })
            Button("预校验")
                .fontSize(20)
                .margin(10)
                .width("60%")
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    if (this.dialogController != null) {
                        this.dialogController.open()
                    }
                    // // router.pushUrl({
                    // //     url: "pages/Second"
                    // // })
                    // router.back()
                })
            Button("校验")
                .fontSize(20)
                .margin(10)
                .width("60%")
                .fontWeight(FontWeight.Bold)
                .onClick(async () => {
                    if (!verifyResponse || !verifyResponse.isSuccess()) {
                        GyLog.debug("please call preVerify first:");
                        showToast("请先调用预校验")
                        return
                    }
                    const data = verifyResponse.getData();
                    const response = await GyManager.getInstance()
                        .verifyPhoneNumber(data["token"] as string, data["processId"] as string,
                            data["phone"] as string, data["operatorType"] as number);
                    hilog.debug(DOMAIN, TAG, `verify==>${JSON.stringify(response, undefined, 2)}`)
                    showDialog("服务端校验", response);
                })
        }
        .width('100%')
        .margin({ top: "15%" })
    }
    
    // 自定义方式2：使用系统提供的多种默认效果(平移、缩放、透明度等)
    // pageTransition() {
    //     // 跳转的到login页面的动画取消掉
    //     PageTransitionExit({ type: RouteType.Push })
    //     PageTransitionEnter({ type: RouteType.Pop })
    // }
    onBackPress(): boolean | void {
        GyLog.debug("CM--onPageShow onBackPress ")
    }

    onPageShow(): void {
        GyLog.debug("CM--onPageShow LOGIN ")
    }

    onPageHide(): void {
        GyLog.debug("CM--onPageHide LOGIN ")
    }

    aboutToAppear(): void {
        GyLog.debug("CM--aboutToAppear LOGIN ")
    }

    // 在自定义组件即将析构销毁时将dialogController置空
    aboutToDisappear() {
        this.dialogController = null // 将dialogController置空
        GyLog.debug("CM--aboutToDisappear LOGIN ")
    }
}

//https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-methods-custom-dialog-box-V5
@CustomDialog
@Component
struct VerifyDialog {
    //号码校验输入框
    @Link textValue: string
    @Link inputValue: string
    confirm: (phoneNumber: string) => void = (phoneNumber: string) => {
    }
    //自行赋值?
    controller: CustomDialogController

    aboutToAppear(): void {
        GyLog.debug("CM--aboutToAppear VerifyDialog :" + Date.now())
    }

    aboutToDisappear(): void {
        GyLog.debug("CM--aboutToDisappear VerifyDialog ")
    }

    onPageShow(): void {
        GyLog.debug("CM--onPageShow VerifyDialog ")
    }

    onPageHide(): void {
        GyLog.debug("CM--onPageHide VerifyDialog ")
    }

    build() {
        Column() {
            Text('预校验').fontSize(20).margin({ top: 10, bottom: 10 })
            TextInput({ placeholder: '请输入手机号码', text: this.textValue })
                .height(50)
                .width('90%')
                .type(InputType.Number)
                .onChange((value: string) => {
                    this.textValue = value
                })
            Flex({ justifyContent: FlexAlign.SpaceAround }) {
                Button('取消')
                    .onClick(() => {
                        if (this.controller != undefined) {
                            this.controller.close()
                        }
                    }).backgroundColor(0xffffff).fontColor(Color.Black)
                Button('获取token')
                    .onClick(() => {
                        if (this.controller != undefined) {
                            this.inputValue = this.textValue
                            this.controller.close()
                            this.confirm(this.textValue);
                        }
                    }).backgroundColor(0xffffff).fontColor(Color.Blue)
            }.margin({ bottom: 20, top: 20 })
        }.borderRadius(10)
    }
}

@Builder
export function authPageComponent(obj?: object): void {
    Column() {
        Text(obj ? (obj as componentConfig).getText() : '自定义文本')
            .fontSize(20)
            .alignRules({
                middle: { anchor: '__container__', align: HorizontalAlign.Center },
                center: { anchor: '__container__', align: VerticalAlign.Center },
            }).margin({ top: "80%" })
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
        GyManager.getInstance().closeAuthLoginPage()
    })
    .backgroundColor(0x7f0086d0)
    .id("111")
}

export class componentConfig {
    private text: string = "移动提供一键认证服务"

    public getText(): string {
        return this.text
    }
}