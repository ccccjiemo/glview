export const INITIALIZED = "Initialized";

export const INIT_FAIL = "Init_Fail"

export const COMMAND_START = "GL_START";

export const COMMAND_INIT = "GL_INIT";

export const COMMAND_STOP = "GL_STOP";

export const COMMAND_FINISH = "GL_FINISH";

export const MESSAGE_GL_FINISH = "GL_FINISH";

export const MESSAGE_EGL_INIT_FAILED = "EGL_INIT_FAILED";

export const MESSAGE_EGL_INIT_SUCCESS = "EGL_INIT_SUCCESS";

export const COMMAND_INIT_WORKER = "INIT_WORKER"

export const COMMAND_SET_RENDER = "SET_RENDER";

export const COMMAND_SET_EGLCONTEXT_CLIENT_VERSION = "SET_EGLCONTEXT_CLIENT_VERSION";

export const COMMAND_SET_RENDER_MODE = "SET_RENDER_MODE";

export const COMMAND_SURFACE_CREATED = "GL_SURFACE_CREATED";

export const COMMAND_SURFACE_CHANGED = "GL_SURFACE_CHANGED";

export const COMMAND_SURFACE_DESTROY = "GL_SURFACE_DESTROY"

export const COMMAND_REQUEST_RENDER = "GL_REQUEST_RENDER"

export const COMMAND_EXECUTE = "GL_EXECUTE"

export interface GLThreadMessage {
  type: string;
  message: string;
}