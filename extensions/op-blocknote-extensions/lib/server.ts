// Server-safe surface of op-blocknote-extensions.
//
// Importing from "op-blocknote-extensions/server" gives consumers (e.g. a
// hocuspocus server using @blocknote/server-util) the pieces they need to
// reconstruct a BlockNote schema and run markdown export without dragging
// @blocknote/react / @blocknote/mantine into the Node import graph.
//
// The block config and the external-HTML helpers are the same ones the
// React variant uses, so client copy-to-clipboard and server save-as-markdown
// produce byte-identical HTML (and therefore byte-identical markdown).

export { blockConfig } from "./components/BlockWorkPackage/blockConfig";
export { openProjectWorkPackageStaticBlockSpec } from "./components/BlockWorkPackage/staticSpec";
export {
  buildWorkPackageBlockExternalDOM,
  computeWorkPackageBlockExternalData,
  parseWorkPackageBlockExternalHTML,
} from "./components/BlockWorkPackage/externalHtml";
export type {
  WorkPackageBlockExternalData,
  WorkPackageBlockProps,
} from "./components/BlockWorkPackage/externalHtml";
