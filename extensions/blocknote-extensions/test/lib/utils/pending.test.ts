import { describe, it, expect, vi } from 'vitest';
import { createPendingRegistry, isPendingWpid, makePendingWpid } from '../../../lib/utils/pending';

function registered() {
  const registry = createPendingRegistry<string>();
  const wpid = makePendingWpid();
  const entry = { onResolve: vi.fn(), onCancel: vi.fn() };
  registry.register(wpid, entry);
  return { registry, wpid, entry };
}

describe('makePendingWpid', () => {
  it('makes a new pending wpid each time', () => {
    const first = makePendingWpid();

    expect(isPendingWpid(first)).toBe(true);
    expect(makePendingWpid()).not.toBe(first);
  });
});

describe('createPendingRegistry', () => {
  it('hands out what was registered for a pending wpid', () => {
    const { registry, wpid } = registered();

    expect(registry.get(wpid)).toBeDefined();
  });

  it('knows nothing of a wpid that is not pending', () => {
    const registry = createPendingRegistry<string>();
    registry.register('42', { onResolve: vi.fn(), onCancel: vi.fn() });

    expect(registry.get('42')).toBeUndefined();
  });

  it('keeps what an entry carries besides its handlers', () => {
    const registry = createPendingRegistry<string, { onResolve:() => void, onCancel:() => void, mode:string }>();
    const wpid = makePendingWpid();

    registry.register(wpid, { onResolve: vi.fn(), onCancel: vi.fn(), mode: 'create' });

    expect(registry.get(wpid)?.mode).toBe('create');
  });

  it('drops an entry once it is resolved, and passes the result on', () => {
    const { registry, wpid, entry } = registered();

    registry.get(wpid)!.onResolve('result');

    expect(entry.onResolve).toHaveBeenCalledWith('result');
    expect(registry.get(wpid)).toBeUndefined();
  });

  it('drops an entry once it is cancelled', () => {
    const { registry, wpid, entry } = registered();

    registry.get(wpid)!.onCancel();

    expect(entry.onCancel).toHaveBeenCalled();
    expect(registry.get(wpid)).toBeUndefined();
  });

  it('drops an entry on request without calling it', () => {
    const { registry, wpid, entry } = registered();

    registry.unregister(wpid);

    expect(registry.get(wpid)).toBeUndefined();
    expect(entry.onCancel).not.toHaveBeenCalled();
  });
});
