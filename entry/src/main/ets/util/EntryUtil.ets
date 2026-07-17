import { window } from '@kit.ArkUI';
import { UIContextUtil, WindowUtil } from '@hm/util';

/**
 * Entry模块工具类
 * 封装应用窗口初始化相关的逻辑，在EntryAbility.onWindowStageCreate中调用
 */
export class EntryUtil {
  /**
   * 设置应用沉浸式全屏模式
   * 完成以下初始化：
   * 1. 保存UIContext到全局单例（UIContextUtil），供其他工具类使用
   * 2. 保存主窗口实例到全局单例（WindowUtil），供后续窗口操作使用
   * 3. 启用沉浸式全屏布局（setWindowLayoutFullScreen）
   * 4. 读取系统避让区信息（状态栏、导航栏、挖孔屏）并保存到AppStorage
   * 5. 监听避让区变化，实时更新AppStorage中的值
   *
   * @param windowClass 主窗口实例
   */
  static setWindowLayoutFullScreen(windowClass: window.Window) {
    // 保存UIContext，供PixelUtil等工具类进行px/vp转换
    UIContextUtil.setUIContext(windowClass.getUIContext())

    // 保存主窗口引用，供后续获取窗口属性
    WindowUtil.setMainWindow(windowClass)

    // 启用沉浸式全屏：内容延伸到状态栏和导航栏区域
    windowClass.setWindowLayoutFullScreen(true)

    // 读取并保存状态栏高度（px → vp）
    WindowUtil.saveTopRectHeight(windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height)
    // 读取并保存底部导航栏高度（px → vp）
    WindowUtil.saveBottomRectHeight(
      windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height)

    // 读取并保存挖孔屏（灵动岛/刘海屏）的位置和尺寸信息
    const cutout = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT)
    WindowUtil.saveCutoutHeight(cutout.topRect.height)
    WindowUtil.saveCutoutWidth(cutout.topRect.width)
    WindowUtil.saveCutoutLeft(cutout.topRect.left)
    WindowUtil.saveCutoutTop(cutout.topRect.top)

    // 监听避让区变化（如旋转屏幕、折叠屏状态变化），实时更新存储值
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
