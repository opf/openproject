import { describe, it, expect, vi } from 'vitest';
import { wpBridge } from '../../../lib/services/wpBridge';

describe('WpBridge', () => {
  it('unsubscribes correctly — listener not called after off()', () => {
    const cb = vi.fn();
    const off = wpBridge.onResize(cb);

    off();
    wpBridge.resize({ instanceId: 'abc', wpid: 1, size: 's' });

    expect(cb).not.toHaveBeenCalled();
  });

  it('supports multiple listeners for the same event', () => {
    const cb1 = vi.fn();
    const cb2 = vi.fn();
    const off1 = wpBridge.onResize(cb1);
    const off2 = wpBridge.onResize(cb2);

    wpBridge.resize({ instanceId: 'abc', wpid: 1, size: 's' });

    expect(cb1).toHaveBeenCalledOnce();
    expect(cb2).toHaveBeenCalledOnce();

    off1();
    off2();
  });

  it('does not call other event listeners when one event fires', () => {
    const resizeCb = vi.fn();
    const deleteCb = vi.fn();
    const off1 = wpBridge.onResize(resizeCb);
    const off2 = wpBridge.onDelete(deleteCb);

    wpBridge.resize({ instanceId: 'abc', wpid: 1, size: 's' });

    expect(resizeCb).toHaveBeenCalledOnce();
    expect(deleteCb).not.toHaveBeenCalled();

    off1();
    off2();
  });

  it('does not throw if a listener throws — other listeners still called', () => {
    const badCb = vi.fn().mockImplementation(() => { throw new Error('oops'); });
    const goodCb = vi.fn();
    const off1 = wpBridge.onResize(badCb);
    const off2 = wpBridge.onResize(goodCb);

    expect(() => wpBridge.resize({ instanceId: 'abc', wpid: 1, size: 's' })).not.toThrow();
    expect(goodCb).toHaveBeenCalledOnce();

    off1();
    off2();
  });
});