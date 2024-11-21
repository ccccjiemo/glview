import { egl, NativeHelper } from '@jemoc/egl'
import { displaySync } from '@kit.ArkGraphics2D';

export abstract class GLViewController {
  private eglDisplay: egl.EGLDisplay = null;
  private eglConfig: egl.EGLConfig = null;
  private eglContext: egl.EGLContext = null;
  private window: egl.EGLNativeWindowType = null;
  private eglSurface: egl.EGLSurface = null;
  private eglClientVersion: number = 2;
  private renderMode: GLViewRenderMode = GLViewRenderMode.CONTINUOUSLY;
  private vSync?: displaySync.DisplaySync;

  abstract onSurfaceCreated(): void;

  abstract onSurfaceChanged(rect: SurfaceRect): void;

  abstract onSurfaceDestroyed(): void;

  abstract onDrawFrame(timestamp: number, targetTimestamp: number): void;

  setEGLContextClientVersion(version: number) {
    this.eglClientVersion = version;
  }

  eglInit(surfaceId: string): void {
    this.window = NativeHelper.getWindowFromSurfaceId(surfaceId);

    if (this.window == null) {
      throw new Error("get Window failed");
    }

    //获取egl display
    this.eglDisplay = egl.eglGetDisplay(egl.EGL_DEFAULT_DISPLAY);

    //判断egl显示设备是否正常
    if (this.eglDisplay == egl.EGL_NO_DISPLAY) {
      throw new Error("eglGetDisplay failed");
    }

    //获取egl的主次版本号
    let version: egl.EGLVersion = {};
    if (!egl.eglInitialize(this.eglDisplay, version)) {
      throw new Error("eglInitialize failed");
    }

    let attrib_list = [egl.EGL_RED_SIZE, 8,
      egl.EGL_BLUE_SIZE, 8,
      egl.EGL_GREEN_SIZE, 8,
      egl.EGL_SURFACE_TYPE, egl.EGL_WINDOW_BIT,
      egl.EGL_RENDERABLE_TYPE, egl.EGL_OPENGL_ES3_BIT_KHR | egl.EGL_OPENGL_ES2_BIT,
      egl.EGL_NONE];

    let configs = [];
    if (!egl.eglChooseConfig(this.eglDisplay, attrib_list, 1, configs)) {
      throw new Error("eglChooseConfig failed");
    }
    this.eglConfig = configs[0];

    let eglContextAttribs: egl.EGLint[] = [egl.EGL_CONTEXT_CLIENT_VERSION, this.eglClientVersion, egl.EGL_NONE];
    this.eglContext = egl.eglCreateContext(this.eglDisplay, this.eglConfig, egl.EGL_NO_CONTEXT, eglContextAttribs);

    if (this.eglContext == egl.EGL_NO_CONTEXT) {
      throw new Error("eglCreateContext failed");
    }

    this.eglSurface = egl.eglCreateWindowSurface(this.eglDisplay, this.eglConfig, this.window);

    if (this.eglSurface == egl.EGL_NO_SURFACE) {
      throw new Error("eglCreateWindowSurface failed");
    }
  }

  eglDestroy(): void {
    egl.eglDestroySurface(this.eglDisplay, this.eglSurface);
    egl.eglDestroyContext(this.eglDisplay, this.eglContext);
  }

  makeCurrent(): boolean {
    return Boolean(egl.eglMakeCurrent(this.eglDisplay, this.eglSurface, this.eglSurface, this.eglContext));
  }

  swapBuffer(): void {
    egl.eglSwapBuffers(this.eglDisplay, this.eglSurface);
  }

  getEGLConfig(): egl.EGLConfig {
    return this.eglConfig;
  }

  getEGLSurface(): egl.EGLSurface {
    return this.eglSurface;
  }

  getEGLContext(): egl.EGLContext {
    return this.eglContext;
  }

  setRenderMode(mode: GLViewRenderMode): void {
    if (mode == this.renderMode) {
      return;
    }
    if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
      this.vSync?.stop();
    } else {
      this.vSync?.start();
    }
    this.renderMode = mode;

  }

  requestRender(): void {
    if (this.renderMode == GLViewRenderMode.WHEN_DIRTY) {
      this.makeCurrent();
      this.onDrawFrame(0, 0);
      this.swapBuffer();
    }
  }

  raiseSurfaceCreated(surfaceId: string): void {
    this.init(surfaceId).then(() => {
      if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
        this.vSync?.start();
      }
    })
  }

  async init(surfaceId: string): Promise<void> {
    this.eglInit(surfaceId);
    this.makeCurrent();
    this.onSurfaceCreated();
    this.initVSync();
  }

  raiseSurfaceChanged(rect: SurfaceRect): void {
    if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
      this.vSync?.stop();
    }
    this.makeCurrent();
    this.onSurfaceChanged(rect);
    if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
      this.vSync?.start();
    }
  }

  raiseSurfaceDestroy(): void {
    this.destroyVSync();
    this.onSurfaceDestroyed();
    this.eglDestroy();
  }

  initVSync(): void {
    this.vSync = displaySync.create();
    this.vSync.setExpectedFrameRateRange({
      expected: 60,
      max: 144,
      min: 0
    });

    this.vSync.on('frame', this.onFrame);
  }

  destroyVSync(): void {
    this.vSync?.stop();
    this.vSync?.off('frame', this.onFrame);
  }

  onFrame = (data: displaySync.IntervalInfo) => {
    this.makeCurrent();
    this.onDrawFrame(data.timestamp, data.targetTimestamp);
    this.swapBuffer();
  }
}

class ViewController extends XComponentController {
  private controller?: GLViewController;
  private vSync: displaySync.DisplaySync | null = null;

  constructor(controller?: GLViewController) {
    super();
    this.controller = controller;
  }

  setController(controller?: GLViewController) {
    this.controller = controller;
  }

  onSurfaceCreated(surfaceId: string): void {
    if (!this.controller) {
      return;
    }
    this.controller.raiseSurfaceCreated(surfaceId);
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    this.controller?.raiseSurfaceChanged(rect);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    this.controller?.raiseSurfaceDestroy();
  }
}

export enum GLViewRenderMode { WHEN_DIRTY, CONTINUOUSLY }

@Component
export struct GLView {
  controller?: GLViewController;
  private viewController: ViewController = new ViewController();

  aboutToAppear(): void {
    this.viewController.setController(this.controller);
  }

  build() {
    XComponent({
      controller: this.viewController,
      type: XComponentType.SURFACE
    })
  }
}