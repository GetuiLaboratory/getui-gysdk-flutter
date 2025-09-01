
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';

export default class EntryAbility extends FlutterAbility {
  private  static  entryAbility :EntryAbility|null

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    EntryAbility.entryAbility = this
    super.onCreate(want, launchParam)
  }

    public  static  getInstanse(): EntryAbility|null {
       return EntryAbility.entryAbility
    }

    onDestroy(): void {
      super.onDestroy()
      EntryAbility.entryAbility = null
    }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
