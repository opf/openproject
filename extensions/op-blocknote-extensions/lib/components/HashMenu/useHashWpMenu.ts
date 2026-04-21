import { useCallback, useMemo, useRef } from "react";
import { useWorkPackageSearch } from "../../hooks/useWorkPackageSearch";
import { createHashWpMenuComponent } from "./HashWpMenu";
import { isHashWpQuery } from "./types";
import type { HashMenuItem } from "./types";
import type { AnyEditor } from "./editorUtils";
import type { WorkPackage } from "../../openProjectTypes";

export function useHashWpMenu(editor: AnyEditor) {
  const { search } = useWorkPackageSearch();
  const searchResultsRef = useRef<WorkPackage[]>([]);

  const getHashItems = useCallback(
    async (query: string): Promise<HashMenuItem[]> => {
      if (!isHashWpQuery(query)) return [];

      const results = await search(query);
      searchResultsRef.current = results;

      const count = Math.max(results.length, 1);
      return Array.from({ length: count }, () => ({
        title: query,
        onItemClick: () => {},
      }));
    },
    [search]
  );

  const HashWpMenu = useMemo(
    () => createHashWpMenuComponent(editor, searchResultsRef),
    [editor]
  );

  return { getHashItems, HashWpMenu };
}