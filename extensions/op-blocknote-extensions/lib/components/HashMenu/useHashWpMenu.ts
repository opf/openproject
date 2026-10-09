import { useCallback } from 'react';
import type { AnyEditor } from '../../editorTypes';
import type { WorkPackage } from '../../openProjectTypes';
import { MAX_SEARCH_RESULTS, useWorkPackageSearch } from '../../hooks/useWorkPackageSearch';
import { useSuggestionSearch } from '../../hooks/useSuggestionSearch';
import type { SuggestionPlan } from '../../hooks/useSuggestionSearch';
import { cacheColors } from '../../services/colors';
import { createHashWpMenuComponent } from './HashWpMenu';
import { insertWpForTarget } from './editorUtils';
import { canOpenHashMenu, HASH_TRIGGER, hashTargetFor } from './hashTrigger';
import { isHashWpQuery } from './types';

export function useHashWpMenu(editor:AnyEditor) {
  const { search } = useWorkPackageSearch();

  const planFor = useCallback((query:string):SuggestionPlan<WorkPackage> => {
    const target = hashTargetFor(editor, query);
    if (target.kind === 'none') return { kind: 'close' };
    if (!isHashWpQuery(query)) return { kind: 'prompt' };
    return { kind: 'search', pick: (workPackage) => insertWpForTarget(editor, workPackage, target) };
  }, [editor]);

  const searchWithColors = useCallback(async (query:string) => {
    await cacheColors();
    return (await search(query)).slice(0, MAX_SEARCH_RESULTS);
  }, [search]);

  const { getItems, Menu } = useSuggestionSearch(editor, {
    trigger: HASH_TRIGGER,
    planFor,
    search: searchWithColors,
    logPrefix: '[work package search] Failed to load work packages from OpenProject:',
    createMenu: createHashWpMenuComponent,
  });

  return { getHashItems: getItems, HashWpMenu: Menu, shouldOpenHashMenu: canOpenHashMenu };
}
