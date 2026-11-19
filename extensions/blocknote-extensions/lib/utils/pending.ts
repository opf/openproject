const PENDING_PREFIX = 'pending:';

export interface PendingHandlers<Result> {
  onResolve:(result:Result) => void;
  onCancel:() => void;
}

export interface PendingRegistry<Result, Entry extends PendingHandlers<Result>> {
  get:(wpid:string) => Entry | undefined;
  register:(wpid:string, entry:Entry) => void;
  unregister:(wpid:string) => void;
}

export function makePendingWpid():string {
  const token = typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  return `${PENDING_PREFIX}${token}`;
}

export function isPendingWpid(wpid:string):boolean {
  return wpid.startsWith(PENDING_PREFIX);
}

export function createPendingRegistry<
  Result,
  Entry extends PendingHandlers<Result> = PendingHandlers<Result>,
>():PendingRegistry<Result, Entry> {
  const entries = new Map<string, Entry>();

  return {
    get: (wpid) => (isPendingWpid(wpid) ? entries.get(wpid) : undefined),
    register: (wpid, entry) => {
      entries.set(wpid, {
        ...entry,
        onResolve: (result:Result) => {
          entries.delete(wpid);
          entry.onResolve(result);
        },
        onCancel: () => {
          entries.delete(wpid);
          entry.onCancel();
        },
      });
    },
    unregister: (wpid) => { entries.delete(wpid); },
  };
}
