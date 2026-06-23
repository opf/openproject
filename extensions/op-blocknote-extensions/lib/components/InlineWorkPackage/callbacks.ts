// Global registry that bridges the slash-menu insertion flow with the
// pending-chip React component.

// When a chip is inserted in "pending" state the slash-menu handler registers
// callbacks here. The `InlineSearchPopover` inside the chip reads them by key
// and calls `onSelect` / `onCancel` when the user picks a WP or dismisses.


type WpSelectedCallback = (wpid:number, displayId:string) => void;
type WpCancelCallback = () => void;

export interface PendingCallbacks {
  onSelect:WpSelectedCallback;
  onCancel:WpCancelCallback;
}

const PENDING_PREFIX = 'pending:' as const;
const registry = new Map<string, PendingCallbacks>();

export function makePendingWpid(instanceId:string):string {
  return `${PENDING_PREFIX}${instanceId}`;
}

// Returns callbacks if wpid is a pending placeholder, undefined otherwise.
export function getPendingCallbacks(wpid:string):PendingCallbacks | undefined {
  if (!wpid.startsWith(PENDING_PREFIX)) return undefined;
  return registry.get(wpid.slice(PENDING_PREFIX.length));
}

export function registerInlineWpCallbacks(
  key:string,
  onSelect:WpSelectedCallback,
  onCancel:WpCancelCallback,
):void {
  if (process.env.NODE_ENV !== 'production' && registry.has(key)) {
    console.warn(`[inline-wp] Overwriting existing callbacks for key "${key}". This is likely a bug.`);
  }
  registry.set(key, { onSelect, onCancel });
}

export function clearInlineWpCallbacks(key:string):void {
  registry.delete(key);
}