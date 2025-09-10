import {
  BlockNoteSchema,
  defaultBlockSpecs,
  filterSuggestionItems,
} from "@blocknote/core";
import "@blocknote/core/fonts/inter.css";
import { BlockNoteView } from "@blocknote/mantine";
import "@blocknote/mantine/style.css";
import {
  getDefaultReactSlashMenuItems,
  SuggestionMenuController,
  useCreateBlockNote,
} from "@blocknote/react";

import { initOpenProjectApi, getDefaultOpenProjectSlashMenuItems, defaultOpenProjectBlockSpecs } from "../lib";

const schema = BlockNoteSchema.create({
  blockSpecs: {
    ...defaultBlockSpecs,
    ...defaultOpenProjectBlockSpecs,
  },
});

export default function App() {
  const editor = useCreateBlockNote({ schema });
  type EditorType = typeof editor;

  initOpenProjectApi({ baseUrl: "http://localhost:3000" });

  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      ...getDefaultOpenProjectSlashMenuItems(editor),
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
