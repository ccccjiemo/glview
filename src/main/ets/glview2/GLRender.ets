import { lang } from '@kit.ArkTS';

export interface GLRender extends lang.ISendable {
  onSurfaceCreated(): void;

  onSurfaceChanged(width: number, height: number): void;

  onSurfaceDestroyed(): void;

  onDrawFrame(timestamp: number, targetTimestamp: number): boolean;
}

@Sendable
export class DefaultRender implements GLRender {
  onSurfaceCreated(): void {
  }

  onSurfaceChanged(width: number, height: number): void {
  }

  onSurfaceDestroyed(): void {
  }

  onDrawFrame(timestamp: number, targetTimestamp: number): boolean {
    return false;
  }
}