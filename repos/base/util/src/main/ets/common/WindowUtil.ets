import { window } from '@kit.ArkUI';
import { BOTTOM_RECT_HEIGHT, CUTOUT_HEIGHT, CUTOUT_LEFT, CUTOUT_TOP, CUTOUT_WIDTH, TOP_RECT_HEIGHT } from '@hm/app';
import { PixelUtil } from './PixelUtil';

/**
 * 窗口工具类
 * 管理主窗口引用和系统避让区尺寸信息
 */
export class WindowUtil {
  /** 主窗口实例引用 */
  private static mainWindow: window.Window | null = null

  /**
   * 保存主窗口实例
   * @param win 主窗口对象
   */
  static setMainWindow(win: window.Window): void {
    WindowUtil.mainWindow = win
  }

  /**
   * 获取主窗口实例
   * @returns 主窗口对象，未初始化时返回null
   */
  static getMainWindow(): window.Window | null {
    return WindowUtil.mainWindow
  }

  /**
   * 保存状态栏高度到AppStorage
   * @param px 像素值，内部转换为vp
   */
  static saveTopRectHeight(px: number): void {
    AppStorage.setOrCreate(TOP_RECT_HEIGHT, PixelUtil.px2vp(px))
  }

  /**
   * 获取状态栏高度
   * @returns vp单位的高度值
   */
  static getTopRectHeight(): number | undefined {
    return AppStorage.get(TOP_RECT_HEIGHT)
  }

  /**
   * 保存底部导航栏高度到AppStorage
   * @param px 像素值，内部转换为vp
   */
  static saveBottomRectHeight(px: number): void {
    AppStorage.setOrCreate(BOTTOM_RECT_HEIGHT, PixelUtil.px2vp(px))
  }

  /**
   * 获取底部导航栏高度
   * @returns vp单位的高度值
   */
  static getBottomRectHeight(): number | undefined {
    return AppStorage.get(BOTTOM_RECT_HEIGHT)
  }

  /**
   * 保存挖孔屏高度到AppStorage
   * @param px 像素值，内部转换为vp
   */
  static saveCutoutHeight(px: number): void {
    AppStorage.setOrCreate(CUTOUT_HEIGHT, PixelUtil.px2vp(px))
  }

  /**
   * 获取挖孔屏高度
   * @returns vp单位的高度值
   */
  static getCutoutHeight(): number | undefined {
    return AppStorage.get(CUTOUT_HEIGHT)
  }

  /**
   * 保存挖孔屏宽度到AppStorage
   * @param px 像素值，内部转换为vp
   */
  static saveCutoutWidth(px: number): void {
    AppStorage.setOrCreate(CUTOUT_WIDTH, PixelUtil.px2vp(px))
  }

  /**
   * 获取挖孔屏宽度
   * @returns vp单位的宽度值
   */
  static getCutoutWidth(): number | undefined {
    return AppStorage.get(CUTOUT_WIDTH)
  }

  /**
   * 保存挖孔屏左边界坐标到AppStorage
   * @param px 像素值，内部转换为vp
   */
  static saveCutoutLeft(px: number): void {
    AppStorage.setOrCreate(CUTOUT_LEFT, PixelUtil.px2vp(px))
  }

  /**
   * 获取挖孔屏左边界坐标
   * @returns vp单位的坐标值
   */
  static getCutoutLeft(): number | undefined {
    return AppStorage.get(CUTOUT_LEFT)
  }

  /**
   * 保存挖孔屏上边界坐标到AppStorage
   * @param px 像素值，内部转换为vp
   */
  static saveCutoutTop(px: number): void {
    AppStorage.setOrCreate(CUTOUT_TOP, PixelUtil.px2vp(px))
  }

  /**
   * 获取挖孔屏上边界坐标
   * @returns vp单位的坐标值
   */
  static getCutoutTop(): number | undefined {
    return AppStorage.get(CUTOUT_TOP)
  }
}
