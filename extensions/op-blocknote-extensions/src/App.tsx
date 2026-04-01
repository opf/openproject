import { useCallback } from "react";
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
} from "../lib";
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

  const getItems = useCallback(
    async (query: string) =>
      filterSuggestionItems(getCustomSlashMenuItems(editor), query),
    [editor, getCustomSlashMenuItems]
  );

  return (
    <BlockNoteView editor={editor} slashMenu={false}>
      <SuggestionMenuController
        triggerCharacter="/"
        getItems={getItems}
      />
    </BlockNoteView>
  );
}