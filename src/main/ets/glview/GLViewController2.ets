import { GLViewRenderMode } from "../common/GLViewRenderMode";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Config_Attrib_list, DOMAIN, TAG } from "../common/constants";
import { displaySync } from "@kit.ArkGraphics2D";
import { egl } from '@jemoc/egl';
import { util } from "@kit.ArkTS";


export class GLViewController extends XComponentController {
  private _eglClientVersion: number = 2;
  private _mode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;
  private _vSync: displaySync.DisplaySync;
  private __display__: egl.EGLDisplay | null = null;
  private __config__: egl.EGLConfig | null = null;
  private __surface__: egl.EGLSurface | null = null;
  private __context__: egl.EGLContext | null = null;
  private _init: boolean = false;
  private _expectedFrameRange: ExpectedFrameRateRange = {
    expected: 60, max: 120, min: 0
  }


  constructor() {
    super();
    this._vSync = displaySync.create();
    util.Aspect.addBefore(this.constructor, "onSurfaceCreated", false, (instance: GLViewController) => {
      if (instance === this) {
        instance.makeCurrent();
      }
    })
    util.Aspect.addAfter(this.constructor, "onSurfaceCreated", false, (instance: GLViewController) => {
      if (instance === this) {
        instance.start();
      }
    })
    util.Aspect.addAfter(this.constructor, "onSurfaceDestroyed", false, (instance: GLViewController) => {
      if (instance === this) {
        instance.stop();
      }
    })
  }

  onSurfaceCreated(surfaceId: string): void {
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
  }

  onSurfaceDestroyed(surfaceId: string): void {
  }

  protected onDrawFrame(timestamp: number, targetTimestamp: number): boolean {
    return false;
  }

  setEGLContextClientVersion(version: number) {
    this._eglClientVersion = version;
  }

  setExpectedFrameRateRange(range: ExpectedFrameRateRange) {
    this._expectedFrameRange = range;
    if (this._init) {
      if (this._mode == GLViewRenderMode.CONTINUOUSLY) {
        this._vSync.stop();
        this._vSync.setExpectedFrameRateRange(range);
        this._vSync.start();
      } else {
        this._vSync.setExpectedFrameRateRange(range);
      }
    }
  }

  setRenderMode(mode: GLViewRenderMode): void {
    if (mode == this._mode) {
      return;
    }
    hilog.debug(DOMAIN, TAG, `GLViewController set render mode %{public}s`, mode ? 'CONTINUOUSLY' : 'WHEN_DIRTY');
    this._mode = mode;
  }

  requestRender() {
    if (this._mode == GLViewRenderMode.WHEN_DIRTY && this._init) {
      this._vSync.start();
    }
  }

  protected makeCurrent(): boolean {
    return this.eglDisplay.makeCurrent(this.eglSurface, this.eglSurface, this.eglContext);
  }

  protected swapBuffer(): void {
    this.eglDisplay.swapBuffers(this.eglSurface);
  }

  protected start() {
    this._vSync.setExpectedFrameRateRange(this._expectedFrameRange);
    this._vSync.on('frame', (data) => {
      if (this.makeCurrent()) {
        if (this.onDrawFrame(data.timestamp, data.targetTimestamp)) {
          this.swapBuffer();
        }
      }
      if (this._mode == GLViewRenderMode.WHEN_DIRTY) {
        this._vSync.stop();
      }
    })

    //异步，让onSurfaceChanged先执行
    setTimeout(() => {
      this._vSync.start();
      this._init = true;
    })
  }

  protected stop() {
    this._vSync.stop();
    this.makeCurrent();
    this.eglDisplay.destroySurface(this.eglSurface);
    this.eglDisplay.destroyContext(this.eglContext);
    this.eglDisplay.terminate();
    egl.eglReleaseThread();
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
      let surface = this.eglDisplay.createSurfaceWindow(this.eglConfig, this.getXComponentSurfaceId());
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



