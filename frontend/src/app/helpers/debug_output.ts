import { environment } from '../../environments/environment';

/**
 * Execute the callback when DEBUG is defined
 * through webpack.
 */
export function whenDebugging(cb:Function) {
  if (!environment.production) {
    cb();
  }
}

/**
 * Log with console.log when DEBUG is defined
 * through webpack.
 */
export function debugLog(message:string, ...args:any[]) {
  whenDebugging(() => console.log(`[DEBUG] ${message}`, ...args));
}

export function timeOutput(msg:string, cb:() => void):any {
  if (!environment.production) {
    var t0 = performance.now();

    var results = cb();

    var t1 = performance.now();
    console.log(`%c${msg} completed in ${(t1 - t0)} milliseconds.`, 'color:#00A093;');

    return results;
  } else {
    return cb();
  }
}

export function asyncTimeOutput(msg:string, promise:Promise<any>):any {
  if (!environment.production) {
    var t0 = performance.now();

    return promise.then(() => {
      var t1 = performance.now();
      console.log(`%c${msg} completed in ${(t1 - t0)} milliseconds.`, 'color:#00A093;');
    });
  } else {
    return promise;
  }
}
