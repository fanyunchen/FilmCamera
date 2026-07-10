import { ColorUtil, WindowUtil } from '@hm/util';

@Entry
@Component
struct Index {
  @State cutoutBackgroundColor: string = '#000';
  @State cutoutAddHeight: number = 0
  @State cutoutAddWidth: number = 30
  @State isShowCutout: boolean = false
  @State columns: number = 3
  private maxHeight: number = 350
  private mock: string[] = ['1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1']

  build() {
    Column() {
      // 灵动岛部分
      Row()
        .margin({ top: WindowUtil.getCutoutTop(), left: WindowUtil.getCutoutLeft()! - this.cutoutAddWidth / 2 })
        .height(WindowUtil.getCutoutHeight()! + this.cutoutAddHeight)
        .width(WindowUtil.getCutoutWidth()! + this.cutoutAddWidth)
        .backgroundColor(this.cutoutBackgroundColor)
        .borderRadius(WindowUtil.getCutoutHeight())
        .visibility(this.isShowCutout ? Visibility.Visible : Visibility.Hidden)

      // 相册部分
      Grid() {
        ForEach(this.mock, (item: string, index) => {
          GridItem() {
            Text(index.toString())
          }
          .width(90)
          .aspectRatio(1)
          .border({ width: 1, color: ColorUtil.getRandomColor() })
        })
      }
      .margin({ top: WindowUtil.getTopRectHeight() })
      .columnsTemplate('1fr '.repeat(this.columns))
      .columnsGap(10)
      .padding({ left: 20, right: 20 })
      .rowsGap(10)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .cachedCount(3)
      // 切换列数item位置重排动画
      .animation({
        duration: 300,
        curve: Curve.Smooth
      })
      .priorityGesture(
        PinchGesture()
          .onActionEnd((event: GestureEvent) => {
            // 手指分开，减少列数以放大Item
            let _columns = this.columns
            if (event.scale > 2) {
              _columns--;
            } else if (event.scale < 0.6) {
              _columns++;
            }
            // 此处以最小3列最大6列为例
            this.columns = Math.min(6, Math.max(3, _columns));
          })
      )
    }
    .alignItems(HorizontalAlign.Start)
    .height('100%')
    .width('100%')
    .onClick(() => {
      if (this.cutoutAddHeight >= this.maxHeight) {
        this.getUIContext().animateTo({ duration: 300 }, () => {
          this.cutoutAddHeight = 0
          this.cutoutAddWidth = 30
          this.isShowCutout = false
        })
      }
    })
    .gesture(
      PanGesture({ fingers: 1, direction: PanDirection.Down })
        .onActionStart(() => {
          this.getUIContext().animateTo({ duration: 300 }, () => {
            this.isShowCutout = true
          })
        })
        .onActionUpdate(event => {
          const targetHeight = Math.min(Math.max(event.offsetY, 0), this.maxHeight)
          const progress = targetHeight / this.maxHeight
          const cutoutHeight = WindowUtil.getCutoutHeight()!
          const cutoutWidth = WindowUtil.getCutoutWidth()!
          const finalWidth = (cutoutHeight + this.maxHeight) * 0.9
          const finalAddWidth = Math.max(finalWidth - cutoutWidth, 30)
          this.cutoutAddHeight = targetHeight
          this.cutoutAddWidth = 30 + (finalAddWidth - 30) * progress
        })
        .onActionEnd(() => {
          if (this.cutoutAddHeight < this.maxHeight) {
            this.getUIContext().animateTo({ duration: 300 }, () => {
              this.cutoutAddHeight = 0
              this.cutoutAddWidth = 30
              this.isShowCutout = false
            })
          }
        }))
  }
}