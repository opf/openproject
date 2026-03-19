// Global registry that bridges the slash-menu insertion flow with the
// pending-chip React component.

// When a chip is inserted in "pending" state the slash-menu handler registers
// callbacks here. The `InlineSearchPopover` inside the chip reads them by key
// and calls `onSelect` / `onCancel` when the user picks a WP or dismisses.


type WpSelectedCallback = (wpid: number) => void;
type WpCancelCallback = () => void;

interface PendingCallbacks {
  onSelect: WpSelectedCallback;
  onCancel: WpCancelCallback;
}

const registry = new Map<string, PendingCallbacks>();

export function registerInlineWpCallbacks(
  key: string,
  onSelect: WpSelectedCallback,
  onCancel: WpCancelCallback
): void {
  registry.set(key, { onSelect, onCancel });
}

export function getInlineWpCallbacks(key: string): PendingCallbacks | undefined {
  return registry.get(key);
}

export function clearInlineWpCallbacks(key: string): void {
  registry.delete(key);
}