import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

/**
 * 字符串工具类
 */
export class StringUtil {
  /**
   * 判断字符串是否为空
   * @param str 待检查字符串
   * @returns true为空
   */
  static isEmpty(str?: string): boolean {
    return str?.length === 0 || str === undefined || str === null
  }

  /**
   * 判断字符串是否不为空
   * @param str 待检查字符串
   * @returns true不为空
   */
  static isNotEmpty(str?: string): boolean {
    return StringUtil.isEmpty(str)
  }

  /**
   * 将字符串进行SHA-256哈希计算
   *
   * @param str 待哈希的字符串
   * @returns SHA-256哈希后的十六进制字符串
   */
  static sha256Sync(str: string) {
    let mdAlgName = 'SHA256';
    let message = str;
    let md = cryptoFramework.createMd(mdAlgName);
    // 数据量较少时可以只做一次update，将数据全部传入
    md.updateSync({ data: new Uint8Array(buffer.from(message, 'utf-8').buffer) });
    let mdResult = md.digestSync();
    let resultString = buffer.from(mdResult.data).toString('hex');
    return resultString;
  }
}
