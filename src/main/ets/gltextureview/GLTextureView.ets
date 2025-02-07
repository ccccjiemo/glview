import { egl } from '@jemoc/egl';
import { gles, globjects } from '@jemoc/gles';
import { Config_Attrib_list } from '../common/constants';
import { NodeController, UIContext } from '@kit.ArkUI';

@Builder
function BuildBlank() {

}

/**
 * 实验阶段
 */
@Component
export struct GLTextureView {
  controller: GLTextureViewController = new GLTextureViewController();


  build() {
    Column() {
      XComponent({ type: XComponentType.SURFACE, controller: this.controller })
    }
  }
}

class BuilderNodeController extends NodeController {
  makeNode(uiContext: UIContext): FrameNode | null {
    throw new Error('Method not implemented.');
  }

}

/**
 * 需要重写
 * onTextureAvailable
 *
 * onTextureSizeChanged
 *
 * onTextureUpdated
 *
 * onTextureDestroyed
 */
export class GLTextureViewController extends XComponentController {
  private _eglClientVersion: number = 2;
  private __display__: egl.EGLDisplay | null = null;
  private __config__: egl.EGLConfig | null = null;
  private __surface__: egl.EGLSurface | null = null;
  private __context__: egl.EGLContext | null = null;
  private __texture__: gles.NativeImage | null = null;
  private __surface_texture__: globjects.Texture | null = null;

  constructor() {
    super();
  }

  private textureAvailable = () => {
    if (this.__surface_texture__ && this.__texture__?.updateSurfaceImage() == 0) {
      this.makeCurrent();
      this.onTextureUpdated(this.__surface_texture__);
    }
  }

  onTextureAvailable(texture: globjects.Texture, width: number, height: number) {

  }

  onTextureSizeChanged(texture: globjects.Texture, width: number, height: number) {

  }

  onTextureUpdated(texture: globjects.Texture) {

  }

  onTextureDestroyed(texture: globjects.Texture) {

  }

  onSurfaceCreated(surfaceId: string): void {
    this.makeCurrent();
    this.__surface_texture__ = new globjects.Texture(gles.GL_TEXTURE_EXTERNAL_OES);
    this.__surface_texture__
      .setParameter(gles.GL_TEXTURE_WRAP_S, gles.GL_REPEAT)
      .setParameter(gles.GL_TEXTURE_WRAP_T, gles.GL_REPEAT)
      .setParameter(gles.GL_TEXTURE_MIN_FILTER, gles.GL_LINEAR)
      .setParameter(gles.GL_TEXTURE_MAG_FILTER, gles.GL_LINEAR);
    this.__texture__ = new gles.NativeImage(this.__surface_texture__.handle);
    this.__texture__.setOnFrameAvailableListener(this.textureAvailable);
    const rect = this.getXComponentSurfaceRect();
    this.onTextureAvailable(this.__surface_texture__, rect.surfaceWidth, rect.surfaceHeight);
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    if (!this.__texture__ || !this.__surface_texture__) {
      return;
    }
    this.onTextureSizeChanged(this.__surface_texture__, rect.surfaceWidth, rect.surfaceHeight);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    if (this.__texture__ && this.__surface_texture__) {
      this.onTextureDestroyed(this.__surface_texture__);
      this.__texture__.destroy();
      this.__surface_texture__.delete();
    }
    this.destroy();
  }


  setEGLContextClientVersion(version: number) {
    this._eglClientVersion = version;
  }

  protected makeCurrent(): boolean {
    return this.eglDisplay.makeCurrent(this.eglSurface, this.eglSurface, this.eglContext);
  }

  protected swapBuffer(): void {
    this.eglDisplay.swapBuffers(this.eglSurface);
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

  protected destroy() {
    this.makeCurrent();
    this.eglDisplay.destroySurface(this.eglSurface);
    this.eglDisplay.destroyContext(this.eglContext);
    this.eglDisplay.terminate();
    egl.eglReleaseThread();
  }
}