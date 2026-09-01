import { initOpenProjectApi } from './services/openProjectApi.ts';
import { initLanguage } from './services/i18n.ts';
import { initEditorContext } from './services/editorContext.ts';

export function initializeOpBlockNoteExtensions(config:{
  baseUrl:string,
  proxyUrl?:string,
  locale:string,
  projectId?:string | number,
}) {
  initOpenProjectApi({ baseUrl: config.baseUrl, proxyUrl: config.proxyUrl });
  initLanguage(config.locale);
  initEditorContext({ projectId: config.projectId });
}
