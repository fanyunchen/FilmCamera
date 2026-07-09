import { window } from '@kit.ArkUI';
import { BOTTOM_RECT_HEIGHT, TOP_RECT_HEIGHT } from '@hm/app';
import { UIContextUtil } from '@hm/util';

export class EntryUtil {
  static setWindowLayoutFullScreen(windowClass: window.Window) {
    UIContextUtil.UIContext = windowClass.getUIContext()
    
    windowClass.setWindowLayoutFullScreen(true)

    // 存储状态栏的高度
    AppStorage.setOrCreate(TOP_RECT_HEIGHT,
      UIContextUtil.px2vp(windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height))
    // 存储底部导航栏高度
    AppStorage.setOrCreate(BOTTOM_RECT_HEIGHT,
      UIContextUtil.px2vp(windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
        .bottomRect
        .height))

    // 监听状态栏，导航栏的高度并存储
    windowClass.on('avoidAreaChange', option => {
      if (option.type === window.AvoidAreaType.TYPE_SYSTEM) {
        AppStorage.setOrCreate(TOP_RECT_HEIGHT, UIContextUtil.px2vp(option.area.topRect.height))
      } else if (option.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        AppStorage.setOrCreate(BOTTOM_RECT_HEIGHT, UIContextUtil.px2vp(option.area.bottomRect.height))
      }
    })
  }
}