import {
  BlockNoteEditor,
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

  const getCustomSlashMenuItems = (
    editor: BlockNoteEditor<typeof schema.blockSchema>
  ) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      {
        title: "Insert Dummy Block",
        onItemClick: () =>
          // If the block containing the text caret is empty, `insertOrUpdateBlock`
          // changes its type to the provided block. Otherwise, it inserts the new
          // block below and moves the text caret to it. We use this function with
          // a block containing 'Hello World' in bold.
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
