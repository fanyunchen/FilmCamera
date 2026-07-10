import { window } from '@kit.ArkUI';
import { UIContextUtil, WindowUtil } from '@hm/util';

export class EntryUtil {
  static setWindowLayoutFullScreen(windowClass: window.Window) {
    UIContextUtil.setUIContext(windowClass.getUIContext())

    WindowUtil.setMainWindow(windowClass)

    windowClass.setWindowLayoutFullScreen(true)

    // 存储状态栏的高度
    WindowUtil.saveTopRectHeight(windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height)
    // 存储底部导航栏高度
    WindowUtil.saveBottomRectHeight(
      windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height)

    const cutout = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT)
    WindowUtil.saveCutoutHeight(cutout.topRect.height)
    WindowUtil.saveCutoutWidth(cutout.topRect.width)
    WindowUtil.saveCutoutLeft(cutout.topRect.left)
    WindowUtil.saveCutoutTop(cutout.topRect.top)

    // 监听状态栏，导航栏的高度并存储
    windowClass.on('avoidAreaChange', option => {
      if (option.type === window.AvoidAreaType.TYPE_SYSTEM) {
        WindowUtil.saveTopRectHeight(option.area.topRect.height)
      } else if (option.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        WindowUtil.saveBottomRectHeight(option.area.bottomRect.height)
      } else if (option.type === window.AvoidAreaType.TYPE_CUTOUT) {
        WindowUtil.saveCutoutHeight(option.area.topRect.height)
        WindowUtil.saveCutoutWidth(option.area.topRect.width)
        WindowUtil.saveCutoutLeft(option.area.topRect.left)
        WindowUtil.saveCutoutTop(option.area.topRect.top)
      }
    })
  }
}