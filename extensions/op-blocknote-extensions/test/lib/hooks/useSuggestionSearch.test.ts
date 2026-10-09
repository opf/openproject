// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { RefObject } from 'react';
import { renderHook } from '@testing-library/react';
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
});
