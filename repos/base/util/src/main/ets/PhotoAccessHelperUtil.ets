import { FileUtil } from './FileUtil';
import { common } from '@kit.AbilityKit';

/**
 * 相册访问辅助工具类
 * 封装图片保存到系统相册的常用操作
 */
export class PhotoAccessHelperUtil {
  /**
   * 通过安全控件授权保存图片到系统相册
   * 需在SaveButton的onClick回调中调用，依赖安全控件临时授权
   *
   * @param context UIAbilityContext上下文
   * @param imageBuffer JPEG格式的图片数据（不能是@State代理的ArrayBuffer）
   * @returns true保存成功，false保存失败
   */
  static async saveImageToGallery(context: common.UIAbilityContext, imageBuffer: ArrayBuffer): Promise<boolean> {
    if (!imageBuffer) {
      return false
    }
    try {
      return await FileUtil.saveButtonImage(context, imageBuffer)
    } catch (error) {
      return false
    }
  }
}
