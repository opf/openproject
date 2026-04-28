import "./services/i18n.ts";
export {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  workPackageSlashMenu,
  ShadowDomWrapper,
} from "./components";
export { initializeOpBlockNoteExtensions } from "./initialize";
export { wpBridge } from "./services/wpBridge.ts";
export type { WpResizePayload, WpDeletePayload, WpToInlinePayload } from "./services/wpBridge.ts";
export { makeInstanceId } from "./utils/id.ts";
export type { InlineWpSize, BlockWpSize, WpSize } from "./components/WorkPackage/types";
export { createHashWpMenuComponent, isHashWpQuery, useHashWpMenu } from "./components/HashMenu";
export type { HashMenuItem } from "./components/HashMenu";
export { useWorkPackageSearch } from "./hooks/useWorkPackageSearch";
export type { WorkPackage } from "./openProjectTypes";
export { useInlineWpEvents } from './hooks/useInlineWpEvents';
export { useDeduplicateInstanceIds } from "./hooks/useDeduplicateInstanceIds";