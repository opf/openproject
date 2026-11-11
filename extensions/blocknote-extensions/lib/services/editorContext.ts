let projectId:string | number | undefined;

/** `projectId` is the project the edited document belongs to, where the application knows it. */
export function initEditorContext(context:{ projectId?:string | number }):void {
  projectId = context.projectId === '' ? undefined : context.projectId;
}

export function contextProjectId():string | number | undefined {
  return projectId;
}
