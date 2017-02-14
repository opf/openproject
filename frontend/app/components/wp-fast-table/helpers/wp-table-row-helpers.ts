/**
 * Return the row html id attribute for the given work package ID.
 */
export function rowId(workPackageId):string {
  return `wp-row-${workPackageId}`;
}

/**
 * Locate the row by its work package ID.
 */
export function locateRow(id):HTMLElement|null {
  return document.getElementById(rowId(id));
}

/**
 * Get the row group class name for the given group id.
 */
export function groupedRowClassName(groupIndex) {
  return `__row-group-${groupIndex}`
}
