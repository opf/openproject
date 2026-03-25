import "./services/i18n.ts";
export * from "./components";
export { initializeOpBlockNoteExtensions } from "./initialize";
export { wpBridge } from "./services/wpBridge.ts";
export type { WpResizePayload, WpDeletePayload, WpToInlinePayload } from "./services/wpBridge.ts";
export { makeInstanceId } from "./services/utils.ts";