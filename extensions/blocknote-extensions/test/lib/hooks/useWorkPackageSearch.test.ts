// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, renderHook } from '@testing-library/react';
import type { RenderHookResult } from '@testing-library/react';
import { useWorkPackageSearch } from '../../../lib/hooks/useWorkPackageSearch';
import { searchWorkPackages } from '../../../lib/services/openProjectApi';
import type { WorkPackage } from '../../../lib/openProjectTypes';

vi.mock('../../../lib/services/openProjectApi', () => ({
  searchWorkPackages: vi.fn(),
}));

type SearchHook = RenderHookResult<ReturnType<typeof useWorkPackageSearch>, unknown>;

const workPackage = { id: 12 } as WorkPackage;

function startSearch({ result }:SearchHook, query:string):Promise<WorkPackage[]> {
  let call!:Promise<WorkPackage[]>;
  act(() => {
    call = result.current.search(query);
  });
  return call;
}

const passDebounce = () => act(() => vi.advanceTimersByTimeAsync(300));

describe('useWorkPackageSearch imperative search', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.mocked(searchWorkPackages).mockReset();
    vi.mocked(searchWorkPackages).mockResolvedValue([workPackage]);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('cancels a pending search when called with a blank query', async () => {
    const hook = renderHook(() => useWorkPackageSearch());

    const pending = startSearch(hook, '12');
    const blank = startSearch(hook, '');
    await passDebounce();

    expect(await pending).toEqual([]);
    expect(await blank).toEqual([]);
    expect(searchWorkPackages).not.toHaveBeenCalled();
    expect(hook.result.current.searchResults).toEqual([]);
  });

  it('does not touch state when a call is superseded', async () => {
    const hook = renderHook(() => useWorkPackageSearch());

    const initial = startSearch(hook, '1');
    await passDebounce();
    expect(await initial).toEqual([workPackage]);
    expect(hook.result.current.searchResults).toEqual([workPackage]);

    const superseded = startSearch(hook, '2');
    const latest = startSearch(hook, '3');
    expect(await superseded).toEqual([]);
    expect(hook.result.current.searchResults).toEqual([workPackage]);

    await passDebounce();
    expect(await latest).toEqual([workPackage]);
  });

  it('rethrows a failed search, but only the latest call clears the results', async () => {
    const hook = renderHook(() => useWorkPackageSearch());
    const initial = startSearch(hook, '1');
    await passDebounce();
    expect(await initial).toEqual([workPackage]);

    let failSuperseded:(error:Error) => void = () => {};
    vi.mocked(searchWorkPackages)
      .mockImplementationOnce(() => new Promise((_resolve, reject) => { failSuperseded = reject; }))
      .mockRejectedValueOnce(new Error('latest failed'));

    const superseded = startSearch(hook, '2');
    await passDebounce();
    const latest = startSearch(hook, '3');

    await act(async () => {
      failSuperseded(new Error('superseded failed'));
      await expect(superseded).rejects.toThrow('superseded failed');
    });
    expect(hook.result.current.searchResults).toEqual([workPackage]);

    await Promise.all([
      expect(latest).rejects.toThrow('latest failed'),
      passDebounce(),
    ]);
    expect(hook.result.current.searchResults).toEqual([]);
  });
});
