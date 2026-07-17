/**
 * 颜色工具类
 */
export class ColorUtil {
  /**
   * 生成随机十六进制颜色字符串
   * @param len 颜色位数，支持3/6/8/9/12位，默认6位（如#FF00AA）
   * @returns 带#前缀的十六进制颜色字符串
   */
  static getRandomColor(len: number = 6) {
    if (![3, 6, 8, 9, 12].includes(len)) {
      len = 6;
    }
    let hex = Math.random().toString(16).substring(2);
    // 位数不足时补充随机字符
    while (hex.length < len) {
      hex += Math.random().toString(16).substring(2);
    }
    return `#${hex.substring(0, len)}`;
  }
}
