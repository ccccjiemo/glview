import { egl } from "@jemoc/egl";

export const DOMAIN = 0xffff;

export const TAG = "GLView";

export const GL_Command_Queue_Domain = 0xf1;

export const GL_Command_Queue_Tag = "GLCommandQueue";

export const GL_Thread_Domain = 0xf0;

export const GL_Thread_Tag = "GLThread"

export const DefaultExpectedFrameRateRange: ExpectedFrameRateRange = {
  min: 0,
  max: 120,
  expected: 60
}

export const Config_Attrib_list = [egl.EGL_RED_SIZE, 8,
  egl.EGL_BLUE_SIZE, 8,
  egl.EGL_GREEN_SIZE, 8,
  egl.EGL_ALPHA_SIZE, 8,
  egl.EGL_SURFACE_TYPE, egl.EGL_WINDOW_BIT,
  egl.EGL_RENDERABLE_TYPE, egl.EGL_OPENGL_ES3_BIT_KHR | egl.EGL_OPENGL_ES2_BIT,
  egl.EGL_NONE];