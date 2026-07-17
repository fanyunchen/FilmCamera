import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 照片Buffer回调类型定义
 * 当相机拍照完成后，通过此回调将JPEG数据传递给调用方
 */
type PhotoBufferCallback = (buffer: ArrayBuffer) => void;

/**
 * 相机工具类
 * 封装HarmonyOS Camera Kit的核心功能，包括：
 * - 相机初始化（创建CameraManager、CameraInput、PreviewOutput、PhotoOutput、PhotoSession）
 * - 实时预览（通过XComponent的Surface承载预览流）
 * - 拍照（触发photoOutput.capture，通过photoAvailable回调获取JPEG数据）
 * - 资源释放（按正确顺序停止会话、释放输出流、关闭相机输入）
 *
 * 使用流程：
 * 1. setOnPhotoBufferReady() 设置拍照回调
 * 2. initCamera() 初始化相机（需传入Context和XComponent的surfaceId）
 * 3. takePhoto() 拍照
 * 4. releaseCamera() 释放资源
 *
 * 注意事项：
 * - initCamera内部会先调用releaseCamera确保旧资源被释放
 * - releaseCamera有防重入机制（isReleasing），避免并发释放导致死锁
 * - 拍照回调中会对buffer进行拷贝，避免底层buffer被回收后上层访问无效数据
 */
export class CameraUtil {
  /** 相机管理器，用于获取相机设备列表、创建输入/输出流和会话 */
  private cameraManager: camera.CameraManager | undefined = undefined;
  /** 相机输入流，对应物理摄像头设备 */
  private cameraInput: camera.CameraInput | undefined = undefined;
  /** 预览输出流，将画面渲染到XComponent的Surface上 */
  private previewOutput: camera.PreviewOutput | undefined = undefined;
  /** 拍照输出流，拍照时输出JPEG格式的照片数据 */
  private photoOutput: camera.PhotoOutput | undefined = undefined;
  /** 拍照会话，管理相机输入流、预览输出流和拍照输出流的绑定关系 */
  private session: camera.PhotoSession | undefined = undefined;
  /** 标记当前相机会话是否正在运行（预览流是否活跃） */
  private isSessionRunning: boolean = false;
  /** 拍照数据就绪回调，当photoAvailable触发时将JPEG buffer传递给调用方 */
  private onPhotoBufferReady: PhotoBufferCallback | undefined = undefined;
  /** 防重入标记，确保releaseCamera不会被并发调用，避免资源释放顺序混乱导致死锁 */
  private isReleasing: boolean = false;

  /**
   * 设置拍照数据就绪回调
   * @param callback 回调函数，参数为JPEG格式的ArrayBuffer
   */
  setOnPhotoBufferReady(callback: PhotoBufferCallback): void {
    this.onPhotoBufferReady = callback;
  }

  /**
   * 获取当前相机会话是否正在运行
   * @returns true表示预览流活跃，false表示已停止或未初始化
   */
  getIsSessionRunning(): boolean {
    return this.isSessionRunning;
  }

  /**
   * 初始化相机
   * 完整流程：释放旧资源 → 创建CameraManager → 获取相机设备 → 创建CameraInput并打开 →
   *           获取输出能力 → 创建PreviewOutput → 创建PhotoOutput → 创建PhotoSession →
   *           配置会话（addInput + addOutput） → 提交配置 → 启动会话
   *
   * @param context 应用上下文，用于获取CameraManager实例
   * @param surfaceId XComponent提供的Surface ID，预览流将渲染到此Surface上
   * @returns true初始化成功，false初始化失败
   */
  async initCamera(context: Context, surfaceId: string): Promise<boolean> {
    // 防止在释放过程中重新初始化
    if (this.isReleasing) {
      return false;
    }
    try {
      // 先释放旧的相机资源，确保干净的初始化环境
      await this.releaseCamera();

      // 1. 创建CameraManager实例
      this.cameraManager = camera.getCameraManager(context);
      if (!this.cameraManager) {
        return false;
      }

      // 2. 获取设备支持的相机列表（前置/后置摄像头）
      let cameras: Array<camera.CameraDevice> = this.cameraManager.getSupportedCameras();
      if (!cameras || cameras.length <= 0) {
        return false;
      }

      // 3. 使用第一个相机设备（通常为后置摄像头）
      let cameraDevice: camera.CameraDevice = cameras[0];
      this.cameraInput = this.cameraManager.createCameraInput(cameraDevice);
      if (!this.cameraInput) {
        return false;
      }
      // 打开相机设备，建立与硬件的连接
      await this.cameraInput.open();

      // 4. 获取该相机设备在NORMAL_PHOTO模式下的输出能力
      let outputCapability: camera.CameraOutputCapability =
        this.cameraManager.getSupportedOutputCapability(cameraDevice, camera.SceneMode.NORMAL_PHOTO);

      // 5. 创建预览输出流，绑定到XComponent的Surface
      let previewProfiles: Array<camera.Profile> = outputCapability.previewProfiles;
      if (!previewProfiles || previewProfiles.length === 0) {
        return false;
      }
      this.previewOutput = this.cameraManager.createPreviewOutput(previewProfiles[0], surfaceId);
      if (!this.previewOutput) {
        return false;
      }

      // 6. 创建拍照输出流，用于输出JPEG格式照片
      let photoProfiles: Array<camera.Profile> = outputCapability.photoProfiles;
      if (!photoProfiles || photoProfiles.length === 0) {
        return false;
      }
      this.photoOutput = this.cameraManager.createPhotoOutput(photoProfiles[0]);
      if (!this.photoOutput) {
        return false;
      }

      // 7. 注册拍照数据回调，当有照片数据可用时触发
      this.setPhotoOutputCb();

      // 8. 创建PhotoSession（普通拍照模式），统一管理输入和输出流
      this.session = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      if (!this.session) {
        return false;
      }

      // 9. 配置会话：添加输入流和输出流
      this.session.beginConfig();
      this.session.addInput(this.cameraInput);
      this.session.addOutput(this.previewOutput);
      this.session.addOutput(this.photoOutput);
      await this.session.commitConfig();

      // 10. 启动会话，预览流开始输出画面
      await this.session.start();
      this.isSessionRunning = true;
      return true;
    } catch (error) {
      let err = error as BusinessError;
      // 初始化失败时释放已创建的资源，避免资源泄漏
      await this.releaseCamera();
      return false;
    }
  }

