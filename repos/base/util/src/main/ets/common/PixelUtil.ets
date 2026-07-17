import { display } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { UIContextUtil } from './UIContextUtil';

/**
 * 像素与图片工具类
 * 提供像素单位转换和图片解码/释放功能
 */
export class PixelUtil {
  /**
   * 获取屏幕物理密度值
   * 当UIContext不可用时作为px/vp转换的回退方案
   * @returns 屏幕密度像素值（如3.0表示3倍屏）
   */
  static getDensity() {
    let displayClass = display.getDefaultDisplaySync();
    let density = displayClass.densityPixels;
    return density;
  }

  /**
   * 物理像素(px)转虚拟像素(vp)
   * @param px 物理像素值
   * @param uiContext 可选的UIContext，提供更精确的转换
   * @returns vp值
   */
  static px2vp(px: number, uiContext?: UIContext): number {
    const _uiContext = UIContextUtil.getEffectiveUIContext(uiContext)
    if (!_uiContext) {
      return px / PixelUtil.getDensity()
    }
    return _uiContext.px2vp(px)
  }

  /**
   * 虚拟像素(vp)转物理像素(px)
   * @param vp 虚拟像素值
   * @param uiContext 可选的UIContext，提供更精确的转换
   * @returns px值
   */
  static vp2px(vp: number, uiContext?: UIContext): number {
    const _uiContext = UIContextUtil.getEffectiveUIContext(uiContext)
    if (!_uiContext) {
      return vp * PixelUtil.getDensity()
    }
    return _uiContext.vp2px(vp)
  }

  /**
   * 将JPEG ArrayBuffer解码为PixelMap
   * 用于相机拍照后将JPEG数据转为可显示的PixelMap
   *
   * @param buffer JPEG格式的图片数据
   * @returns PixelMap对象，解码失败返回undefined
   */
  static async bufferToPixelMap(buffer: ArrayBuffer): Promise<image.PixelMap | undefined> {
    try {
      let imageSource: image.ImageSource = image.createImageSource(buffer)
      let pixelMap: image.PixelMap = await imageSource.createPixelMap()
      return pixelMap
    } catch (error) {
      return undefined
    }
  }

  /**
   * 释放PixelMap资源
   * PixelMap占用较多内存，使用完毕后必须主动释放
   *
   * @param pixelMap 待释放的PixelMap对象
   */
  static releasePixelMap(pixelMap: image.PixelMap | undefined): void {
    if (pixelMap) {
      pixelMap.release()
    }
  }
}
