// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { RefObject } from 'react';
import { renderHook } from '@testing-library/react';
import { useDebouncedSearch } from '../../../lib/hooks/useDebouncedSearch';
import { useSuggestionSearch } from '../../../lib/hooks/useSuggestionSearch';
import type { SuggestionPlan, SuggestionSearchState } from '../../../lib/hooks/useSuggestionSearch';
import { createHeadlessEditorWithText } from '../../helpers/headlessEditor';

interface PendingSearch {
  resolve:(results:string[]) => void;
  reject:(error:Error) => void;
}

const searchPlan = ():SuggestionPlan<string> => ({ kind: 'search', pick: () => {} });

function renderSuggestionSearch() {
  const pending = new Map<string, PendingSearch>();
  const search = (query:string) => new Promise<string[]>((resolve, reject) => {
    pending.set(query, { resolve, reject });
  });
  let searchState!:RefObject<SuggestionSearchState<string>>;
  const createMenu = (ref:RefObject<SuggestionSearchState<string>>) => {
    searchState = ref;
    return () => null;
  };

  const { result } = renderHook(() => useSuggestionSearch(createHeadlessEditorWithText('@'), {
    trigger: '@',
    planFor: searchPlan,
    search,
    cancelSearch: () => {},
    logPrefix: '[test search]',
    createMenu,
  }));

  return {
    getItems: result.current.getItems,
    searchFor: (query:string) => pending.get(query)!,
    state: () => searchState.current,
  };
}

describe('useSuggestionSearch', () => {
  beforeEach(() => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('lets only the latest query write the search state', async () => {
    const { getItems, searchFor, state } = renderSuggestionSearch();
    const stale = getItems('a');
    const latest = getItems('an');

    searchFor('an').resolve(['Anna']);
    expect(await latest).toHaveLength(1);
    searchFor('a').resolve(['Adam', 'Anna']);

    expect(await stale).toEqual([]);
    expect(state()).toEqual({ query: 'an', results: ['Anna'], error: null });
  });

  it('does not let a stale error overwrite the latest results', async () => {
    const { getItems, searchFor, state } = renderSuggestionSearch();
    const stale = getItems('a');
    const latest = getItems('an');

    searchFor('an').resolve(['Anna']);
    await latest;
    searchFor('a').reject(new Error('offline'));
    await stale;

    expect(console.error).toHaveBeenCalledWith('[test search]', new Error('offline'));
    expect(state()).toEqual({ query: 'an', results: ['Anna'], error: null });
  });

  it('lets only the latest call write the state when the same query is asked twice', async () => {
    const pending:PendingSearch[] = [];
    const search = () => new Promise<string[]>((resolve, reject) => { pending.push({ resolve, reject }); });
    let searchState!:RefObject<SuggestionSearchState<string>>;
    const { result } = renderHook(() => useSuggestionSearch(createHeadlessEditorWithText('@'), {
      trigger: '@',
      planFor: searchPlan,
      search,
      cancelSearch: () => {},
      logPrefix: '[test search]',
      createMenu: (ref) => { searchState = ref; return () => null; },
    }));

    const first = result.current.getItems('a');
    const second = result.current.getItems('a');
    pending[1].resolve(['Anna']);
    expect(await second).toHaveLength(1);
    pending[0].resolve(['Adam']);

    expect(await first).toEqual([]);
    expect(searchState.current).toEqual({ query: 'a', results: ['Anna'], error: null });
  });

  it('cancels the pending search when the query stops being searchable', async () => {
    vi.useFakeTimers();
    try {
      const search = vi.fn(async (query:string) => [query]);
      const planFor = (query:string):SuggestionPlan<string> => (
        query === '12' ? searchPlan() : { kind: 'prompt' }
      );
      const { result } = renderHook(() => {
        const debounced = useDebouncedSearch(search, { debounce: 300 });
        return useSuggestionSearch(createHeadlessEditorWithText('#'), {
          trigger: '#',
          planFor,
          search: debounced.search,
          cancelSearch: debounced.cancel,
          logPrefix: '[test search]',
          createMenu: () => () => null,
        });
      });

      const searching = result.current.getItems('12');
      await result.current.getItems('');
      await vi.advanceTimersByTimeAsync(300);

      expect(search).not.toHaveBeenCalled();
      expect(await searching).toEqual([]);
    } finally {
      vi.useRealTimers();
    }
  });
});
