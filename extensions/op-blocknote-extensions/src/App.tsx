import { BlockNoteSchema, filterSuggestionItems } from "@blocknote/core";
import "@blocknote/core/fonts/inter.css";
import { BlockNoteView } from "@blocknote/mantine";
import "@blocknote/mantine/style.css";
import {
    getDefaultReactSlashMenuItems,
    SuggestionMenuController,
    useCreateBlockNote,
} from "@blocknote/react";
import {
    initOpenProjectApi,
    openProjectWorkPackageBlockSpec,
    openProjectWorkPackageSlashMenu
} from "../lib";

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    "openProjectWorkPackage": openProjectWorkPackageBlockSpec(),
  },
});
type EditorType = typeof schema.BlockNoteEditor;

export default function App() {
  const editor = useCreateBlockNote({ schema });

  initOpenProjectApi({ baseUrl: "http://localhost:3000" });

  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      openProjectWorkPackageSlashMenu(editor),
    ];
  };

  return (
    <BlockNoteView editor={editor}>
      <SuggestionMenuController
        triggerCharacter="/"
        getItems={async (query: string) =>
          filterSuggestionItems(getCustomSlashMenuItems(editor), query)
        }
      />
    </BlockNoteView>
  );
}
