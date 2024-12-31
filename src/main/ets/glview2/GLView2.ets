import { DefaultExpectedFrameRateRange } from '../common/constants';
import { GLViewRenderMode } from '../common/GLViewRenderMode';
import { DefaultEGLFactory, EGLFactory } from './EGLFactory';
import { GLController } from './GLController';
import { DefaultRender, GLRender } from './GLRender';

type EGLContextVersion = 2 | 3;

@Component
export struct GLView2 {
  render: GLRender = new DefaultRender();
  eglContextClientVersion: EGLContextVersion = 2;
  controller: GLController = new GLController();
  expectedFrameRateRange: ExpectedFrameRateRange = DefaultExpectedFrameRateRange;
  eglFactory: EGLFactory = new DefaultEGLFactory();
  @Prop @Watch('renderModeChanged') renderMode: 0 | 1 = GLViewRenderMode.WHEN_DIRTY;

  renderModeChanged(prop: string) {
    this.controller.setRenderMode(Number(this.renderMode));
  }

  aboutToAppear(): void {
    this.controller.init({
      render: this.render,
      eglContextClientVersion: this.eglContextClientVersion,
      eglFactory: this.eglFactory
    })

    this.controller.setExpectedFrameRateRange(this.expectedFrameRateRange);
    this.controller.setRenderMode(this.renderMode)
  }

  build() {
    XComponent({
      type: XComponentType.SURFACE,
      controller: this.controller
    })
  }
}

@ComponentV2
export struct GLView2V2 {
  render: GLRender = new DefaultRender();
  eglContextClientVersion: EGLContextVersion = 2;
  controller: GLController = new GLController();
  eglFactory: EGLFactory = new DefaultEGLFactory();
  expectedFrameRateRange: ExpectedFrameRateRange = DefaultExpectedFrameRateRange;
  @Param renderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;

  @Monitor('renderMode')
  onRenderModeChanged(monitor: IMonitor) {
    this.controller.setRenderMode(this.renderMode);
  }

  renderModeChanged(prop: string) {
    this.controller.setRenderMode(this.renderMode);
  }

  aboutToAppear(): void {
    this.controller.init({
      render: this.render,
      eglContextClientVersion: this.eglContextClientVersion,
      eglFactory: this.eglFactory
    })
    this.controller.setExpectedFrameRateRange(this.expectedFrameRateRange);
    this.controller.setRenderMode(this.renderMode)
  }

  build() {
    XComponent({
      type: XComponentType.SURFACE,
      controller: this.controller
    })
  }
}

