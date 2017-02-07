/**
 * Execute the callback when DEBUG is defined
 * through webpack.
 */
export function when_debugging(cb) {
  if (DEBUG) {
    cb();
  }
}

/**
 * Log with console.log when DEBUG is defined
 * through webpack.
 */
export function debug_log(...args) {
  when_debugging(() => console.log('[DEBUG] ', args));
}