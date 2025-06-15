import { insertOrUpdateBlock } from "@blocknote/core";
import { createReactBlockSpec } from "@blocknote/react";

export function DummyComponent(_props: any) {
  return (
    <div>This is a dummy component being served from a separate library</div>
  );
}

export const dummyBlockSpec = createReactBlockSpec(
  {
    type: "dummy",
    propSchema: {},
    content: "inline",
  },
  {
    render: (_params) => {
      return <DummyComponent />;
    },
  }
);

export const dummySlashMenu = (editor: any) => ({
  title: "Insert Dummy Block",
  onItemClick: () =>
    insertOrUpdateBlock(editor, {
      type: "dummy",
    }),
  aliases: ["dummy"],
  group: "Other",
  icon: <span>🧩</span>,
  subtext: "Used to insert a Dummy block",
})