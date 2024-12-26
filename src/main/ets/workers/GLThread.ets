import { ArkTSUtils, ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { egl } from '@jemoc/egl';
import {
  COMMAND_EXECUTE,
  COMMAND_REQUEST_RENDER,
  COMMAND_SET_EGLCONTEXT_CLIENT_VERSION,
  COMMAND_SET_RENDER,
  COMMAND_SET_RENDER_MODE,
  COMMAND_SURFACE_CHANGED,
  COMMAND_SURFACE_CREATED,
  COMMAND_SURFACE_DESTROY,
  MESSAGE_EGL_INIT_FAILED,
  MESSAGE_EGL_INIT_SUCCESS,
  MESSAGE_GL_FINISH
} from '../common/GLThreadMessage';
import { GLViewRenderMode } from '../common/GLViewRenderMode';
import { GLRender } from '../glview2/GLRender';
import { GLCommand, Rect, SendableCallback } from '../glview2/GLCommand'
import { GLCommandQueue } from './GLCommandQueue';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GL_Thread_Domain, GL_Thread_Tag } from '../common/constants';

let commandQueue: GLCommandQueue = new GLCommandQueue();
const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
let eglDisplay: egl.EGLDisplay | undefined;
let eglConfig: egl.EGLConfig | undefined;
let eglContext: egl.EGLContext | undefined;
let eglSurface: egl.EGLSurface | undefined;
let glRender: GLRender | undefined;
let eglContextClientVersion = 2;
let RenderMode: GLViewRenderMode = GLViewRenderMode.WHEN_DIRTY;


/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessage = (e: MessageEvents) => {
  commandQueue.push(e.data);
  // switch (e.data.type) {
  //   case "Init":
  //     initGL(e.data.data);
  //     break;
  //   case COMMAND_SET_RENDER:
  //     setRender(e.data.data);
  //     break;
  //   case COMMAND_SET_EGLCONTEXT_CLIENT_VERSION:
  //     setEGLContextClientVersion(e.data.data);
  //     break;
  //   case COMMAND_SET_RENDER_MODE:
  //     setRenderMode(e.data.data);
  //     break;
  //   case COMMAND_SURFACE_CREATED:
  //     initGL(e.data.data);
  //     break;
  //   case COMMAND_SURFACE_CHANGED:
  //     surfaceChanged(e.data.data);
  //     break;
  //   case COMMAND_SURFACE_DESTROY:
  //     surfaceDestroy();
  //     break;
  //   case COMMAND_REQUEST_RENDER:
  //     requestRender(e.data.data.timestamp, e.data.data.targetTimeStamp);
  //     break;
  //   case COMMAND_EXECUTE:
  //     execute(e.data.data);
  //     break;
  // }

}

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessageerror = (e: MessageEvents) => {
}

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param e error message
 */
workerPort.onerror = (e: ErrorEvent) => {
}

const makeCurrent = (): boolean => {
  return Boolean(eglDisplay?.makeCurrent(eglSurface, eglSurface, eglContext));
}

const initGL = (surfaceId: string): void => {
  try {
    eglDisplay = egl.EGLDisplay.getDisplay();

    //判断egl显示设备是否正常
    if (!eglDisplay) {
      throw new Error("eglGetDisplay failed");
    }

    //获取egl的主次版本号
    if (!eglDisplay.initialize()) {
      throw new Error("eglInitialize failed");
    }

    let attrib_list = [
      egl.EGL_RED_SIZE, 8,
      egl.EGL_BLUE_SIZE, 8,
      egl.EGL_GREEN_SIZE, 8,
      egl.EGL_SURFACE_TYPE, egl.EGL_WINDOW_BIT,
      egl.EGL_RENDERABLE_TYPE, egl.EGL_OPENGL_ES3_BIT_KHR | egl.EGL_OPENGL_ES2_BIT,
      egl.EGL_NONE];

    eglConfig = eglDisplay.chooseConfig(attrib_list)[0];

    if (!eglConfig) {
      throw new Error("eglChooseConfig failed");
    }

    let context_attrib = [egl.EGL_CONTEXT_CLIENT_VERSION, eglContextClientVersion, egl.EGL_NONE];
    eglContext = eglDisplay.createContext(eglConfig, egl.EGL_NO_CONTEXT, context_attrib);

    if (!eglContext) {
      throw new Error("eglCreateContext failed");
    }

    eglSurface = eglDisplay.createSurfaceWindow(eglConfig, surfaceId);
    if (!eglSurface) {
      throw new Error("eglCreateWindowSurface failed");
    }

    if (makeCurrent()) {
      glRender?.onSurfaceCreated();
    }
  } catch (e) {
    workerPort.postMessage({ type: MESSAGE_EGL_INIT_FAILED, message: e })
    return;
  }

  console.log('worker egl init success')
  workerPort.postMessage({ type: MESSAGE_EGL_INIT_SUCCESS })
}

const setRender = (render: GLRender): void => {
  glRender = render;
}

const setEGLContextClientVersion = (version: number): void => {
  eglContextClientVersion = version;
}

const setRenderMode = (mode: number): void => {
  RenderMode = mode;
}

const surfaceChanged = async (rect: Rect): Promise<void> => {
  if (makeCurrent()) {
    glRender?.onSurfaceChanged(rect.width, rect.height);
  }
}

const surfaceDestroy = (): void => {
  makeCurrent();
  glRender?.onSurfaceDestroyed();
  eglDisplay?.destroyContext(eglContext);
  eglDisplay?.destroySurface(eglSurface);
  egl.eglReleaseThread();
  eglDisplay?.terminate();
  workerPort.postMessage({ type: MESSAGE_GL_FINISH })
}

const requestRender = async (timestamp: number, targetTimestamp: number): Promise<void> => {
  if (makeCurrent()) {
    if (glRender?.onDrawFrame(timestamp, targetTimestamp)) {
      eglDisplay?.swapBuffers(eglSurface);
    }
  }
}

const execute = async (callback: SendableCallback<GLRender>): Promise<void> => {
  if (glRender) {
    if (makeCurrent()) {
      callback(glRender);
    }
  }

}

commandQueue.onCommand((command: GLCommand, callback: Callback<void>) => {
  hilog.debug(GL_Thread_Domain, GL_Thread_Tag, "execute command type: %{public}s", command.type);
  switch (command.type) {
    case COMMAND_SET_RENDER:
      setRender(command.data);
      break;
    case COMMAND_SET_EGLCONTEXT_CLIENT_VERSION:
      setEGLContextClientVersion(command.data);
      break;
    case COMMAND_SET_RENDER_MODE:
      setRenderMode(command.data);
      break;
    case COMMAND_SURFACE_CREATED:
      initGL(command.data);
      break;
    case COMMAND_SURFACE_CHANGED:
      surfaceChanged(command.data);
      break;
    case COMMAND_SURFACE_DESTROY:
      surfaceDestroy();
      break;
    case COMMAND_REQUEST_RENDER:
      requestRender(command.data.timestamp, command.data.targetTimeStamp);
      break;
    case COMMAND_EXECUTE:
      execute(command.data);
      break;
  }
  callback();
})