  /**
   * 触发拍照
   * 调用后相机将捕获当前预览帧，通过photoAvailable回调异步返回JPEG数据
   *
   * @returns true拍照指令发送成功，false会话未运行或发送失败
   */
  async takePhoto(): Promise<boolean> {
    if (!this.photoOutput || !this.isSessionRunning) {
      return false;
    }
    try {
      let settings: camera.PhotoCaptureSetting = {
        quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
        rotation: camera.ImageRotation.ROTATION_0
      };
      this.photoOutput.capture(settings);
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * 注册拍照输出流的photoAvailable回调
   * 当拍照完成后，系统会通过此回调返回camera.Photo对象
   * 从中提取JPEG数据并拷贝到新的ArrayBuffer中，通过onPhotoBufferReady传递给调用方
   *
   * 重要：必须对buffer进行拷贝，因为底层buffer在回调结束后可能被系统回收，
   * 如果不拷贝，上层异步访问时可能得到空数据或导致崩溃
   */
  private setPhotoOutputCb(): void {
    this.photoOutput?.on('photoAvailable', (errCode: BusinessError, photo: camera.Photo): void => {
      if (errCode || !photo) {
        return;
      }
      let imageObj: image.Image = photo.main;
      // 从Image对象中获取JPEG格式的组件数据
      imageObj.getComponent(image.ComponentType.JPEG, (errCode: BusinessError, component: image.Component) => {
        if (errCode || !component) {
          imageObj.release();
          return;
        }
        let buffer: ArrayBuffer = component.byteBuffer;
        if (!buffer) {
          imageObj.release();
          return;
        }
        // 拷贝buffer到新的ArrayBuffer，避免底层buffer被回收
        let copiedBuffer: ArrayBuffer = new ArrayBuffer(buffer.byteLength);
        let srcView: Uint8Array = new Uint8Array(buffer);
        let dstView: Uint8Array = new Uint8Array(copiedBuffer);
        for (let i = 0; i < srcView.length; i++) {
          dstView[i] = srcView[i];
        }
        // 通过回调将拷贝后的buffer传递给调用方
        if (this.onPhotoBufferReady) {
          this.onPhotoBufferReady(copiedBuffer);
        }
        // 释放Image对象，必须调用否则后续拍照无法获取buffer
        imageObj.release();
      });
    });
  }

  /**
   * 释放所有相机资源
   * 按照正确的顺序释放：停止会话 → 释放会话 → 释放预览输出流 →
   *                取消回调注册并释放拍照输出流 → 关闭相机输入流
   *
   * 每个步骤独立try-catch，确保某一步失败不影响后续步骤的执行
   * 使用isReleasing防重入标记，避免并发调用导致资源释放顺序混乱
   */
  async releaseCamera(): Promise<void> {
    if (this.isReleasing) {
      return;
    }
    this.isReleasing = true;
    this.isSessionRunning = false;
    try {
      // 1. 停止并释放PhotoSession
      if (this.session) {
        try {
          await this.session.stop();
        } catch (e) {
        }
        try {
          await this.session.release();
        } catch (e) {
        }
        this.session = undefined;
      }
      // 2. 释放预览输出流
      if (this.previewOutput) {
        try {
          await this.previewOutput.release();
        } catch (e) {
        }
        this.previewOutput = undefined;
      }
      // 3. 取消拍照回调注册并释放拍照输出流
      if (this.photoOutput) {
        try {
          this.photoOutput.off('photoAvailable');
        } catch (e) {
        }
        try {
          await this.photoOutput.release();
        } catch (e) {
        }
        this.photoOutput = undefined;
      }
      // 4. 关闭相机输入流（释放物理摄像头硬件连接）
      if (this.cameraInput) {
        try {
          await this.cameraInput.close();
        } catch (e) {
        }
        this.cameraInput = undefined;
      }
    } catch (error) {
    }
    this.isReleasing = false;
  }
}
