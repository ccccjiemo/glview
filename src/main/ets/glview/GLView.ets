import { DefaultExpectedFrameRateRange } from "../common/constants";
import { GLViewRenderMode } from "../common/GLViewRenderMode";
import { GLViewController } from "./GLViewController2";


@Component
export struct GLView {
  controller: GLViewController = new GLViewController();
  eglContextClientVersion: number = 2;
  expectedFrameRange: ExpectedFrameRateRange = DefaultExpectedFrameRateRange;
  @Prop @Watch('onRenderModeChanged') renderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;

  onRenderModeChanged(propName: string) {
    this.controller.setRenderMode(this.renderMode);
  }

  aboutToAppear(): void {
    this.controller.setRenderMode(this.renderMode);
    this.controller.setEGLContextClientVersion(this.eglContextClientVersion);
    this.controller.setExpectedFrameRateRange(this.expectedFrameRange);
  }

  build() {
    XComponent({
      controller: this.controller,
      type: XComponentType.SURFACE
    })
  }
}