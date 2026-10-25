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

    const wpid = makePendingWpid();

    registerInlineWpCallbacks(wpid, onSelect, onCancel);
    const cbs = getPendingCallbacks(wpid);

    expect(cbs?.onSelect).toBe(onSelect);
    expect(cbs?.onCancel).toBe(onCancel);

    clearInlineWpCallbacks(wpid);
  });

  it('generates a unique pending wpid each time', () => {
    const wpid1 = makePendingWpid();
    const wpid2 = makePendingWpid();

    expect(wpid1).not.toBe(wpid2);
    expect(wpid1.startsWith('pending:')).toBe(true);
  });

  it('returns undefined for an unregistered pending wpid', () => {
    const wpid = makePendingWpid();
    expect(getPendingCallbacks(wpid)).toBeUndefined();
  });

  it('returns undefined for non-pending wpid', () => {
    expect(getPendingCallbacks('123')).toBeUndefined();
  });

  it('clears callbacks by pending wpid', () => {
    const onSelect = vi.fn();
    const onCancel = vi.fn();

    const wpid = makePendingWpid();

    registerInlineWpCallbacks(wpid, onSelect, onCancel);
    clearInlineWpCallbacks(wpid);

    expect(getPendingCallbacks(wpid)).toBeUndefined();
  });

  it('overwrites existing callbacks for the same pending wpid', () => {
    const onSelect1 = vi.fn();
    const onSelect2 = vi.fn();
    const onCancel = vi.fn();

    const wpid = makePendingWpid();

    registerInlineWpCallbacks(wpid, onSelect1, onCancel);
    registerInlineWpCallbacks(wpid, onSelect2, onCancel);

    const cbs = getPendingCallbacks(wpid);
    expect(cbs?.onSelect).toBe(onSelect2);

    clearInlineWpCallbacks(wpid);
  });
});
