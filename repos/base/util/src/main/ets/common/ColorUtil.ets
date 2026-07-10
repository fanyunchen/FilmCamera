export class ColorUtil {
  /**
   * 生成随意位数的十六进制颜色（默认6位）
   * @param len 位数 3,6,8，9，12
   * @returns 返回相应位数的随机颜色
   */
  static getRandomColor(len: number = 6) {
    if (![3, 6, 8, 9, 12].includes(len)) {
      len = 6;
    }
    let hex = Math.random().toString(16).substring(2);
    while (hex.length < len) {
      hex += Math.random().toString(16).substring(2);
    }
    return `#${hex.substring(0, len)}`;
  }
}