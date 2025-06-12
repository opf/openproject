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

import { dummyBlockSpec, openProjectWorkPackageBlockSpec } from "../lib";

export default function App() {
  const schema = BlockNoteSchema.create({
    blockSpecs: {
      ...defaultBlockSpecs,
      openProjectWorkPackage: openProjectWorkPackageBlockSpec,
      dummy: dummyBlockSpec,
    },
  });
  const editor = useCreateBlockNote({ schema });
  type EditorType = typeof editor;

  const getCustomSlashMenuItems = (editor: EditorType) => {
    return [
      ...getDefaultReactSlashMenuItems(editor),
      {
        title: "Open Project Work Package",
        onItemClick: () =>
          insertOrUpdateBlock(editor, {
            type: "openProjectWorkPackage",
          }),
        aliases: ["openproject", "workpackage", "op", "wp"],
        group: "OpenProject",
        icon: <span>📦</span>,
        subtext: "Search and link an existing Work Package",
      },
      {
        title: "Insert Dummy Block",
        onItemClick: () =>
          insertOrUpdateBlock(editor, {
            type: "dummy",
          }),
        aliases: ["dummy"],
        group: "OpenProject",
        icon: <span>🧩</span>,
        subtext: "Insert a Dummy block",
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
