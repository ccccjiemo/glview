import { egl } from "@jemoc/egl";
import { displaySync } from "@kit.ArkGraphics2D";
import { lang } from "@kit.ArkTS";

export { gles } from '@jemoc/gles'

export { egl }

export enum GLViewRenderMode { WHEN_DIRTY, CONTINUOUSLY }


@Component
export struct GLView {
  controller?: GLViewController;
  eglContextClientVersion?: number;
  onCreated?: Function;
  renderMode: GLViewRenderMode;

  build(): void
}

@ComponentV2
export struct GLViewV2 {
  controller?: GLViewController;
  eglContextClientVersion?: number;
  renderMode: GLViewRenderMode

  build(): void
}


export abstract class GLViewController {
  eglDisplay?: egl.EGLDisplay;
  eglConfig?: egl.EGLConfig;
  eglContext?: egl.EGLContext;
  eglSurface?: egl.EGLSurface;

  abstract onSurfaceCreated(): void;

  abstract onSurfaceChanged(rect: SurfaceRect): void;

  abstract onSurfaceDestroyed(): void;

  abstract onDrawFrame(timestamp: number, targetTimestamp: number): void;

  setEGLContextClientVersion(version: number): void

  setRenderMode(mode: GLViewRenderMode): void

  requestRender(): void

  makeCurrent(): boolean

  swapBuffer(): void
}

type EGLContextVersion = 2 | 3;

@Component
export struct GLView2 {
  render: GLRender;
  eglContextClientVersion: EGLContextVersion;
  controller: GLController
  renderMode: GLViewRenderMode

  build(): void
}

export interface GLRender extends lang.ISendable {
  onSurfaceCreated(): void;

  onSurfaceChanged(width: number, height: number): void;

  onSurfaceDestroyed(): void;

  onDrawFrame(timestamp: number, targetTimestamp: number): boolean;
}


export class GLController {
  setRender(render: GLRender): void

  setRenderMode(mode: GLViewRenderMode): void

  setEGLContextClientVersion(version: number): void

  requestRender(info?: displaySync.IntervalInfo): void
}