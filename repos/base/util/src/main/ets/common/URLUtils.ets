import { StringUtil } from './StringUtil';

export class URLUtils {
  /**
   * 获取路径的后缀名
   * @param str 路径
   * @returns 后缀名
   *
   * 普通 URL：https://example.com/image.jpg → .jpg
   * 查询参数：image.png?width=100 → .png
   * URL 片段：image.webp#preview → .webp
   * 多个点：photo.origin.jpeg → .jpeg
   * 空字符串、无扩展名、隐藏文件、尾随点 → ''
   */
  static getFileExtensionFromUrl(str: string): string {
    if (StringUtil.isEmpty(str)) {
      return ''
    }

    const queryIndex = str.indexOf('?')
    const fragmentIndex = str.indexOf('#')
    let pathEnd = str.length
    if (queryIndex >= 0) {
      pathEnd = queryIndex
    }
    if (fragmentIndex >= 0 && fragmentIndex < pathEnd) {
      pathEnd = fragmentIndex
    }

    const path = str.substring(0, pathEnd)
    const fileName = path.substring(path.lastIndexOf('/') + 1)
    const dotIndex = fileName.lastIndexOf('.')
    if (dotIndex <= 0 || dotIndex === fileName.length - 1) {
      return ''
    }

    return fileName.substring(dotIndex)
  }
}
