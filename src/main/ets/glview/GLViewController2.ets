import { GLViewRenderMode } from "../common/GLViewRenderMode";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Config_Attrib_list, DOMAIN, TAG } from "../common/constants";
import { displaySync } from "@kit.ArkGraphics2D";
import { egl } from '@jemoc/egl';

export class GLViewController extends XComponentController {
  private _eglClientVersion: number = 2;
  private _mode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;
  private _vSync: displaySync.DisplaySync;
  private __display__: egl.EGLDisplay | null = null;
  private __config__: egl.EGLConfig | null = null;
  private __surface__: egl.EGLSurface | null = null;
  private __context__: egl.EGLContext | null = null;
  private _expectedFrameRange: ExpectedFrameRateRange = {
    expected: 60, max: 120, min: 0
  }

  constructor() {
    super();
    this._vSync = displaySync.create();
  }

  onSurfaceCreated(surfaceId: string): void {
    this.makeCurrent();
    this.onCreated();
    this._vSync.setExpectedFrameRateRange(this._expectedFrameRange);
    this._vSync.on('frame', (data) => {
      if (this.makeCurrent()) {
        this.onDrawFrame(data.timestamp, data.targetTimestamp);
        this.swapBuffer();
      }
      if (this._mode == GLViewRenderMode.WHEN_DIRTY) {
        this._vSync.stop();
      }
    })

    //异步，让onSurfaceChanged先执行
    setTimeout(() => {
      this._vSync.start();
    })
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    this.makeCurrent();
    this.onChanged(rect);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    this.makeCurrent();
    this.onDestroy();
    this.eglDisplay.destroySurface(this.eglSurface);
    this.eglDisplay.destroyContext(this.eglContext);
    this.eglDisplay.terminate();
    egl.eglReleaseThread();
  }

  setEGLContextClientVersion(version: number) {
    this._eglClientVersion = version;
  }

  setExpectedFrameRateRange(range: ExpectedFrameRateRange) {
    this._expectedFrameRange = range;
  }

  setRenderMode(mode: GLViewRenderMode): void {
    if (mode == this._mode) {
      return;
    }
    hilog.debug(DOMAIN, TAG, `GLViewController set render mode %{public}s`, mode ? 'CONTINUOUSLY' : 'WHEN_DIRTY');
    this._mode = mode;
  }

  protected makeCurrent(): boolean {
    return this.eglDisplay.makeCurrent(this.eglSurface, this.eglSurface, this.eglContext);
  }

  protected swapBuffer(): void {
    this.eglDisplay.swapBuffers(this.eglSurface);
  }

  protected onDrawFrame(timestamp: number, targetTimestamp: number): void {

  }

  protected onCreated() {

  }

  protected onChanged(rect: SurfaceRect) {

  }

  protected onDestroy() {

  }

  protected get eglDisplay(): egl.EGLDisplay {
    if (!this.__display__) {
      let display = egl.eglGetDisplay();
      if (!display) {
        throw Error('egl get display failed')
      }
      this.__display__ = display;
      display.initialize();
    }
    return this.__display__;
  }

  protected get eglSurface(): egl.EGLSurface {
    if (!this.__surface__) {
      let surface = this.eglDisplay.createWindowSurface(this.eglConfig, this.getXComponentSurfaceId());
      if (!surface) {
        throw Error('egl create surface failed')
      }
      this.__surface__ = surface;
    }
    return this.__surface__;
  }

  protected get eglConfig(): egl.EGLConfig {
    if (!this.__config__) {
      let configs = this.eglDisplay.chooseConfig(Config_Attrib_list);
      if (!configs || configs.length == 0) {
        throw Error('egl get config failed');
      }
      this.__config__ = configs[0];
    }
    return this.__config__;
  }

  protected get eglContext(): egl.EGLContext {
    if (!this.__context__) {
      let context = this.eglDisplay.createContext(this.eglConfig, egl.EGL_NO_SURFACE,
        [egl.EGL_CONTEXT_CLIENT_VERSION, this._eglClientVersion, egl.EGL_NONE]);
      if (!context) {
        throw Error('egl get context failed');
      }
      this.__context__ = context;
    }
    return this.__context__;
  }
}



