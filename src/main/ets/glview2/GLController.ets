import { ErrorEvent, MessageEvents, worker } from "@kit.ArkTS";
import { GLViewRenderMode } from "../common/GLViewRenderMode";
import {
  GLThreadMessage,
  MESSAGE_EGL_INIT_FAILED,
  MESSAGE_EGL_INIT_SUCCESS,
  MESSAGE_GL_FINISH
} from "../common/GLThreadMessage";
import {
  ExecuteCommand,
  InitCommand,
  RequestRenderCommand,
  SendableCallback,
  SetEGLContextClientVersionCommand,
  SetRenderCommand,
  SurfaceChangedCommand,
  SurfaceCreatedCommand,
  SurfaceDestroyCommand
} from "./GLCommand";
import { GLRender } from "./GLRender";
import { displaySync } from "@kit.ArkGraphics2D";
import { DefaultExpectedFrameRateRange } from "../common/constants";
import { EGLFactory } from "./EGLFactory";

interface InitParam {
  eglContextClientVersion: number,
  render: GLRender,
  eglFactory: EGLFactory
}

export class GLController extends XComponentController {
  private worker: worker.ThreadWorker;
  private mode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;
  private vSync: displaySync.DisplaySync = displaySync.create();
  private isInit: boolean = false;
  private expectedFrameRateRange: ExpectedFrameRateRange = DefaultExpectedFrameRateRange;

  constructor() {
    super();
    this.worker = new worker.ThreadWorker('../workers/GLWorker.ets');

    this.vSync.setExpectedFrameRateRange(this.expectedFrameRateRange)

    this.vSync.on('frame', (t) => {
      this.worker.postMessageWithSharedSendable(new RequestRenderCommand(t));
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

    this.worker.onerror = (error: ErrorEvent) => {
      this.destroy();
    }
  }

  init(param: InitParam) {
    this.worker.postMessageWithSharedSendable(new InitCommand(param.render, param.eglFactory,
      param.eglContextClientVersion));
  }

  destroy() {
    this.vSync.stop();
    this.worker.terminate();
  }

  setExpectedFrameRateRange(range: ExpectedFrameRateRange) {
    this.expectedFrameRateRange = range;
  }

  // setRender(render: GLRender): void {
  //   if (this.isInit) {
  //     return;
  //   }
  //   this.worker.postMessageWithSharedSendable(new SetRenderCommand(render));
  // }

  setRenderMode(mode: GLViewRenderMode): void {
    this.mode = mode;
    //this.worker.postMessageWithSharedSendable(new SetRenderModeCommand(mode));
    if (this.isInit && mode == GLViewRenderMode.CONTINUOUSLY) {
      this.vSync.start();
    }
  }

  // setEGLContextClientVersion(version: number): void {
  //   if (this.isInit) {
  //     return;
  //   }
  //   this.worker.postMessageWithSharedSendable(new SetEGLContextClientVersionCommand(version));
  // }

  onSurfaceCreated(surfaceId: string) {
    this.worker.postMessageWithSharedSendable(new SurfaceCreatedCommand(surfaceId));
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect) {
    this.worker.postMessageWithSharedSendable(new SurfaceChangedCommand(rect));
  }

  onSurfaceDestroy() {
    this.worker.postMessageWithSharedSendable(new SurfaceDestroyCommand());
  }

  requestRender(info?: displaySync.IntervalInfo) {
    if (this.mode != GLViewRenderMode.WHEN_DIRTY) {
      return;
    }
    if (!this.isInit) {
      return;
    }
    this.worker?.postMessageWithSharedSendable(new RequestRenderCommand(info));
  }

  execute<T extends GLRender>(callback: SendableCallback<T>) {
    this.worker.postMessageWithSharedSendable(new ExecuteCommand<T>(callback))
  }
}

