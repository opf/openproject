import { useCallback, useMemo, useRef } from 'react';
import { useWorkPackageSearch } from '../../hooks/useWorkPackageSearch';
import { createHashWpMenuComponent } from './HashWpMenu';
import { isHashWpQuery } from './types';
import { getSizeFromCurrentBlock, insertWpChip, restoreHashQuery } from './editorUtils';
import type { HashMenuItem, HashSearchState } from './types';
import type { AnyEditor } from './editorUtils';
import { cacheColors } from '../../services/colors';

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

      if (!isHashWpQuery(query)) {
        searchStateRef.current = { query, results: [], error: null };
        return placeholderItems(query);
      }

      await cacheColors();

      try {
        const results = await search(query);

        if (latestQueryRef.current !== query) return [];
        searchStateRef.current = { query, results, error: null };

        if (results.length === 0) return placeholderItems(query);

        const size = getSizeFromCurrentBlock(editor);
        return results.map((wp) => ({
          title: query,
          onItemClick: () => {
            insertWpChip(editor, wp, size);
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

  return { getHashItems, HashWpMenu };
}
