
export function rowId(workPackageId):string {
  return `wp-row-${workPackageId}`;
}

export function locateRow(id):HTMLElement {
  return document.getElementById(rowId(id));
}
