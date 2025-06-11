import {
  BlockNoteSchema,
  defaultBlockSpecs,
  filterSuggestionItems,
  insertOrUpdateBlock,
} from "@blocknote/core";
import "@blocknote/core/fonts/inter.css";
import { BlockNoteView } from "@blocknote/mantine";
import "@blocknote/mantine/style.css";
import {
  getDefaultReactSlashMenuItems,
  SuggestionMenuController,
  useCreateBlockNote,
} from "@blocknote/react";

import { dummyBlockSpec } from "../lib";

export default function App() {
  const schema = BlockNoteSchema.create({
    blockSpecs: {
      ...defaultBlockSpecs,
      dummy: dummyBlockSpec,
    },
  });
  const editor = useCreateBlockNote({ schema });
  type EditorType = typeof editor;

  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      {
        title: "Insert Dummy Block",
        onItemClick: () =>
          insertOrUpdateBlock(editor, {
            type: "dummy",
          }),
        aliases: ["dummy"],
        group: "Other",
        icon: <span>🧩</span>,
        subtext: "Used to insert a Dummy block",
      },
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
