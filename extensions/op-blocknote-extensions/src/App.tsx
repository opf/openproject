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
  openProjectWorkPackageInlineSpec,
  workPackageSlashMenu,
  useHashWpMenu,
  useOpBlockNoteExtensions
} from "../lib";
import "./fetchOverride";

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

initializeOpBlockNoteExtensions({
  baseUrl: "http://localhost:3000",
  locale: "en",
});

type EditorType = typeof schema.BlockNoteEditor;

function buildSlashMenuItems(editor: EditorType) {
  return [
    ...getDefaultReactSlashMenuItems(editor),
    workPackageSlashMenu(editor as any),
  ];
}

export default function App() {
  const editor = useCreateBlockNote({ schema });

  useOpBlockNoteExtensions(editor as any);

  const getSlashItems = useCallback(
    async (query: string) => filterSuggestionItems(buildSlashMenuItems(editor), query),
    [editor]
  );

  const { getHashItems, HashWpMenu } = useHashWpMenu(editor as any);

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
      />
    </BlockNoteView>
  );
}