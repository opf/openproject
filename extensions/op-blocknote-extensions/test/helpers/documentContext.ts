import { onTestFinished } from 'vitest';
import { contextDocumentId, contextProjectId, initEditorContext } from '../../lib/services/editorContext';

/** Makes `documentId` the edited document for the rest of the test. */
export function editDocument(documentId:string | number):void {
  const projectId = contextProjectId();
  const previousDocumentId = contextDocumentId();
  initEditorContext({ projectId, documentId });
  onTestFinished(() => initEditorContext({ projectId, documentId: previousDocumentId }));
}
