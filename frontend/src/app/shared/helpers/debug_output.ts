import { environment } from '../../../environments/environment';

/**
 * Execute the callback when DEBUG is defined
 * through webpack.
 */
export function whenDebugging(cb:() => void) {
  if (!environment.production) {
    cb();
  }
}

/**
 * Log with console.log when DEBUG is defined
 * through webpack.
 */
export function debugLog(message:string, ...args:unknown[]):void {
  // eslint-disable-next-line no-console
  whenDebugging(() => console.log(`[DEBUG] ${message}`, ...args));
}

export function timeOutput(msg:string, cb:() => void):any {
  if (!environment.production) {
    const t0 = performance.now();

    const results = cb();

    const t1 = performance.now();
    // eslint-disable-next-line no-console
    console.log(`%c${msg} completed in ${(t1 - t0)} milliseconds.`, 'color:#00A093;');

    return results;
  }
  return cb();
}

export function asyncTimeOutput(msg:string, promise:Promise<any>):any {
  if (!environment.production) {
    const t0 = performance.now();

    return promise.then(() => {
      const t1 = performance.now();
      // eslint-disable-next-line no-console
      console.log(`%c${msg} completed in ${(t1 - t0)} milliseconds.`, 'color:#00A093;');
    });
  }
  return promise;
}
