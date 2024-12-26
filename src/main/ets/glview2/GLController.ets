import { MessageEvents, worker } from "@kit.ArkTS";
import { GLViewRenderMode } from "../common/GLViewRenderMode";
import {
  GLThreadMessage,
  MESSAGE_EGL_INIT_FAILED,
  MESSAGE_EGL_INIT_SUCCESS,
  MESSAGE_GL_FINISH
} from "../common/GLThreadMessage";
import {
  ExecuteCommand,
  RequestRenderCommand,
  SendableCallback,
  SetEGLContextClientVersionCommand,
  SetRenderCommand,
  SetRenderModeCommand,
  SurfaceChangedCommand,
  SurfaceCreatedCommand,
  SurfaceDestroyCommand
} from "./GLCommand";
import { GLRender } from "./GLRender";
import { displaySync } from "@kit.ArkGraphics2D";

export class GLController {
  private worker?: worker.ThreadWorker;
  private mode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;
  private vSync: displaySync.DisplaySync = displaySync.create();
  private isInit: boolean = false;

  init() {
    this.worker = new worker.ThreadWorker('../workers/GLThread.ets');

    this.vSync.setExpectedFrameRateRange({
      min: 0,
      max: 30,
      expected: 30
    })

    this.vSync.on('frame', (t) => {
      this.worker?.postMessageWithSharedSendable(new RequestRenderCommand(t));
      if (this.mode == GLViewRenderMode.WHEN_DIRTY) {
        this.vSync.stop();
      }
    })

    this.worker.onmessage = (message: MessageEvents) => {
      let data = message.data as GLThreadMessage
      switch (data.type) {
        case MESSAGE_GL_FINISH:
          this.destroy();
          break;
        case MESSAGE_EGL_INIT_FAILED:
          this.destroy();
          throw Error(data.message);
        case MESSAGE_EGL_INIT_SUCCESS:
          this.isInit = true;
          setTimeout(() => {
            this.vSync.start();
          })
          break;
      }
    }
  }

  destroy() {
    this.worker?.terminate();
    this.worker = undefined;
  }

  setRender(render: GLRender): void {
    if (this.isInit) {
      return;
    }
    this.worker?.postMessageWithSharedSendable(new SetRenderCommand(render));
  }

  setRenderMode(mode: GLViewRenderMode): void {
    this.mode = mode;
    this.worker?.postMessageWithSharedSendable(new SetRenderModeCommand(mode));
    if (this.isInit && mode == GLViewRenderMode.CONTINUOUSLY) {
      this.vSync.start();
    }
  }

  setEGLContextClientVersion(version: number): void {
    if (this.isInit) {
      return;
    }
    this.worker?.postMessageWithSharedSendable(new SetEGLContextClientVersionCommand(version));
  }

  onSurfaceCreated(surfaceId: string) {
    this.worker?.postMessageWithSharedSendable(new SurfaceCreatedCommand(surfaceId));
  }

  onSurfaceChanged(rect: SurfaceRect) {
    this.worker?.postMessageWithSharedSendable(new SurfaceChangedCommand(rect));
  }

  onSurfaceDestroy() {
    this.worker?.postMessageWithSharedSendable(new SurfaceDestroyCommand());
  }

  requestRender(info?: displaySync.IntervalInfo) {
    if (this.mode != GLViewRenderMode.WHEN_DIRTY) {
      return;
    }
    this.worker?.postMessageWithSharedSendable(new RequestRenderCommand(info));
  }

  execute<T extends GLRender>(callback: SendableCallback<T>) {
    this.worker?.postMessageWithSharedSendable(new ExecuteCommand<T>(callback))
  }
}

