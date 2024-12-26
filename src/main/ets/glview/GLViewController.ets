import { displaySync } from "@kit.ArkGraphics2D";
import { GLViewRenderMode } from "../common/GLViewRenderMode";
import { DOMAIN, TAG } from '../common/constants'
import { hilog } from "@kit.PerformanceAnalysisKit";
import { egl } from "@jemoc/egl";

export abstract class GLViewController {
  eglDisplay?: egl.EGLDisplay;
  eglConfig?: egl.EGLConfig;
  eglContext?: egl.EGLContext;
  eglSurface?: egl.EGLSurface;
  private eglClientVersion: number = 2;
  private renderMode: GLViewRenderMode = GLViewRenderMode.CONTINUOUSLY;
  private vSync?: displaySync.DisplaySync;
  private isInit: boolean = false;
  private onCreated?: Function;

  abstract onSurfaceCreated(): void;

  abstract onSurfaceChanged(rect: SurfaceRect): void;

  abstract onSurfaceDestroyed(): void;

  abstract onDrawFrame(timestamp: number, targetTimestamp: number): void;

  setEGLContextClientVersion(version: number) {
    this.eglClientVersion = version;
  }


  /* getEGLConfig(): egl.EGLConfig {
     return this.eglConfig;
   }

   getEGLSurface(): egl.EGLSurface {
     return this.eglSurface;
   }

   getEGLContext(): egl.EGLContext {
     return this.eglContext;
   }*/

  registerOnCreated(onCreated?: Function) {
    this.onCreated = onCreated;
  }

  setRenderMode(mode: GLViewRenderMode): void {
    if (mode == this.renderMode) {
      return;
    }
    hilog.debug(DOMAIN, TAG, `GLViewController set render mode %{public}s`, mode ? 'CONTINUOUSLY' : 'WHEN_DIRTY');
    if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
      this.vSync?.stop();
    } else {
      this.vSync?.start();
    }
    this.renderMode = mode;
  }

  requestRender(): void {
    if (this.renderMode == GLViewRenderMode.WHEN_DIRTY) {
      setTimeout(() => {
        this.render();
      }, 0)
    }
  }

  raiseSurfaceCreated(surfaceId: string): void {
    //初始化egl
    this.init(surfaceId);

    if (!this.isInit) {
      throw Error('init egl fail')
    }

    //加入异步队列，等待surfaceChanged完成再执行
    setTimeout(() => {
      if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
        this.vSync?.start();
      } else {
        this.render()
      }
    }, 0);

    if (this.onCreated) {
      this.onCreated();
    }


    // this.init(surfaceId).then(() => {
    //
    // })
  }

  raiseSurfaceChanged(rect: SurfaceRect): void {
    if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
      this.vSync?.stop();
    }
    if (this.makeCurrent()) {
      this.onSurfaceChanged(rect);
      if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
        this.vSync?.start();
      }
    }
  }

  raiseSurfaceDestroy(): void {
    this.destroyVSync();
    this.onSurfaceDestroyed();
    this.eglDestroy();
  }

  private init(surfaceId: string) {
    if (this.isInit) {
      return;
    }
    this.eglInit(surfaceId);
    if (this.makeCurrent()) {
      this.onSurfaceCreated();
      this.initVSync();
      this.isInit = true;
    }

  }

  private initVSync(): void {
    this.vSync = displaySync.create();
    this.vSync.setExpectedFrameRateRange({
      expected: 60,
      max: 120,
      min: 0
    });

    this.vSync.on('frame', this.render);
  }

  private destroyVSync(): void {
    this.vSync?.stop();
    this.vSync?.off('frame', this.render);
  }


  private render = (data?: displaySync.IntervalInfo): void => {
    hilog.debug(DOMAIN, TAG, 'GLViewController render frame');
    if (this.makeCurrent()) {
      this.onDrawFrame(data?.timestamp || 0, data?.targetTimestamp || 0);
      this.swapBuffer();
    }


  }

  private eglDestroy(): void {
    this.eglDisplay?.destroyContext(this.eglContext!);
    this.eglDisplay?.destroySurface(this.eglSurface!);
    egl.eglReleaseThread();
    this.eglDisplay?.terminate();
  }

  makeCurrent(): boolean {
    let result = Boolean(this.eglDisplay?.makeCurrent(this.eglSurface, this.eglSurface, this.eglContext));
    hilog.debug(DOMAIN, TAG, 'makeCurrent %{public}s', result);
    return result;
  }

  swapBuffer(): void {
    hilog.debug(DOMAIN, TAG, 'swapBuffer');
    this.eglDisplay?.swapBuffers(this.eglSurface!);
  }

  private eglInit(surfaceId: string): void {
    hilog.debug(DOMAIN, TAG, 'init egl start');

    //获取egl display
    this.eglDisplay = egl.EGLDisplay.getDisplay();

    //判断egl显示设备是否正常
    if (!this.eglDisplay) {
      hilog.debug(DOMAIN, TAG, 'eglGetDisplay failed');
      throw new Error("eglGetDisplay failed");
    }

    //获取egl的主次版本号
    if (!this.eglDisplay.initialize()) {
      hilog.debug(DOMAIN, TAG, 'eglInitialize failed');
      throw new Error("eglInitialize failed");
    }

    let attrib_list = [egl.EGL_RED_SIZE, 8,
      egl.EGL_BLUE_SIZE, 8,
      egl.EGL_GREEN_SIZE, 8,
      egl.EGL_SURFACE_TYPE, egl.EGL_WINDOW_BIT,
      egl.EGL_RENDERABLE_TYPE, egl.EGL_OPENGL_ES3_BIT_KHR | egl.EGL_OPENGL_ES2_BIT,
      egl.EGL_NONE];

    if (!(this.eglConfig = this.eglDisplay.chooseConfig(attrib_list)[0])) {
      hilog.debug(DOMAIN, TAG, 'eglChooseConfig failed');
      throw new Error("eglChooseConfig failed");
    }

    if (!(this.eglContext = this.eglDisplay.createContext(this.eglConfig, egl.EGL_NO_CONTEXT,
      [egl.EGL_CONTEXT_CLIENT_VERSION, this.eglClientVersion, egl.EGL_NONE]))) {
      hilog.debug(DOMAIN, TAG, 'eglCreateContext failed');
      throw new Error("eglCreateContext failed");
    }

    if (!(this.eglSurface = this.eglDisplay.createSurfaceWindow(this.eglConfig, surfaceId))) {
      hilog.debug(DOMAIN, TAG, 'eglCreateWindowSurface failed');
      throw new Error("eglCreateWindowSurface failed");
    }

    let error = egl.eglGetError();
    hilog.debug(DOMAIN, TAG, 'init egl end, error = %{public}d', error);

  }
}

