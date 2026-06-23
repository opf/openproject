import { describe, it, expect, vi } from 'vitest';
import {
  registerInlineWpCallbacks,
  getPendingCallbacks,
  clearInlineWpCallbacks,
  makePendingWpid,
} from '../../../lib/components/InlineWorkPackage/callbacks';

describe('InlineWp callbacks registry', () => {
  it('registers and retrieves callbacks via pending wpid', () => {
    const onSelect = vi.fn();
    const onCancel = vi.fn();

    const key = 'key-1';
    const wpid = makePendingWpid(key);

    registerInlineWpCallbacks(key, onSelect, onCancel);
    const cbs = getPendingCallbacks(wpid);

    expect(cbs?.onSelect).toBe(onSelect);
    expect(cbs?.onCancel).toBe(onCancel);

    clearInlineWpCallbacks(key);
  });

  it('returns undefined for unknown key', () => {
    const wpid = makePendingWpid('nonexistent');
    expect(getPendingCallbacks(wpid)).toBeUndefined();
  });

  it('returns undefined for non-pending wpid', () => {
    expect(getPendingCallbacks('123')).toBeUndefined();
  });

  it('clears callbacks by key', () => {
    const onSelect = vi.fn();
    const onCancel = vi.fn();

    const key = 'key-2';
    const wpid = makePendingWpid(key);

    registerInlineWpCallbacks(key, onSelect, onCancel);
    clearInlineWpCallbacks(key);

    expect(getPendingCallbacks(wpid)).toBeUndefined();
  });

  it('overwrites existing callbacks for the same key', () => {
    const onSelect1 = vi.fn();
    const onSelect2 = vi.fn();
    const onCancel = vi.fn();

    const key = 'key-3';
    const wpid = makePendingWpid(key);

    registerInlineWpCallbacks(key, onSelect1, onCancel);
    registerInlineWpCallbacks(key, onSelect2, onCancel);

    const cbs = getPendingCallbacks(wpid);
    expect(cbs?.onSelect).toBe(onSelect2);

    clearInlineWpCallbacks(key);
  });
});