// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useDebouncedSearch } from '../../../lib/hooks/useDebouncedSearch';

describe('useDebouncedSearch', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('only fetches the last query and settles the superseded one empty', async () => {
    const search = vi.fn(async (query:string) => [query]);
    const { result } = renderHook(() => useDebouncedSearch(search, { debounce: 300 }));

    const first = result.current('a');
    const second = result.current('ab');
    await vi.advanceTimersByTimeAsync(300);

    expect(await first).toEqual([]);
    expect(await second).toEqual(['ab']);
    expect(search).toHaveBeenCalledTimes(1);
  });

  it('skips blank queries unless asked to search them', async () => {
    const search = vi.fn(async () => ['x']);
    const skipping = renderHook(() => useDebouncedSearch(search, { debounce: 0 })).result.current;
    const searching = renderHook(() => useDebouncedSearch(search, { debounce: 0, searchBlank: true })).result.current;

    expect(await skipping(' ')).toEqual([]);
    const blank = searching('');
    await vi.advanceTimersByTimeAsync(0);
    expect(await blank).toEqual(['x']);
    expect(search).toHaveBeenCalledTimes(1);
  });

  it('rejects with the search error', async () => {
    const { result } = renderHook(() => useDebouncedSearch(async () => { throw new Error('boom'); }, { debounce: 0 }));

    const failing = result.current('a');
    await Promise.all([
      expect(failing).rejects.toThrow('boom'),
      vi.advanceTimersByTimeAsync(0),
    ]);
  });

  it('rejects when the search throws synchronously', async () => {
    const { result } = renderHook(() => useDebouncedSearch(() => { throw new Error('sync boom'); }, { debounce: 0 }));

    const failing = result.current('a');
    await Promise.all([
      expect(failing).rejects.toThrow('sync boom'),
      vi.advanceTimersByTimeAsync(0),
    ]);
  });
});
