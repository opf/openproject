import { useCallback, useMemo, useRef } from 'react';
import { MAX_SEARCH_RESULTS, useWorkPackageSearch } from '../../hooks/useWorkPackageSearch';
import { createHashWpMenuComponent } from './HashWpMenu';
import { isHashWpQuery } from './types';
import { canOpenHashMenu, hashTargetFor } from './hashTrigger';
import { insertWpForTarget, restoreHashQuery } from './editorUtils';
import type { HashMenuItem, HashSearchState } from './types';
import type { AnyEditor } from '../../editorTypes';
import { cacheColors } from '../../services/colors';
import { closeSuggestionMenu } from '../../utils/suggestionMenu';

export function useHashWpMenu(editor:AnyEditor) {
  const { search } = useWorkPackageSearch();
  const searchStateRef = useRef<HashSearchState>({ query: '', results: [], error: null });
  const latestQueryRef = useRef('');

  const placeholderItems = useCallback(
    (query:string):HashMenuItem[] => [{
      title: query,
      onItemClick: () => {
        restoreHashQuery(editor, query);
      },
    }],
    [editor]
  );

  const getHashItems = useCallback(
    async (query:string):Promise<HashMenuItem[]> => {
      latestQueryRef.current = query;

      const target = hashTargetFor(editor, query);
      if (target.kind === 'none') {
        closeSuggestionMenu(editor);
        return [];
      }

      if (!isHashWpQuery(query)) {
        searchStateRef.current = { query, results: [], error: null };
        return placeholderItems(query);
      }

      await cacheColors();

      try {
        const results = (await search(query)).slice(0, MAX_SEARCH_RESULTS);

        if (latestQueryRef.current !== query) return [];
        searchStateRef.current = { query, results, error: null };

        if (results.length === 0) return placeholderItems(query);

        return results.map((wp) => ({
          title: query,
          onItemClick: () => {
            insertWpForTarget(editor, wp, target);
          },
        }));
      } catch (error) {
        console.error('[work package search] Failed to load work packages from OpenProject:', error);
        if (latestQueryRef.current === query) {
          searchStateRef.current = {
            query,
            results: [],
            error: error instanceof Error ? error.message : 'Unknown error',
          };
        }
        return placeholderItems(query);
      }
    },
    [editor, search, placeholderItems]
  );

  /* eslint-disable react-hooks/refs */
  const HashWpMenu = useMemo(
    () => createHashWpMenuComponent(searchStateRef),
    []
  );
  /* eslint-enable react-hooks/refs */

  return { getHashItems, HashWpMenu, shouldOpenHashMenu: canOpenHashMenu };
}
