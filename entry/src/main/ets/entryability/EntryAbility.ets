import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { EntryUtil } from '../util/EntryUtil';

/** 日志打印的域标识 */
const DOMAIN = 0x0000;

/**
 * 应用主Ability
 * 作为应用的入口UIAbility，负责：
 * - 加载主页面（pages/Index）
 * - 初始化沉浸式全屏模式
 * - 管理应用生命周期
 */
export default class EntryAbility extends UIAbility {
  /** Ability创建时回调，设置颜色模式 */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  /** Ability销毁时回调 */
  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /**
   * 窗口阶段创建时回调
   * 1. 加载主页面
   * 2. 获取主窗口并初始化沉浸式全屏模式（读取避让区信息、注册监听）
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 加载主页面
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    // 获取主窗口并初始化沉浸式全屏模式
    windowStage.getMainWindow().then(window => {
      EntryUtil.setWindowLayoutFullScreen(window)
    })
  }

  /** 窗口阶段销毁时回调 */
  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  /** Ability切到前台时回调 */
  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  /** Ability切到后台时回调 */
  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
