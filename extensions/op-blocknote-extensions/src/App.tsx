import { useCallback, useEffect, useMemo, useRef } from "react";
import { BlockNoteSchema } from "@blocknote/core";
import { filterSuggestionItems } from "@blocknote/core/extensions";
import "@blocknote/core/fonts/inter.css";
import { BlockNoteView } from "@blocknote/mantine";
import "@blocknote/mantine/style.css";
import {
  getDefaultReactSlashMenuItems,
  SuggestionMenuController,
  useCreateBlockNote,
} from "@blocknote/react";
import {
  initializeOpBlockNoteExtensions,
  openProjectWorkPackageBlockSpec,
  inlineWorkPackageSpec,
  workPackageSlashMenu,
  createHashWpMenuComponent,
  isHashWpQuery,
} from "../lib";
import type { HashMenuItem } from "../lib";
import { useWorkPackageSearch } from "../lib/hooks/useWorkPackageSearch";
import type { WorkPackage } from "../lib/openProjectTypes";
import "./fetchOverride";

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackage: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    inlineWorkPackage: inlineWorkPackageSpec,
  },
});

initializeOpBlockNoteExtensions({
  baseUrl: "http://localhost:3000",
  locale: "en",
});

type EditorType = typeof schema.BlockNoteEditor;

export default function App() {
  const editor = useCreateBlockNote({ schema });

  const getCustomSlashMenuItems = useCallback(
    (editorInstance: EditorType) => [
      ...getDefaultReactSlashMenuItems(editorInstance),
      workPackageSlashMenu(editorInstance as any),
    ],
    []
  );

  const getSlashItems = useCallback(
    async (query: string) =>
      filterSuggestionItems(getCustomSlashMenuItems(editor), query),
    [editor, getCustomSlashMenuItems]
  );

  const { searchResults, setSearchQuery } = useWorkPackageSearch();
  const searchResultsRef = useRef<WorkPackage[]>([]);

  useEffect(() => {
    searchResultsRef.current = searchResults;
  }, [searchResults]);

  const getHashItems = useCallback(
    async (query: string): Promise<HashMenuItem[]> => {
      if (!isHashWpQuery(query)) return [];
      setSearchQuery(query);

      const results = searchResultsRef.current;
      const count = Math.max(results.length, 1);
      return Array.from({ length: count }, () => ({
        title: query,
        onItemClick: () => {},
      }));
    },
    [setSearchQuery]
  );

  const HashWpMenu = useMemo(
    () => createHashWpMenuComponent(editor as any, searchResultsRef),
    [editor]
  );

  return (
    <BlockNoteView editor={editor} slashMenu={false}>
      <SuggestionMenuController
        triggerCharacter="/"
        getItems={getSlashItems}
      />

      <SuggestionMenuController
        triggerCharacter="#"
        getItems={getHashItems}
        suggestionMenuComponent={HashWpMenu}
        onItemClick={(item) => item.onItemClick()}
      />
    </BlockNoteView>
  );
}