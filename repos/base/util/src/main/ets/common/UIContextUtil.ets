/**
 * UIContext工具类
 * 全局管理UIContext实例，供其他工具类使用UIContext提供的各种能力
 * 如px/vp转换、animateTo动画、getPromptAction提示等
 *
 * 使用方式：
 * - 在EntryAbility初始化时调用setUIContext保存UIContext
 * - 其他工具类通过getUIContext()或getEffectiveUIContext()获取
 */
export class UIContextUtil {
  /** 全局UIContext实例 */
  private static UIContext: UIContext | null = null

  /**
   * 保存UIContext实例（在Ability初始化时调用）
   * @param uiContext 主窗口的UIContext
   */
  static setUIContext(uiContext: UIContext): void {
    UIContextUtil.UIContext = uiContext
  }

  /**
   * 获取全局UIContext实例
   * @returns UIContext或null
   */
  static getUIContext() {
    return UIContextUtil.UIContext
  }

  /**
   * 获取应用上下文（从UIContext中获取HostContext）
   * @returns Context或undefined
   */
  static getContext(): Context | undefined {
    return UIContextUtil.UIContext?.getHostContext()
  }

  /**
   * 获取有效的UIContext
   * 优先使用传入的ui参数，不可用时回退到全局UIContext
   * 同时检查UIContext是否可用（isAvailable）
   *
   * @param ui 可选的UIContext参数，优先使用
   * @returns 可用的UIContext或undefined
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
 * 统一的动画执行方法
 * 封装UIContext.animateTo，提供全局可用的动画能力
 *
 * @param value 动画参数（时长、曲线等）
 * @param event 动画回调（在此闭包中修改@State变量会触发动画过渡）
 * @param uiContext 可选的UIContext，不传时使用全局实例
 */
export function AnimateTo(value: AnimateParam, event: () => void, uiContext?: UIContext): void {
  const _animateTo = UIContextUtil.getEffectiveUIContext(uiContext)?.animateTo
  return _animateTo?.(value, event)
}
