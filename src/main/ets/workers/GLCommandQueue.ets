import { GLCommand } from '../glview2/GLCommand';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GL_Command_Queue_Domain, GL_Command_Queue_Tag } from '../common/constants';

interface Listener {
  listener: Function;
  once: boolean;
}


class EventEmitter {
  protected _events: Record<string, Listener[]> = {};

  private indexOf(eventName: string, listener: Function | Listener): number {
    if (!this._events[eventName]) {
      return -1;
    }

    let listeners = this._events[eventName];
    let target: Function;
    if (typeof listener === 'function') {
      target = listener;
    } else {
      target = listener.listener;
    }
    return listeners.findIndex((_listener) => {
      return _listener.listener === target;
    })

  }

  on(eventName: string, listener: Function | Listener): EventEmitter {
    if (!eventName && !listener) {
      return this;
    }

    let isNew: boolean = false;
    if (!this._events[eventName]) {
      this._events[eventName] = [];
    }

    if (this.indexOf(eventName, listener) === -1) {
      this._events[eventName].push(typeof listener === 'function' ? { listener: listener, once: false } : listener);
    }
    return this;
  }

  emit(eventName: string, ...args: ESObject[]): EventEmitter {
    let listeners = this._events[eventName];
    if (!listeners) {
      return this;
    }

    for (let i = 0; i < listeners.length; i++) {
      let listener = listeners[i];
      if (listener) {
        listener.listener(...args);
        if (listener.once) {
          this.off(eventName, listener)
        }
      }
    }
    return this;
  }

  off(eventName: string, listener: Function | Listener): EventEmitter {
    let listeners = this._events[eventName];
    if (!listener) {
      return this;
    }

    let index = this.indexOf(eventName, listener);
    if (index != -1) {
      listeners.splice(index, 1);
    }
    return this;
  }

  once(eventName: string, listener: Function): EventEmitter {
    return this.on(eventName, { listener: listener, once: true });
  }

  allOff(eventName?: string) {
    if (!eventName) {
      this._events = {};
    } else {
      this._events[eventName] = [];
    }
  }
}

export class GLCommandQueue extends EventEmitter {
  protected commands: Array<GLCommand> = [];
  private _canExecute: boolean = false;
  private _last_command: string = '';

  constructor() {
    super();
    this.on('newListener', (eventName: string) => {
      if (eventName === 'command') {
        this._canExecute = true;
        this.execute();
      }
    })

  }

  on(eventName: string, listener: Function | Listener): GLCommandQueue {
    let isNew = !this._events[eventName] || this._events[eventName].length == 0
    super.on(eventName, listener);
    if (isNew) {
      this.emit('newListener', eventName);
    }
    return this;
  }

  private execute() {
    if (!this._canExecute) {
      return;
    }
    let command: GLCommand | undefined = this.commands.shift();
    if (command) {
      hilog.debug(GL_Command_Queue_Domain, GL_Command_Queue_Tag, "execute command start");
      let start = Date.now();
      this._canExecute = false;
      this.emit('command', command, () => {
        hilog.debug(GL_Command_Queue_Domain, GL_Command_Queue_Tag, "execute command end, take %{public}dms",
          Date.now() - start);
        this._canExecute = true;
        this.execute();
      });
    }
  }

  push(data: GLCommand) {

      this.commands.push(data);
      this.execute();
  }

  onCommand(callback: (command: GLCommand, callback: Callback<void>) => void) {
    this.on('command', callback);
  }

  destroy() {
    this.commands = [];
    this.allOff();
  }
}