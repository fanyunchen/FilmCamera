export class UIContextUtil {
  private static UIContext: UIContext | null = null

  static setUIContext(uiContext: UIContext): void {
    UIContextUtil.UIContext = uiContext
  }

  static getUIContext() {
    return UIContextUtil.UIContext
  }

  static getContext(): Context | undefined {
    return UIContextUtil.UIContext?.getHostContext()
  }

  /**
   * 获取有效的UIContext
   */
  static getEffectiveUIContext(ui?: UIContext) {
    const _ui = ui ?? UIContextUtil.getUIContext()
    if (!_ui || (!_ui.isAvailable && !_ui.isAvailable())) {
      return undefined
    }
    return _ui
  }
}

/**
 * 统一的动画方法
 * @param value AnimateParam
 * @param event () => void
 */
export function AnimateTo(value: AnimateParam, event: () => void, uiContext?: UIContext): void {
  const _animateTo = UIContextUtil.getEffectiveUIContext(uiContext)?.animateTo
  return _animateTo?.(value, event)
}