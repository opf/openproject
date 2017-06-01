/**
 * Execute the callback when DEBUG is defined
 * through webpack.
 */
export function whenDebugging(cb:Function) {
  if (true) {
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
