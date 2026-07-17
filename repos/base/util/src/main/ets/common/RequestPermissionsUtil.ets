import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';

/**
 * 权限请求工具类
 * 封装HarmonyOS权限检查和申请的常用操作
 * 支持同步/异步检查权限状态，以及向用户弹窗申请权限
 */
export class RequestPermissionsUtil {
  /** 访问控制管理器实例，用于检查和请求权限 */
  private static atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

  /**
   * 同步检查权限是否已被授予
   * @param permission 要检查的权限名称（如'ohos.permission.CAMERA'）
   * @returns true已授权，false未授权
   */
  static checkPermissionGrantSync(permission: Permissions): boolean {
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用的accessTokenID，用于权限状态查询
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
    }

    // 查询该token对指定权限的授权状态
    try {
      grantStatus = RequestPermissionsUtil.atManager.checkAccessTokenSync(tokenId, permission);
    } catch (error) {
    }

    return RequestPermissionsUtil.isGranted(grantStatus)
  }

  /**
   * 异步检查权限是否已被授予
   * @param permission 要检查的权限名称
   * @returns Promise<boolean> true已授权，false未授权
   */
  static async checkPermissionGrant(permission: Permissions): Promise<boolean> {
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
    }

    try {
      grantStatus = await RequestPermissionsUtil.atManager.checkAccessToken(tokenId, permission);
    } catch (error) {
    }

    return RequestPermissionsUtil.isGranted(grantStatus)
  }

  /**
   * 向用户弹窗申请权限
   * 如果用户拒绝，可选择是否跳转到系统设置页面手动授权
   *
   * @param permissions 要申请的权限名称
   * @param context 应用上下文
   * @param isOpenSetting 用户拒绝后是否自动跳转设置页，默认true
   * @returns true授权成功（注意：异步操作，返回值可能不准确）
   */
  static reqPermissionsFromUser(permissions: Permissions, context: Context, isOpenSetting: boolean = true): boolean {
    let res = false
    RequestPermissionsUtil.atManager.requestPermissionsFromUser(context, [permissions]).then((data) => {
      let grantStatus: number[] = data.authResults;
      if (grantStatus[0] === 0) {
        res = true
      } else {
        // 用户拒绝授权，尝试跳转设置页
        res = isOpenSetting ? RequestPermissionsUtil.requestPermissionOnSetting(context, permissions) : false
      }
    })

    return res
  }

  /**
   * 跳转到系统设置页申请权限
   * 当用户在弹窗中拒绝授权后，可引导用户到设置页手动开启
   *
   * @param context 应用上下文
   * @param permissions 要申请的权限名称
   * @returns true授权成功
   */
  static requestPermissionOnSetting(context: Context, permissions: Permissions): boolean {
    let res = false
    RequestPermissionsUtil.atManager.requestPermissionOnSetting(context, [permissions]).then(data => {
      res = RequestPermissionsUtil.isGranted(data[0])
    })
    return res
  }

  /**
   * 判断授权状态是否为"已授权"
   * @param state 权限授权状态枚举值
   * @returns true已授权
   */
  private static isGranted(state: abilityAccessCtrl.GrantStatus): boolean {
    return state === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
  }
}
