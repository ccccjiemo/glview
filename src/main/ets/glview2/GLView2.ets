import { GLViewRenderMode } from '../common/GLViewRenderMode';
import { GLController } from './GLController';
import { DefaultRender, GLRender } from './GLRender';
import { GLThread } from './GLThread';

type EGLContextVersion = 2 | 3;

@Component
export struct GLView2 {
  private glThread: GLThread = new GLThread();
  render: GLRender = new DefaultRender();
  eglContextClientVersion: EGLContextVersion = 2;
  controller: GLController = new GLController();
  @Prop @Watch('renderModeChanged') renderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;

  renderModeChanged(prop: string) {
    this.controller.setRenderMode(this.renderMode);
  }

  aboutToAppear(): void {
    this.glThread.setGLController(this.controller);
    this.controller.setRender(this.render);
    this.controller.setEGLContextClientVersion(this.eglContextClientVersion);
    this.controller.setRenderMode(this.renderMode)
  }

  build() {
    XComponent({
      type: XComponentType.SURFACE,
      controller: this.glThread
    })
  }
}

@ComponentV2
export struct GLView2V2 {
  private glThread: GLThread = new GLThread();
  render: GLRender = new DefaultRender();
  eglContextClientVersion: EGLContextVersion = 2;
  controller: GLController = new GLController();
  @Param renderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;

  @Monitor('renderMode')
  onRenderModeChanged(monitor: IMonitor) {
    this.controller.setRenderMode(this.renderMode);
  }

  renderModeChanged(prop: string) {
    this.controller.setRenderMode(this.renderMode);
  }

  aboutToAppear(): void {
    this.glThread.setGLController(this.controller);
    this.controller.setRender(this.render);
    this.controller.setEGLContextClientVersion(this.eglContextClientVersion);
    this.controller.setRenderMode(this.renderMode)
  }

  build() {
    XComponent({
      type: XComponentType.SURFACE,
      controller: this.glThread
    })
  }
}

