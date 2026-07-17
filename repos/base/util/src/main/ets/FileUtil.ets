import { StringUtil } from './common/StringUtil';
import { UIContextUtil } from './common/UIContextUtil';
import { fileIo, fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { URLUtils } from './common/URLUtils';
import { NetWorkUtils } from './NetWorkUtils';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';

export class FileUtil {
  static async saveButtonImage(context: Context, imageBuffer: ArrayBuffer | string): Promise<boolean> {
    let helper = photoAccessHelper.getPhotoAccessHelper(context)
    const extName = typeof imageBuffer === 'string' ? URLUtils.getFileExtensionFromUrl(imageBuffer) : ''

    try {
      let uri =
        await helper.createAsset(photoAccessHelper.PhotoType.IMAGE,
          StringUtil.isEmpty(extName) ? 'jpg' : extName.substring(1))

      let destFile = await fs.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)

      if (typeof imageBuffer === 'string') {
        let srcFile = fs.openSync(imageBuffer, fileIo.OpenMode.READ_ONLY)
        let stat = fs.statSync(srcFile.fd)
        let buf: ArrayBuffer = new ArrayBuffer(stat.size)
        fs.readSync(srcFile.fd, buf)
        fs.closeSync(srcFile.fd)
        fs.writeSync(destFile.fd, buf)
      } else {
        fs.writeSync(destFile.fd, imageBuffer)
      }

      fs.closeSync(destFile.fd)

      return true
    } catch (err) {
      console.error('saveButtonImage error-->', JSON.stringify(err))
      return false
    }
  }

  /**
   * 下载网络图片到本地
   * @param imageUrl 网络图片地址
   * @returns 下载到沙箱的地址
   */
  static async downloadNetWorkImage(imageUrl: string): Promise<string> {
    if (StringUtil.isEmpty(imageUrl)) {
      return ''
    }

    const cachePath = UIContextUtil.getContext()?.cacheDir

    if (StringUtil.isEmpty(cachePath)) {
      // 获取不到沙箱路径
      return ''
    }

    const dirPath = cachePath + '/download'

    try {
      // 判断是否有目录，没有则创建目录
      if (!fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath, true)
      }

      // 获取链接的扩展名
      const extName = URLUtils.getFileExtensionFromUrl(imageUrl)
      // 创建下载的目标地址
      const hash = StringUtil.sha256Sync(imageUrl)

      const targetPath = dirPath + "/" + hash + extName

      if (!fs.accessSync(targetPath)) {
        // 创建文件
        const fill = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
        fs.closeSync(fill)

        // 没东西则下载到缓存沙箱路径
        await NetWorkUtils.downloadFile(imageUrl, targetPath);
      }

      return fileUri.getUriFromPath(targetPath)
    } catch (err) {
      return ''
    }
  }
}