import { useCallback, useMemo, useRef } from 'react';
import { MAX_SEARCH_RESULTS, useWorkPackageSearch } from '../../hooks/useWorkPackageSearch';
import { createHashWpMenuComponent } from './HashWpMenu';
import { isHashWpQuery } from './types';
import { canOpenHashMenu, hashTargetFor } from './hashTrigger';
import { createWpForTarget, insertWpForTarget, restoreHashQuery } from './editorUtils';
import type { HashTarget } from './hashTrigger';
import type { HashMenuItem, HashSearchState } from './types';
import type { AnyEditor } from '../../editorTypes';
import { cacheColors } from '../../services/colors';
import { canCreateWorkPackages } from '../../services/openProjectApi';
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

  // Comes last, so it is never what Enter picks before the user moves to it.
  const withCreateItem = useCallback(
    (items:HashMenuItem[], query:string, target:HashTarget):HashMenuItem[] => {
      if (!canCreateWorkPackages()) return items;

      return [...items, {
        title: query,
        createsWorkPackage: true,
        onItemClick: () => {
          createWpForTarget(editor, query, target);
        },
      }];
    },
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

        const resultItems = results.length === 0
          ? placeholderItems(query)
          : results.map((wp) => ({
            title: query,
            onItemClick: () => {
              insertWpForTarget(editor, wp, target);
            },
          }));

        return withCreateItem(resultItems, query, target);
      } catch (error) {
        console.error('[work package search] Failed to load work packages from OpenProject:', error);
        if (latestQueryRef.current === query) {
          searchStateRef.current = {
            query,
            results: [],
            error: error instanceof Error ? error.message : 'Unknown error',
          };
        }
        return withCreateItem(placeholderItems(query), query, target);
      }
    },
    [editor, search, placeholderItems, withCreateItem]
  );

  /* eslint-disable react-hooks/refs */
  const HashWpMenu = useMemo(
    () => createHashWpMenuComponent(searchStateRef),
    []
  );
  /* eslint-enable react-hooks/refs */

  return { getHashItems, HashWpMenu, shouldOpenHashMenu: canOpenHashMenu };
}
