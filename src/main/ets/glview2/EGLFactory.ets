import { egl } from '@jemoc/egl'
import { lang } from '@kit.ArkTS'
import { Config_Attrib_list } from '../common/constants'

export interface EGLFactory extends lang.ISendable {
  getConfig(display: egl.EGLDisplay): egl.EGLConfig

  getContext(display: egl.EGLDisplay, eglContextClientVersion: number): egl.EGLContext

  getSurface(display: egl.EGLDisplay, surfaceId: string): egl.EGLSurface

  destroy(display: egl.EGLDisplay): void
}

@Sendable
export class DefaultEGLFactory implements EGLFactory {
  config: egl.EGLConfig | null = null;
  context: egl.EGLContext | null = null;
  surface: egl.EGLSurface | null = null;

  getConfig(display: egl.EGLDisplay): egl.EGLConfig {
    if (!this.config) {
      let attrib_list = Config_Attrib_list;
      let configs = display.chooseConfig(attrib_list);
      if (!configs || configs.length == 0) {
        throw new Error("eglChooseConfig failed");
      }
      this.config = configs[0]
    }
    return this.config;
  }

  getContext(display: egl.EGLDisplay, eglContextClientVersion: number): egl.EGLContext {
    if (!this.context) {
      let context_attrib = [egl.EGL_CONTEXT_CLIENT_VERSION, eglContextClientVersion, egl.EGL_NONE];
      let context = display.createContext(this.getConfig(display), egl.EGL_NO_CONTEXT, context_attrib);
      if (!context) {
        throw new Error('createContext failed');
      }
      this.context = context;
    }
    return this.context;
  }

  getSurface(display: egl.EGLDisplay, surfaceId: string): egl.EGLSurface {
    if (!this.surface) {
      let surface = display.createWindowSurface(this.getConfig(display), surfaceId);
      if (!surface) {
        throw new Error("eglCreateWindowSurface failed");
      }
      this.surface = surface;
    }
    return this.surface;
  }

  destroy(display: egl.EGLDisplay): void {
    if (this.context) {
      display.destroyContext(this.context);
      this.context = null;
    }
    if (this.surface) {
      display.destroySurface(this.surface);
      this.surface = null;
    }
    this.config = null;
  }
}