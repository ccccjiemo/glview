import { GLViewController } from "./GLViewController";

export class ViewController extends XComponentController {
  private controller?: GLViewController;

  constructor(controller?: GLViewController) {
    super();
    this.controller = controller;
  }

  setController(controller?: GLViewController) {
    this.controller = controller;
  }

  onSurfaceCreated(surfaceId: string): void {
    if (!this.controller) {
      return;
    }
    this.controller.raiseSurfaceCreated(surfaceId);
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    this.controller?.raiseSurfaceChanged(rect);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    this.controller?.raiseSurfaceDestroy();
  }
}
