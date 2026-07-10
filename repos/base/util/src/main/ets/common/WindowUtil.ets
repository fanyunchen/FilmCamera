import { window } from '@kit.ArkUI';
import { BOTTOM_RECT_HEIGHT, CUTOUT_HEIGHT, CUTOUT_LEFT, CUTOUT_TOP, CUTOUT_WIDTH, TOP_RECT_HEIGHT } from '@hm/app';
import { PixelUtil } from './PixelUtil';

export class WindowUtil {
  private static mainWindow: window.Window | null = null

  static setMainWindow(win: window.Window): void {
    WindowUtil.mainWindow = win
  }

  static getMainWindow(): window.Window | null {
    return WindowUtil.mainWindow
  }

  /**
   * 保存状态栏高度
   * @param px
   */
  static saveTopRectHeight(px: number): void {
    AppStorage.setOrCreate(TOP_RECT_HEIGHT, PixelUtil.px2vp(px))
  }

  /**
   * 获取状态栏高度
   * @returns vp
   */
  static getTopRectHeight(): number | undefined {
    return AppStorage.get(TOP_RECT_HEIGHT)
  }

  /**
   * 保存导航栏高度
   * @param px
   */
  static saveBottomRectHeight(px: number): void {
    AppStorage.setOrCreate(BOTTOM_RECT_HEIGHT, PixelUtil.px2vp(px))
  }

  /**
   * 获取导航栏高度
   * @returns vp
   */
  static getBottomRectHeight(): number | undefined {
    return AppStorage.get(BOTTOM_RECT_HEIGHT)
  }

  /**
   * 保存前置摄像头挖孔高度
   * @param px
   */
  static saveCutoutHeight(px: number): void {
    AppStorage.setOrCreate(CUTOUT_HEIGHT, PixelUtil.px2vp(px))
  }

  /**
   * 获取前置摄像头挖孔高度
   * @returns vp
   */
  static getCutoutHeight(): number | undefined {
    return AppStorage.get(CUTOUT_HEIGHT)
  }

  /**
   * 保存前置摄像头挖孔宽度
   * @param px
   */
  static saveCutoutWidth(px: number): void {
    AppStorage.setOrCreate(CUTOUT_WIDTH, PixelUtil.px2vp(px))
  }

  /**
   * 获取前置摄像头挖孔宽度
   * @returns vp
   */
  static getCutoutWidth(): number | undefined {
    return AppStorage.get(CUTOUT_WIDTH)
  }

  /**
   * 保存前置摄像头挖孔左边界
   * @param px
   */
  static saveCutoutLeft(px: number): void {
    AppStorage.setOrCreate(CUTOUT_LEFT, PixelUtil.px2vp(px))
  }

  /**
   * 获取前置摄像头挖孔左边界
   * @returns vp
   */
  static getCutoutLeft(): number | undefined {
    return AppStorage.get(CUTOUT_LEFT)
  }

  /**
   * 保存前置摄像头挖孔上边界
   * @param px
   */
  static saveCutoutTop(px: number): void {
    AppStorage.setOrCreate(CUTOUT_TOP, PixelUtil.px2vp(px))
  }

  /**
   * 获取前置摄像头挖孔上边界
   * @returns vp
   */
  static getCutoutTop(): number | undefined {
    return AppStorage.get(CUTOUT_TOP)
  }
}