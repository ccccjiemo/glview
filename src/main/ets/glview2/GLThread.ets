import { GLController } from "./GLController";

export class GLThread extends XComponentController {
  glController?: GLController;

  setGLController(controller: GLController) {
    this.glController = controller;
    controller.init();
  }

  onSurfaceCreated(surfaceId: string): void {
    this.glController?.onSurfaceCreated(surfaceId);
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    this.glController?.onSurfaceChanged(rect);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    this.glController?.onSurfaceDestroy();
  }
}