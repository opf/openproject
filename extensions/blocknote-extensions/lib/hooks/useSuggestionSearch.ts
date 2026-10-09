import { useCallback, useMemo, useRef } from 'react';
import type { FC, RefObject } from 'react';
import type { SuggestionMenuProps } from '@blocknote/react';
import type { AnyEditor } from '../editorTypes';
import { restoreTypedQuery } from '../utils/insertInline';
import { closeSuggestionMenu } from '../utils/suggestionMenu';

export interface SuggestionMenuItem {
  title:string;
  onItemClick:() => void;
}

export interface SuggestionSearchState<T> {
  query:string;
  results:T[];
  error:string | null;
}

export type SuggestionPlan<T> =
  | { kind:'close' }
  | { kind:'prompt' }
  | { kind:'search'; pick:(result:T) => void };

export type SuggestionMenuComponent = FC<SuggestionMenuProps<SuggestionMenuItem>>;

interface SuggestionSearchOptions<T> {
  trigger:string;
  // Callers pass stable functions: a new `getItems` makes BlockNote search again.
  planFor:(query:string) => SuggestionPlan<T>;
  search:(query:string) => Promise<T[]>;
  cancelSearch:() => void;
  logPrefix:string;
  createMenu:(searchStateRef:RefObject<SuggestionSearchState<T>>) => SuggestionMenuComponent;
}

export function useSuggestionSearch<T>(
  editor:AnyEditor,
  { trigger, planFor, search, cancelSearch, logPrefix, createMenu }:SuggestionSearchOptions<T>,
) {
  const searchStateRef = useRef<SuggestionSearchState<T>>({ query: '', results: [], error: null });
  const latestRequestRef = useRef(0);

  const getItems = useCallback(async (query:string):Promise<SuggestionMenuItem[]> => {
    latestRequestRef.current += 1;
    const request = latestRequestRef.current;
    const typedQueryItems = [{ title: query, onItemClick: () => restoreTypedQuery(editor, trigger, query) }];

    const plan = planFor(query);
    if (plan.kind !== 'search') cancelSearch();
    if (plan.kind === 'close') {
      closeSuggestionMenu(editor);
      return [];
    }
    if (plan.kind === 'prompt') {
      searchStateRef.current = { query, results: [], error: null };
      return typedQueryItems;
    }

    try {
      const results = await search(query);
      if (request !== latestRequestRef.current) return [];
      searchStateRef.current = { query, results, error: null };

      if (results.length === 0) return typedQueryItems;
      return results.map((result) => ({ title: query, onItemClick: () => plan.pick(result) }));
    } catch (error) {
      console.error(logPrefix, error);
      if (request === latestRequestRef.current) {
        searchStateRef.current = {
          query,
          results: [],
          error: error instanceof Error ? error.message : 'Unknown error',
        };
      }
      return typedQueryItems;
    }
  }, [editor, trigger, planFor, search, cancelSearch, logPrefix]);

  /* eslint-disable react-hooks/refs */
  const Menu = useMemo(() => createMenu(searchStateRef), [createMenu]);
  /* eslint-enable react-hooks/refs */

  return { getItems, Menu };
}
