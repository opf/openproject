import {commonRowClassName} from '../builders/rows/single-row-builder';
/**
 * Return the row html id attribute for the given work package ID.
 */
export function rowId(workPackageId:string):string {
  return `wp-row-${workPackageId}`;
}

export function rowClass(workPackageId:string):string {
  return `${commonRowClassName}-${workPackageId}`;
}

/**
 * Locate the row by its work package ID.
 */
export function locateRow(id:string):HTMLElement|null {
  return document.getElementById(rowId(id));
}


