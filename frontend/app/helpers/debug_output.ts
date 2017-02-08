/**
 * Execute the callback when DEBUG is defined
 * through webpack.
 */
export function whenDebugging(cb) {
  if (true) {
    cb();
  }
}

/**
 * Log with console.log when DEBUG is defined
 * through webpack.
 */
export function debugLog(...args) {
  whenDebugging(() => console.log('[DEBUG] ', args));
}