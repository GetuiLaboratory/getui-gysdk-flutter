
import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos'

import GysdkFlutterPlugin from 'gyflut';
import { GyAuthLoginDialog, GyAuthThemeConfig, GyConfig, GyLog, GyManager, GyResponse } from 'gyflut';
import EntryAbility from '../entryability/EntryAbility';
import { promptAction } from '@kit.ArkUI';

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private readonly  dialogController: CustomDialogController = new CustomDialogController({
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
    .setLoginPageComponent(authPageComponent)//设置自定义布局
    .setNumberColor("#3973ff")//带星手机号的颜色
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


  private context = getContext(this) as common.UIAbilityContext

  @LocalStorageLink('viewId') viewId: string = "";
  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }

  aboutToAppear(): void {
    //使用弹框模式
    //this.config.setWindowMode(this.dialogController)
    //this.config.setLogoMargin({ top: 50 })

    let  plugin : GysdkFlutterPlugin =   EntryAbility.getInstanse()?.getFlutterEngine()?.getPlugins()?.get(new GysdkFlutterPlugin().getUniqueClassName()) as GysdkFlutterPlugin
    plugin.config = this.config
  }
  aboutToDisappear() {
  }
}

@Builder
export function authPageComponent(): void {
  Column() {
    Text('自定义文本')
      .fontSize(30)
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        center: { anchor: '__container__', align: VerticalAlign.Center },

      }).margin({ top: "10%" })
  }.width('100%')
  .height('100%')
  //设置背景色
  .backgroundColor(Color.White)
  .id("111")
}
