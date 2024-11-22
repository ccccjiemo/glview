import { egl, NativeHelper } from "@jemoc/egl";
import { displaySync } from "@kit.ArkGraphics2D";
import { GLViewRenderMode } from "./GLViewRenderMode";

export abstract class GLViewController {
  private eglDisplay: egl.EGLDisplay = null;
  private eglConfig: egl.EGLConfig = null;
  private eglContext: egl.EGLContext = null;
  private window: egl.EGLNativeWindowType = null;
  private eglSurface: egl.EGLSurface = null;
  private eglClientVersion: number = 2;
  private renderMode: GLViewRenderMode = GLViewRenderMode.CONTINUOUSLY;
  private vSync?: displaySync.DisplaySync;
  private eglVersion: egl.EGLVersion = {};
  private isInit: boolean = false;

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
      setTimeout(() => {
        this.render();
      }, 0)
    }
  }

  raiseSurfaceCreated(surfaceId: string): void {
    this.init(surfaceId).then(() => {
      if (this.renderMode == GLViewRenderMode.CONTINUOUSLY) {
        this.vSync?.start();
      } else {
        setTimeout(() => {
          this.render()
        }, 0)
      }
    })
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

  private async init(surfaceId: string): Promise<void> {
    if (this.isInit) {
      return;
    }
    this.eglInit(surfaceId);
    this.makeCurrent();
    this.onSurfaceCreated();
    this.initVSync();
    this.isInit = true;
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
    this.makeCurrent();
    this.onDrawFrame(data?.timestamp || 0, data?.targetTimestamp || 0);
    this.swapBuffer();
  }

  private eglDestroy(): void {
    egl.eglDestroyContext(this.eglDisplay, this.eglContext);
    egl.eglDestroySurface(this.eglDisplay, this.eglSurface);
    egl.eglReleaseThread();
    egl.eglTerminate(this.eglDisplay);
  }

  private makeCurrent(): boolean {
    return Boolean(egl.eglMakeCurrent(this.eglDisplay, this.eglSurface, this.eglSurface, this.eglContext));
  }

  private swapBuffer(): void {
    egl.eglSwapBuffers(this.eglDisplay, this.eglSurface);
  }

  private eglInit(surfaceId: string): void {
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
    if (!egl.eglInitialize(this.eglDisplay, this.eglVersion)) {
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
}

