export type MessageSeverity = 'fatal'|'error'|'warning'|'log'|'info'|'debug';
export type ErrorTags = Record<string, string>;
export type ContextHook = () => ErrorTags|Promise<ErrorTags>;

export abstract class ErrorReporterBase {
  protected contextHooks:ContextHook[] = [];

  public addHook(...hook:ContextHook[]):void {
    this.contextHooks.push(...hook);
  }

  protected hookPromises():Promise<ErrorTags[]> {
    const promises = this
      .contextHooks
      .map((cb) => Promise.resolve(cb()));

    return Promise.all(promises);
  }

  /** Capture a message */
  abstract captureMessage(msg:string, level?:MessageSeverity):void;

  /** Capture an exception(!) only */
  abstract captureException(err:Error):void;
}
