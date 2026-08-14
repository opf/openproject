import type { AllowedValue } from './formSchema';

export type LastSelection = Record<string, AllowedValue>;

export const LAST_SELECTION_STORAGE_KEY = 'op-bn-create-wp-last-selection';

let cached:LastSelection | undefined;

function withStorage<T>(action:(storage:Storage) => T):T | undefined {
  try {
    return action(window.sessionStorage);
  } catch { return undefined; }
}

function selectedValueOf(candidate:unknown):AllowedValue | undefined {
  if (typeof candidate !== 'object' || candidate === null) return undefined;

  const { href, label } = candidate as Partial<AllowedValue>;
  if (typeof href !== 'string' || !href) return undefined;
  return typeof label === 'string' && label ? { href, label } : undefined;
}

function read():LastSelection {
  const raw = withStorage((storage) => storage.getItem(LAST_SELECTION_STORAGE_KEY));
  if (!raw) return {};

  let stored:unknown;
  try {
    stored = JSON.parse(raw);
  } catch { return {}; }

  if (typeof stored !== 'object' || stored === null) return {};

  const selection:LastSelection = {};
  for (const [key, candidate] of Object.entries(stored)) {
    const value = selectedValueOf(candidate);
    if (value) selection[key] = value;
  }
  return selection;
}

export function lastSelection():LastSelection {
  cached ??= read();
  return cached;
}

/** Replaces the whole selection, so an attribute left empty stays empty next time. */
export function rememberSelection(selection:LastSelection):void {
  cached = selection;
  withStorage((storage) => { storage.setItem(LAST_SELECTION_STORAGE_KEY, JSON.stringify(selection)); });
}

export function forgetLastSelection():void {
  cached = undefined;
  withStorage((storage) => { storage.removeItem(LAST_SELECTION_STORAGE_KEY); });
}
