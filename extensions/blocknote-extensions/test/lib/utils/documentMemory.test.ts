import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { createDocumentMemory } from '../../../lib/utils/documentMemory';

function visit(pathname:string) {
  vi.stubGlobal('window', { location: { pathname } });
}

describe('createDocumentMemory', () => {
  beforeEach(() => visit('/documents/1'));
  afterEach(() => vi.unstubAllGlobals());

  it('recalls nothing before anything was remembered', () => {
    expect(createDocumentMemory<string>().recall()).toBeUndefined();
  });

  it('recalls what was remembered last in the same document', () => {
    const memory = createDocumentMemory<string>();

    memory.remember('first');
    memory.remember('second');

    expect(memory.recall()).toBe('second');
  });

  it('recalls nothing in another document', () => {
    const memory = createDocumentMemory<string>();
    memory.remember('first');

    visit('/documents/2');

    expect(memory.recall()).toBeUndefined();
  });

  it('recalls nothing once forgotten', () => {
    const memory = createDocumentMemory<string>();
    memory.remember('first');

    memory.forget();

    expect(memory.recall()).toBeUndefined();
  });

  it('keeps each memory apart from the others', () => {
    const first = createDocumentMemory<string>();
    const second = createDocumentMemory<string>();

    first.remember('first');

    expect(second.recall()).toBeUndefined();
  });
});
