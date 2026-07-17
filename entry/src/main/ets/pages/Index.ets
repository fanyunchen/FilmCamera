import {
  CameraUtil,
  ColorUtil,
  PhotoAccessHelperUtil,
  PixelUtil,
  RequestPermissionsUtil,
  WindowUtil
} from '@hm/util';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';

/**
 * 胶片相机应用主页面
 *
 * 核心功能：
 * 1. 灵动岛相机：下拉手势展开灵动岛区域，内嵌XComponent承载相机实时预览流
 * 2. 拍照与预览：点击拍照按钮捕获当前帧，灵动岛内切换显示拍摄的照片缩略图
 * 3. 保存/删除：拍照后提供"保存至图库"和"删除"两个操作按钮
 * 4. 照片画廊：下方Grid展示模拟照片列表，支持PinchGesture缩放切换列数
 *
 * 灵动岛交互流程：
 *   下拉 → 灵动岛展开 → 相机启动实时预览 → 点击拍照 → 显示拍摄照片 + 操作按钮
 *                                                              ├─ 删除 → 恢复实时预览
 *                                                              └─ 保存 → 保存到相册 → 恢复实时预览
 *   点击空白区域 → 灵动岛收起 → 相机资源释放
 *
 * 前后台切换处理：
 *   切后台(onPageHide) → 释放相机资源
 *   切前台(onPageShow) → 重新初始化相机恢复预览
 */
@Entry
@Component
struct Index {
  /** 灵动岛背景颜色 */
  @State cutoutBackgroundColor: string = '#000'
  /** 灵动岛额外增加的高度（下拉展开时递增，最大maxHeight） */
  @State cutoutAddHeight: number = 0
  /** 灵动岛额外增加的宽度（展开时按比例递增） */
  @State cutoutAddWidth: number = 30
  /** 灵动岛是否可见（下拉手势开始时为true，收起时为false） */
  @State isShowCutout: boolean = false
  /** 照片画廊Grid的列数（3-6列，通过PinchGesture调节） */
  @State columns: number = 3
  /** 相机是否已就绪（初始化完成且预览流活跃） */
  @State isCameraReady: boolean = false
  /** 拍摄照片的PixelMap对象（用于在灵动岛内显示照片预览，叠加在XComponent上方） */
  @State capturedPixelMap: image.PixelMap | undefined = undefined
  /** 待保存的JPEG照片Buffer（拍照后从CameraUtil回调获取，不用@State避免ArrayBuffer被代理导致fs.writeSync报13900020） */
  private pendingPhotoBuffer: ArrayBuffer | undefined = undefined
  /** 灵动岛最大展开高度（vp），下拉手势展开时cutoutAddHeight的上限 */
  private maxHeight: number = 350
  /** 触摸起始Y坐标，用于判断是否为下拉手势 */
  private touchStartY: number = 0
  /** 标记当前是否正在下拉（用于手势冲突判断） */
  private isPullingDown: boolean = false
  /** 照片画廊的滚动控制器 */
  private scroller: Scroller = new Scroller()
  /** 模拟照片数据源 */
  private mock: string[] = ['1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1']
  /** XComponent控制器，用于获取Surface ID */
  private mXComponentController: XComponentController = new XComponentController()
  /** 相机工具类实例，封装了相机初始化、拍照、释放等功能 */
  private cameraUtil: CameraUtil = new CameraUtil()
  /** XComponent的Surface ID，相机预览流通过此ID绑定到XComponent */
  private surfaceId: string = ''
  /** 页面是否可见（用于前后台切换判断，切后台时不重新初始化相机） */
  private isPageVisible: boolean = true

  /**
   * 组件即将挂载时的初始化
   * - 生成模拟照片数据
   * - 注册拍照数据回调：拍照完成后将JPEG buffer转为PixelMap并更新状态
   */
  aboutToAppear(): void {
    for (let i = 0; i <= 20; i++) {
      this.mock.push(i.toString())
    }
    this.cameraUtil.setOnPhotoBufferReady((buffer: ArrayBuffer) => {
      this.onPhotoCaptured(buffer)
    })
  }

  /**
   * 组件即将销毁时释放所有资源
   * - 释放相机硬件资源
   * - 释放PixelMap内存
   */
  aboutToDisappear(): void {
    this.cameraUtil.releaseCamera()
    this.releasePixelMap()
  }

  /**
   * 页面重新显示（从后台切回前台时触发）
   * 如果灵动岛处于展开状态且没有拍摄照片待处理，则重新初始化相机恢复预览
   * 注意：切后台时系统会强制回收相机资源，必须重新初始化
   */
  onPageShow(): void {
    this.isPageVisible = true
    if (this.isShowCutout && this.surfaceId && !this.capturedPixelMap) {
      this.reinitCamera()
    }
  }

