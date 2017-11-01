
/**
 * Return the row html id attribute for the given work package ID.
 */
export function rowId(workPackageId:string):string {
  return `wp-row-${workPackageId}-table`;
}

export function locateTableRow(workPackageId:string):JQuery {
  return jQuery('.' + rowId(workPackageId));
}


