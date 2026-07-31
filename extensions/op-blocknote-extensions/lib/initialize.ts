import { initOpenProjectApi } from './services/openProjectApi.ts';
import { initLanguage } from './services/i18n.ts';

export function initializeOpBlockNoteExtensions(config:{ baseUrl:string, proxyUrl?:string, locale:string }) {
  initOpenProjectApi({ baseUrl: config.baseUrl, proxyUrl: config.proxyUrl });
  initLanguage(config.locale);
}