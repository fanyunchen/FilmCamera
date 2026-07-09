export class UIContextUtil {
  static UIContext: UIContext

  static px2vp(px: number): number {
    return UIContextUtil.UIContext.px2vp(px)
  }

  static vp2px(vp: number): number {
    return UIContextUtil.UIContext.vp2px(vp)
  }

  static getContext(): Context | undefined {
    return UIContextUtil.UIContext.getHostContext()
  }
}