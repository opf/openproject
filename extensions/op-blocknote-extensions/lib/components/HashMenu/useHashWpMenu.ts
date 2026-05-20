import { useCallback, useMemo, useRef } from "react";
import { useWorkPackageSearch } from "../../hooks/useWorkPackageSearch";
import { createHashWpMenuComponent } from "./HashWpMenu";
import { isHashWpQuery } from "./types";
import { getSizeFromCurrentBlock, insertWpChip } from "./editorUtils";
import type { HashMenuItem } from "./types";
import type { AnyEditor } from "./editorUtils";
import type { WorkPackage } from "../../openProjectTypes";
import { cacheColors } from "../../services/colors";

export function useHashWpMenu(editor: AnyEditor) {
  const { search } = useWorkPackageSearch();
  const searchResultsRef = useRef<WorkPackage[]>([]);

  const getHashItems = useCallback(
    async (query: string): Promise<HashMenuItem[]> => {
      if (!isHashWpQuery(query)) return [];

      await cacheColors();

      const results = await search(query);
      searchResultsRef.current = results;

      const size = getSizeFromCurrentBlock(editor);
      return results.map((wp) => ({
        title: query,
        onItemClick: () => {
          insertWpChip(editor, wp, size);
        },
      }));
    },
    [editor, search]
  );

  const HashWpMenu = useMemo(
    () => createHashWpMenuComponent(searchResultsRef),
    []
  );

  return { getHashItems, HashWpMenu };
}