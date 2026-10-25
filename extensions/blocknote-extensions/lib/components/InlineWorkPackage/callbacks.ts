import type { PendingMode } from '../WorkPackage/types';

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
  // Kept here rather than in the node props, so it never reaches the document.
  mode:PendingMode;
}

export const PENDING_PREFIX = 'pending:' as const;
const registry = new Map<string, PendingCallbacks>();

// Generates a unique placeholder wpid. It doubles as the registry key, so
// callbacks are keyed by the pending chip's own wpid prop rather than a
// separate instanceId — the chip node needs no extra identifying attribute.
export function makePendingWpid():string {
  const token =
    typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function'
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  return `${PENDING_PREFIX}${token}`;
}

// Returns callbacks if wpid is a pending placeholder, undefined otherwise.
export function getPendingCallbacks(wpid:string):PendingCallbacks | undefined {
  if (!wpid.startsWith(PENDING_PREFIX)) return undefined;
  return registry.get(wpid);
}

export function registerInlineWpCallbacks(
  key:string,
  onSelect:WpSelectedCallback,
  onCancel:WpCancelCallback,
  mode:PendingMode = 'link',
):void {
  if (!import.meta.env.PROD && registry.has(key)) {
    console.warn(`[inline-wp] Overwriting existing callbacks for key "${key}". This is likely a bug.`);
  }
  registry.set(key, { onSelect, onCancel, mode });
}

export function clearInlineWpCallbacks(key:string):void {
  registry.delete(key);
}
