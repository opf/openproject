import { createReactBlockSpec } from "@blocknote/react";

export function DummyComponent() {
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
    render: (_props) => {
      return <DummyComponent />;
    },
  }
);

