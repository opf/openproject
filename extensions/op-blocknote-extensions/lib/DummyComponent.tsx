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
