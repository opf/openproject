import { initOpenProjectApi } from "./services/openProjectApi.ts";
import { initLanguage } from "./services/i18n.ts";

export function initializeOpBlockNoteExtensions(config: { baseUrl: string, locale: string }) {
  initOpenProjectApi({ baseUrl: config.baseUrl });
  initLanguage(config.locale);
}