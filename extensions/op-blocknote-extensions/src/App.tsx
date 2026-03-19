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
  inlineWorkPackageSlashMenu,
} from "../lib";
import { useEffect } from "react";
import "./fetchOverride";

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackage: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    inlineWorkPackage: inlineWorkPackageSpec,
  },
});

type EditorType = typeof schema.BlockNoteEditor;

export default function App() {
  const editor = useCreateBlockNote({ schema });

  useEffect(() => {
    initializeOpBlockNoteExtensions({
      baseUrl: "http://localhost:3000",
      locale: "en",
    });
  }, []);

  const getCustomSlashMenuItems = (editorInstance: EditorType) => [
    ...getDefaultReactSlashMenuItems(editorInstance),
    inlineWorkPackageSlashMenu(editorInstance as any),
  ];

  return (
    <BlockNoteView editor={editor} slashMenu={false}>
      <SuggestionMenuController
        triggerCharacter="/"
        getItems={async (query: string) =>
          filterSuggestionItems(getCustomSlashMenuItems(editor), query)
        }
      />
    </BlockNoteView>
  );
}