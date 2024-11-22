import { GLViewRenderMode } from "./GLViewRenderMode";
import { GLViewController } from "./GLViewController";
import { ViewController } from "./ViewController";


@Component
export struct GLView {
  controller?: GLViewController;
  private viewController: ViewController = new ViewController();
  eglContextClientVersion?: number;
  @Prop @Watch('onRenderModeChanged') renderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;

  onRenderModeChanged(propName: string) {
    this.controller?.setRenderMode(this.renderMode);
  }

  aboutToAppear(): void {
    this.viewController.setController(this.controller);
    if (this.eglContextClientVersion != undefined) {
      this.controller?.setEGLContextClientVersion(this.eglContextClientVersion);
    }
    this.controller?.setRenderMode(this.renderMode);
  }

  build() {
    XComponent({
      controller: this.viewController,
      type: XComponentType.SURFACE
    })
  }
}