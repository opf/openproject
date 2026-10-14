let projectId:string | number | undefined;
let documentId:string | number | undefined;

/**
 * `projectId` is the project the edited document belongs to, where the application knows it.
 * `documentId` is the document mentioned users are notified about.
 */
export function initEditorContext(context:{ projectId?:string | number, documentId?:string | number }):void {
  projectId = context.projectId === '' ? undefined : context.projectId;
  documentId = context.documentId === '' ? undefined : context.documentId;
}

export function contextProjectId():string | number | undefined {
  return projectId;
}

export function contextDocumentId():string | number | undefined {
  return documentId;
}
