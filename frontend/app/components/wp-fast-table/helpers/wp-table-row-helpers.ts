
/**
 * Return the row html id attribute for the given work package ID.
 */
export function rowId(workPackageId:string):string {
  return `wp-table-row-${workPackageId}`;
}

/**
 * Locate the row by its work package ID.
 */
export function locateRow(id:string):HTMLElement|null {
  return document.getElementById(rowId(id));
}


