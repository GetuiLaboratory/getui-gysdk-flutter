
import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos'
import GysdkFlutterPlugin, { GyLoginDialogHost } from 'gyflut'
import EntryAbility from '../entryability/EntryAbility'

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  private plugin: GysdkFlutterPlugin | null = null

  @LocalStorageLink('viewId') viewId: string = "";
  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
      GyLoginDialogHost({ plugin: this.plugin })
    }
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }

  aboutToAppear(): void {
    const plugin = EntryAbility.getInstanse()?.getFlutterEngine()?.getPlugins()?.get('gyflut')
    this.plugin = plugin instanceof GysdkFlutterPlugin ? plugin : null
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
