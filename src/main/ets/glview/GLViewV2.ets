import { DefaultExpectedFrameRateRange } from "../common/constants";
import { GLViewRenderMode } from "../common/GLViewRenderMode";
import { GLViewController } from "./GLViewController2";


@ComponentV2
export struct GLViewV2 {
  controller: GLViewController = new GLViewController();
  eglContextClientVersion: number = 2;
  expectedFrameRange: ExpectedFrameRateRange = DefaultExpectedFrameRateRange;
  @Param renderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;

  @Monitor('renderMode')
  onRenderModeChanged() {
    this.controller.setRenderMode(this.renderMode)
  }

  aboutToAppear(): void {
    this.controller.setRenderMode(this.renderMode)
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