  /**
   * 页面隐藏（切到后台时触发）
   * 主动释放相机资源，避免被系统强制断流导致后续状态不一致
   */
  onPageHide(): void {
    this.isPageVisible = false
    if (this.cameraUtil.getIsSessionRunning()) {
      this.cameraUtil.releaseCamera()
      this.isCameraReady = false
    }
  }

  build() {
    Column() {
      // ========== 灵动岛区域 ==========
      // 使用Stack叠加：XComponent（始终挂载，承载相机预览流）+ 照片Image（拍照后叠加显示）+ 操作按钮
      Stack() {
        // XComponent始终挂载，避免条件渲染导致销毁重建引发黑屏
        // 相机预览流绑定到此Surface，即使被照片Image遮挡也持续运行
        XComponent({
          id: 'cameraXComponent',
          type: XComponentType.SURFACE,
          controller: this.mXComponentController
        })
          .onLoad(async () => {
            // 获取Surface ID，相机预览流通过此ID绑定到XComponent
            this.surfaceId = this.mXComponentController.getXComponentSurfaceId()
            if (!this.isPageVisible || !this.surfaceId) {
              return
            }
            let context = this.getUIContext().getHostContext()
            if (!context) {
              return
            }
            let hasPermission = RequestPermissionsUtil.checkPermissionGrantSync('ohos.permission.CAMERA')
            if (!hasPermission) {
              RequestPermissionsUtil.reqPermissionsFromUser('ohos.permission.CAMERA', context)
              return
            }
            let result = await this.cameraUtil.initCamera(context, this.surfaceId)
            this.isCameraReady = result
          })
          .width('100%')
          .height('100%')

        // 拍照后叠加显示拍摄的照片，覆盖在XComponent预览流上方
        // 删除或保存后capturedPixelMap被清除，自动恢复显示XComponent的预览画面
        if (this.capturedPixelMap) {
          Image(this.capturedPixelMap)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }

        // 灵动岛完全展开时的操作按钮区域
        if ((this.isCameraReady || this.capturedPixelMap) && this.cutoutAddHeight >= this.maxHeight) {
          Row({ space: 16 }) {
            if (this.capturedPixelMap) {
              // ---- 拍照后模式：显示删除按钮 + 保存按钮 ----
              // 删除按钮：丢弃照片，恢复实时预览
              Button({ type: ButtonType.Circle }) {
                Image($r('sys.media.ohos_ic_public_cancel'))
                  .width(24)
                  .height(24)
                  .fillColor(Color.White)
              }
              .width(44)
              .height(44)
              .backgroundColor(Color.Red)
              .onClick(() => {
                this.discardPhoto()
              })

              // 保存按钮：SaveButton安全控件
              // 用户点击后系统授予临时写入相册权限（10秒内有效）
              // 必须在授权窗口内完成createAsset + writeSync操作
              SaveButton({
                icon: SaveIconStyle.FULL_FILLED,
                text: SaveDescription.SAVE_TO_GALLERY,
                buttonType: ButtonType.Capsule
              })
                .padding({
                  top: 6,
                  bottom: 6,
                  left: 12,
                  right: 12
                })
                .backgroundColor(Color.Black)
                .fontColor(Color.White)
                .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                  if (result === SaveButtonOnClickResult.SUCCESS) {
                    this.savePhotoToGallery()
                  } else {
                    this.getUIContext().getPromptAction().showToast({ message: '保存权限未授予' })
                  }
                })
            } else {
              // ---- 实时预览模式：显示拍照按钮 ----
              Button({ type: ButtonType.Circle }) {
                Image($r('sys.media.ohos_ic_public_camera'))
                  .width(24)
                  .height(24)
                  .fillColor(Color.White)
              }
              .width(44)
              .height(44)
              .backgroundColor(Color.Black)
              .onClick(() => {
                this.cameraUtil.takePhoto()
              })
            }
          }
          .position({ x: '50%', y: '100%' })
          .translate({ x: '-50%', y: -56 })
        }
      }
      // 灵动岛定位与样式：根据系统挖孔屏参数定位，展开时按动态宽高显示
      .margin({ top: WindowUtil.getCutoutTop(), left: WindowUtil.getCutoutLeft()! - this.cutoutAddWidth / 2 })
      .height(WindowUtil.getCutoutHeight()! + this.cutoutAddHeight)
      .width(WindowUtil.getCutoutWidth()! + this.cutoutAddWidth)
      .backgroundColor(this.cutoutBackgroundColor)
      .borderRadius(WindowUtil.getCutoutHeight())
      .visibility(this.isShowCutout ? Visibility.Visible : Visibility.Hidden)
      .zIndex(999)
      .clip(true) // 裁剪超出圆角区域的内容，确保相机预览和照片不溢出灵动岛

