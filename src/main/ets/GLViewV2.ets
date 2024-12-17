import { GLViewRenderMode } from "./GLViewRenderMode";
import { GLViewController } from "./GLViewController";
import { ViewController } from "./ViewController";


@ComponentV2
export struct GLViewV2 {
  controller?: GLViewController;
  private viewController: ViewController = new ViewController();
  eglContextClientVersion?: number;
  onCreated?: Function;
  @Param renderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;

  aboutToAppear(): void {
    this.viewController.setController(this.controller);
    if (this.eglContextClientVersion != undefined) {
      this.controller?.setEGLContextClientVersion(this.eglContextClientVersion);
    }
    this.controller?.setRenderMode(this.renderMode);
    this.controller?.registerOnCreated(this.onCreated);
  }

  build() {
    XComponent({
      controller: this.viewController,
      type: XComponentType.SURFACE
    })
  }
}