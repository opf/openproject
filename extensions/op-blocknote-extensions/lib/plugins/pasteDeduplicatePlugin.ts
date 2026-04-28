import { Plugin, PluginKey } from "prosemirror-state";
import { Fragment, Slice } from "prosemirror-model";
import type { Node } from "prosemirror-model";
import { makeInstanceId } from "../services/utils";

/**
 * Regenerates instanceId for every inline WP chip in pasted content.
 *
 * BlockNote duplicates all props verbatim when copying an inline node,
 * including instanceId. Duplicate IDs cause wpBridge resize/delete actions
 * to always affect the first chip instead of the intended one.
 */
export const pasteDeduplicatePluginKey = new PluginKey(
  "pasteDeduplicateInstanceIds"
);

export const pasteDeduplicatePlugin = new Plugin({
  key: pasteDeduplicatePluginKey,

  props: {
    transformPasted(slice) {
      return new Slice(
        transformFragment(slice.content),
        slice.openStart,
        slice.openEnd
      );
    },
  },
});

function transformFragment(fragment: Fragment): Fragment {
  const nodes: Node[] = [];

  fragment.forEach((node) => {
    if (
      node.type.name === "openProjectWorkPackageInline" &&
      node.attrs.instanceId
    ) {
      nodes.push(
        node.type.create(
          { ...node.attrs, instanceId: makeInstanceId() },
          node.content,
          node.marks
        )
      );
    } else if (node.childCount > 0) {
      nodes.push(node.copy(transformFragment(node.content)));
    } else {
      nodes.push(node);
    }
  });

  return Fragment.fromArray(nodes);
}