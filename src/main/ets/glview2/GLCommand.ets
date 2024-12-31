import { lang } from "@kit.ArkTS";
import { GLViewRenderMode } from "../common/GLViewRenderMode";

import { GLRender } from "./GLRender";
import { displaySync } from "@kit.ArkGraphics2D";
import {
  COMMAND_EXECUTE,
  COMMAND_INIT_WORKER,
  COMMAND_REQUEST_RENDER,
  COMMAND_SET_EGLCONTEXT_CLIENT_VERSION,
  COMMAND_SET_RENDER,
  COMMAND_SET_RENDER_MODE,
  COMMAND_SURFACE_CHANGED,
  COMMAND_SURFACE_CREATED,
  COMMAND_SURFACE_DESTROY
} from "../common/GLThreadMessage";
import { EGLFactory } from "./EGLFactory";

export type CommandType = "Init" | "Start" | "Stop" | "Finish"


@Sendable
export type SendableCallback<T extends lang.ISendable> = (context: T) => void;

@Sendable
export class InitParam implements lang.ISendable {
  eglContextClientVersion: number;
  render: GLRender;
  eglFactory: EGLFactory;

  constructor(render: GLRender, eglFactory: EGLFactory, eglContextClientVersion: number) {
    this.eglContextClientVersion = eglContextClientVersion;
    this.render = render;
    this.eglFactory = eglFactory;
  }
}

@Sendable
export class Rect {
  width: number;
  height: number;

  constructor(rect: SurfaceRect) {
    this.width = rect.surfaceWidth;
    this.height = rect.surfaceHeight;
  }
}

@Sendable
export class TimeStamp {
  timestamp: number;
  targetTimeStamp: number;

  constructor(info?: displaySync.IntervalInfo) {
    this.timestamp = info?.timestamp ?? 0;
    this.targetTimeStamp = info?.targetTimestamp ?? 0;
  }
}

export interface GLCommand<T extends lang.ISendable = ESObject> extends lang.ISendable {
  type: string;
  data: T
}

@Sendable
export class InitCommand implements GLCommand<InitParam> {
  type: string = COMMAND_INIT_WORKER;
  data: InitParam;

  constructor(render: GLRender, eglFactory: EGLFactory, eglContextClientVersion: number) {
    this.data = new InitParam(render, eglFactory, eglContextClientVersion);
  }
}

@Sendable
export class StartCommand implements GLCommand<string> {
  type: string;
  data: string;

  constructor() {
    this.type = "Start";
    this.data = '';
  }
}

@Sendable
export class SetRenderCommand implements GLCommand<GLRender> {
  type: string;
  data: GLRender;

  constructor(render: GLRender) {
    this.data = render;
    this.type = COMMAND_SET_RENDER;
  }
}

@Sendable
export class SetRenderModeCommand implements GLCommand<number> {
  type: string;
  data: number;

  constructor(mode: GLViewRenderMode) {
    this.type = COMMAND_SET_RENDER_MODE;
    this.data = mode;
  }
}

@Sendable
export class SetEGLContextClientVersionCommand implements GLCommand<number> {
  type: string;
  data: number;

  constructor(version: number) {
    this.type = COMMAND_SET_EGLCONTEXT_CLIENT_VERSION;
    this.data = version;
  }
}

@Sendable
export class SurfaceCreatedCommand implements GLCommand<string> {
  type: string;
  data: string;

  constructor(surfaceId: string) {
    this.data = surfaceId;
    this.type = COMMAND_SURFACE_CREATED;
  }
}

@Sendable
export class SurfaceChangedCommand implements GLCommand<Rect> {
  type: string;
  data: Rect;

  constructor(rect: SurfaceRect) {
    this.type = COMMAND_SURFACE_CHANGED;
    this.data = new Rect(rect);
  }
}

@Sendable
export class SurfaceDestroyCommand implements GLCommand<string> {
  type: string = COMMAND_SURFACE_DESTROY;
  data: string = '';
}

@Sendable
export class RequestRenderCommand implements GLCommand<TimeStamp> {
  type: string = COMMAND_REQUEST_RENDER;
  data: TimeStamp;

  constructor(info?: displaySync.IntervalInfo) {
    this.data = new TimeStamp(info);
  }
}

@Sendable
export class ExecuteCommand<T extends GLRender> implements GLCommand<SendableCallback<T>> {
  type: string = COMMAND_EXECUTE;
  data: SendableCallback<T>;

  constructor(callback: SendableCallback<T>) {
    this.data = callback;
  }
}