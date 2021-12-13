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
export function debugLog(message:string, ...args:any[]) {
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

// Better extraction of zone.js backtraces
// thanks to https://stackoverflow.com/a/54943260
export function renderLongStackTrace():string {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-unsafe-member-access
  const frames:any[] = (Zone.currentTask?.data as any).__creationTrace__;
  const NEWLINE = '\n';

  // edit this array if you want to ignore or unignore something
  const FILTER_REGEXP:RegExp[] = [
    /checkAndUpdateView/,
    /callViewAction/,
    /execEmbeddedViewsAction/,
    /execComponentViewsAction/,
    /callWithDebugContext/,
    /debugCheckDirectivesFn/,
    /Zone/,
    /checkAndUpdateNode/,
    /debugCheckAndUpdateNode/,
    /onScheduleTask/,
    /onInvoke/,
    /updateDirectives/,
    /@angular/,
    /Observable\._trySubscribe/,
    /Observable.subscribe/,
    /SafeSubscriber/,
    /Subscriber.js.Subscriber/,
    /checkAndUpdateDirectiveInline/,
    /drainMicroTaskQueue/,
    /getStacktraceWithUncaughtError/,
    /LongStackTrace/,
    /Observable._zoneSubscribe/,
  ];

  if (!frames) {
    return 'no frames';
  }

  const filterFrames = (stack:string) => {
    return stack
      .split(NEWLINE)
      .filter((frame) => !FILTER_REGEXP.some((reg) => reg.test(frame)))
      .join(NEWLINE);
  };

  return frames
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    .filter((frame:any) => frame.error.stack)
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    .map((frame:any) => filterFrames(frame.error.stack))
    .join(NEWLINE);
}
