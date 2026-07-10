import { display } from '@kit.ArkUI';
import { UIContextUtil } from './UIContextUtil';

export class PixelUtil {
  static getDensity() {
    // 获取屏幕密度计算
    let displayClass = display.getDefaultDisplaySync();
    let density = displayClass.densityPixels;
    return density;
  }

  static px2vp(px: number, uiContext?: UIContext): number {
    const _uiContext = UIContextUtil.getEffectiveUIContext(uiContext)
    if (!_uiContext) {
      return px / PixelUtil.getDensity()
    }
    return _uiContext.px2vp(px)
  }

  static vp2px(vp: number, uiContext?: UIContext): number {
    const _uiContext = UIContextUtil.getEffectiveUIContext(uiContext)
    if (!_uiContext) {
      return vp * PixelUtil.getDensity()
    }
    return _uiContext.vp2px(vp)
  }
}