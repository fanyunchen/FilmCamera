import { WindowUtil } from '@hm/util';

@Entry
@Component
struct Index {
  @State cutoutBackgroundColor: string = '#000';
  @State cutoutAddHeight: number = 0
  @State cutoutAddWidth: number = 30
  @State isShowCutout: boolean = false
  private maxHeight: number = 350

  build() {
    Column() {
      Row()
        .margin({ top: WindowUtil.getCutoutTop(), left: WindowUtil.getCutoutLeft()! - this.cutoutAddWidth / 2 })
        .height(WindowUtil.getCutoutHeight()! + this.cutoutAddHeight)
        .width(WindowUtil.getCutoutWidth()! + this.cutoutAddWidth)
        .backgroundColor(this.cutoutBackgroundColor)
        .borderRadius(WindowUtil.getCutoutHeight())
        .visibility(this.isShowCutout ? Visibility.Visible : Visibility.Hidden)
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
          this.isShowCutout = true
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