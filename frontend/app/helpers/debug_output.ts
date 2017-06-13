/**
 * Execute the callback when DEBUG is defined
 * through webpack.
 */
export function whenDebugging(cb:Function) {
  if (DEBUG) {
    cb();
  }
}

/**
 * Log with console.log when DEBUG is defined
 * through webpack.
 */
export function debugLog(...args:any[]) {
  whenDebugging(() => console.log('[DEBUG] ', args.join('-- ')));
}

export function timeOutput(msg:string, cb:() => void) {
  if (DEBUG) {
    var t0 = performance.now();

    cb();

    var t1 = performance.now();
    console.log(`%c${msg} [completed in ${(t1 - t0)} milliseconds.`, 'color:#00A093;');
  } else {
    cb();
  }
}