      // ========== 照片画廊区域 ==========
      Grid(this.scroller) {
        ForEach(this.mock, (item: string, index) => {
          GridItem() {
            Text(index.toString())
          }
          .width(90)
          .aspectRatio(1)
          .border({ width: 1, color: ColorUtil.getRandomColor() })
        })
      }
      .columnsTemplate('1fr '.repeat(this.columns))
      .columnsGap(10)
      .padding({
        left: 20,
        right: 20,
        top: 15,
        bottom: WindowUtil.getBottomRectHeight()
      })
      // 嵌套滚动：向上滚动时自身先滚，向下滚动时自身先滚到底再触发外层
      .nestedScroll({ scrollBackward: NestedScrollMode.SELF_FIRST, scrollForward: NestedScrollMode.SELF_ONLY })
      .rowsGap(10)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .cachedCount(3)
      // 列数切换时item位置重排动画
      .animation({
        duration: 300,
        curve: Curve.Smooth
      })
      .edgeEffect(EdgeEffect.Spring)
      // 触摸事件：记录起始Y坐标和下拉方向，用于手势冲突判断
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down && event.touches.length > 0) {
          this.touchStartY = event.touches[0].windowY
          this.isPullingDown = false
        } else if (event.type === TouchType.Move && event.touches.length > 0) {
          this.isPullingDown =
            event.touches[0].windowY - this.touchStartY > 2
        } else if (event.type === TouchType.Up ||
          event.type === TouchType.Cancel) {
          this.isPullingDown = false
        }
      })
      // 手势冲突仲裁：当Grid滚动到顶部且用户正在下拉时，拒绝Grid的PanGesture
      // 让外层的下拉手势（展开灵动岛）得以触发
      .onGestureRecognizerJudgeBegin((event, current) => {
        const isPan = current.getType() ===
          GestureControl.GestureType.PAN_GESTURE
        const isAtTop = this.scroller.currentOffset().yOffset <= 0.5

        if (isPan && isAtTop && this.isPullingDown) {
          return GestureJudgeResult.REJECT
        }

        return GestureJudgeResult.CONTINUE
      })
      // PinchGesture：双指捏合缩放调节列数
      // 手指分开 → 减少列数（放大Item） / 手指合拢 → 增加列数（缩小Item）
      .priorityGesture(
        PinchGesture()
          .onActionEnd((event: GestureEvent) => {
            let _columns = this.columns
            if (event.scale > 2) {
              _columns--;
            } else if (event.scale < 0.6) {
              _columns++;
            }
            // 限制列数范围3-6列
            this.columns = Math.min(6, Math.max(3, _columns));
          })
      )

    }
    .alignItems(HorizontalAlign.Start)
    .height('100%')
    .width('100%')
    // 点击空白区域收起灵动岛（仅当灵动岛完全展开时生效）
    .onClick(() => {
      if (this.cutoutAddHeight >= this.maxHeight) {
        this.closeCutout()
      }
    })
    // 全局手势仲裁：检查相机权限，未授权时拒绝所有手势并提示
    .onGestureRecognizerJudgeBegin(() => {
      const checkRes = RequestPermissionsUtil.checkPermissionGrantSync('ohos.permission.CAMERA')
      if (checkRes) {
        return GestureJudgeResult.CONTINUE
      }
      const context = this.getUIContext().getHostContext()
      if (!context) {
        this.getUIContext().getPromptAction().showToast({ message: '请打开相机权限使用' })
        return GestureJudgeResult.REJECT
      }
      if (RequestPermissionsUtil.reqPermissionsFromUser('ohos.permission.CAMERA', context)) {
        return GestureJudgeResult.CONTINUE
      }
      this.getUIContext().getPromptAction().showToast({ message: '请打开相机权限使用' })
      return GestureJudgeResult.REJECT
    })
    // 下拉手势：展开灵动岛
    // onActionStart → 显示灵动岛
    // onActionUpdate → 根据偏移量动态调整灵动岛高度和宽度
    // onActionEnd → 判断展开程度，未达到maxHeight则收起，达到则保持展开并初始化相机
    .gesture(
      PanGesture({ fingers: 1, direction: PanDirection.Down })
        .onActionStart(() => {
          this.getUIContext().animateTo({ duration: 300 }, () => {
            this.isShowCutout = true
          })
        })
        .onActionUpdate(event => {
          if (this.cutoutAddHeight !== this.maxHeight) {
            // 计算下拉偏移量，限制在0到maxHeight之间
            const targetHeight = Math.min(Math.max(event.offsetY, 0), this.maxHeight)
            // 根据展开进度计算宽度增量
            const progress = targetHeight / this.maxHeight
            const cutoutHeight = WindowUtil.getCutoutHeight()!
            const cutoutWidth = WindowUtil.getCutoutWidth()!
            // 最终展开宽度为（挖孔高度 + 最大展开高度）* 0.9
            const finalWidth = (cutoutHeight + this.maxHeight) * 0.9
            const finalAddWidth = Math.max(finalWidth - cutoutWidth, 30)
            this.cutoutAddHeight = targetHeight
            // 宽度从30按进度递增到finalAddWidth
            this.cutoutAddWidth = 30 + (finalAddWidth - 30) * progress
          }
        })
        .onActionEnd(async () => {
          if (this.cutoutAddHeight < this.maxHeight) {
            // 下拉未达到最大高度，动画收起灵动岛
            this.getUIContext().animateTo({ duration: 300 }, () => {
              this.cutoutAddHeight = 0
              this.cutoutAddWidth = 30
              this.isShowCutout = false
              this.isCameraReady = false
              this.pendingPhotoBuffer = undefined
            })
            this.releasePixelMap()
            await this.cameraUtil.releaseCamera()
          } else {
            // 下拉达到最大高度，保持展开，若相机未运行则初始化
            if (this.surfaceId && !this.cameraUtil.getIsSessionRunning() && !this.capturedPixelMap) {
              this.reinitCamera()
            }
          }
        }))
  }

  /**
   * 拍照完成回调处理
   * 将JPEG buffer解码为PixelMap用于照片预览显示
   * XComponent始终挂载，照片Image叠加在XComponent上方，删除照片后移除Image即可恢复预览
   *
   * @param buffer JPEG格式的照片数据
   */
  private async onPhotoCaptured(buffer: ArrayBuffer): Promise<void> {
    this.pendingPhotoBuffer = buffer
    let pixelMap = await PixelUtil.bufferToPixelMap(buffer)
    if (pixelMap) {
      this.capturedPixelMap = pixelMap
    }
  }

  /**
   * 释放PixelMap资源
   * PixelMap占用较多内存，使用完毕后必须主动释放
   */
  private releasePixelMap(): void {
    PixelUtil.releasePixelMap(this.capturedPixelMap)
    this.capturedPixelMap = undefined
  }

  /**
   * 重新初始化相机
   * 用于从照片预览模式恢复到实时预览模式，或前后台切换后恢复预览
   * 先释放旧资源再重新创建完整的相机链路
   */
  private async reinitCamera(): Promise<void> {
    let context = this.getUIContext().getHostContext()
    if (!context || !this.surfaceId) {
      return
    }
    let hasPermission = RequestPermissionsUtil.checkPermissionGrantSync('ohos.permission.CAMERA')
    if (!hasPermission) {
      return
    }
    let result = await this.cameraUtil.initCamera(context, this.surfaceId)
    this.isCameraReady = result
  }

  /**
   * 保存照片到系统相册
   * 使用SaveButton安全控件获取临时写入授权，在授权窗口内通过同步写入确保操作完成
   */
  private async savePhotoToGallery(): Promise<void> {
    if (!this.pendingPhotoBuffer) {
      return
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext
    if (!context) {
      return
    }
    const res = await PhotoAccessHelperUtil.saveImageToGallery(context, this.pendingPhotoBuffer)
    if (res) {
      this.pendingPhotoBuffer = undefined
      this.getUIContext().getPromptAction().showToast({ message: '照片已保存' })
      this.discardPhoto()
    } else {
      this.getUIContext().getPromptAction().showToast({ message: '保存失败' })
    }
  }

  /**
   * 丢弃拍摄的照片，恢复相机实时预览
   * 释放PixelMap内存 → 清空buffer → 重新初始化相机
   * 由于XComponent始终挂载，移除照片Image后预览流自动可见
   */
  private async discardPhoto(): Promise<void> {
    this.releasePixelMap()
    this.pendingPhotoBuffer = undefined
    // 如果session还在运行，无需重新初始化，直接恢复预览
    if (this.cameraUtil.getIsSessionRunning()) {
      return
    }
    // session已停止（如前后台切换后），需要重新初始化
    if (this.isShowCutout && this.surfaceId && this.isPageVisible) {
      await this.reinitCamera()
    }
  }

  /**
   * 收起灵动岛
   * 动画收起 → 释放PixelMap → 释放相机资源
   */
  private async closeCutout(): Promise<void> {
    this.getUIContext().animateTo({ duration: 300 }, () => {
      this.cutoutAddHeight = 0
      this.cutoutAddWidth = 30
      this.isShowCutout = false
      this.isCameraReady = false
      this.pendingPhotoBuffer = undefined
    })
    this.releasePixelMap()
    await this.cameraUtil.releaseCamera()
  }
}
